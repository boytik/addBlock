//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//

import Foundation
import SafariServices
import ContentBlockerConverter
import CryptoKit
import Combine

// MARK: - Error types

enum RulesServiceError: LocalizedError {
    case filtersNotLoaded
    case conversionFailed(String)
    case reloadFailed
    case cancelled
    case containerUnavailable

    var errorDescription: String? {
        switch self {
        case .filtersNotLoaded:
            return "Failed to load any filter lists"
        case .conversionFailed(let reason):
            return "Filter conversion failed: \(reason)"
        case .reloadFailed:
            return "Safari content blocker reload failed"
        case .cancelled:
            return "Update was cancelled"
        case .containerUnavailable:
            return "App group container is unavailable"
        }
    }
}

// MARK: - Update result

struct RulesUpdateResult {
    let success: Bool
    let rulesCount: Int
    let jsonSize: Int
    let errors: [String]

    static let cancelled = RulesUpdateResult(success: false, rulesCount: 0, jsonSize: 0, errors: ["Cancelled"])
}

// MARK: - RulesService

@MainActor
final class RulesService {

    // MARK: - Published state

    @Published private(set) var isUpdating: Bool = false
    @Published private(set) var lastError: String?
    @Published private(set) var lastRulesCount: Int = 0

    // MARK: - Config

    private let appGroupID = "group.test.com.adblock"
    private let blockerID = "test.com.adblock.blocker"
    private let jsonFileName = "blockerList.json"
    /// Источники фильтров: при старте читаем из бандла (easylist.txt, easyprivacy.txt); url/fallback — только если бандл пуст.
    private let filterSources: [(url: URL, fallbackUrl: URL, cacheKey: String, configFlag: KeyPath<ContentBlockerConfig, Bool>)] = [
        (URL(string: "https://easylist.to/easylist/easylist.txt")!, URL(string: "https://raw.githubusercontent.com/boytik/addBlock/refs/heads/main/easylist.txt")!, "easylist.txt", \.blockAds),
        (URL(string: "https://easylist.to/easylist/easyprivacy.txt")!, URL(string: "https://raw.githubusercontent.com/boytik/addBlock/refs/heads/main/easyprivacy.txt")!, "easyprivacy.txt", \.blockTrackers),
    ]

    private nonisolated static let defaultVideoWhitelistDomains = [
        "youtube.com", "googlevideo.com", "ytimg.com",
        "twitch.tv", "ttvnw.net", "jtvnw.net", "live-video.net",
        "vimeo.com", "vimeocdn.com",
    ]
    private var defaultVideoWhitelist: [String] { Self.defaultVideoWhitelistDomains }

    /// Whitelist-строки для pre-merge (быстрый путь при первом включении)
    private nonisolated static var defaultWhitelistLines: [String] {
        defaultVideoWhitelistDomains.flatMap { domain -> [String] in
            let cleaned = domain
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: "www.", with: "")
            guard !cleaned.isEmpty else { return [] }
            return ["@@||\(cleaned)^$document", "@@||\(cleaned)^"]
        }
    }

    // MARK: - Stores

    private let customRulesStore: CustomRulesStore

    // MARK: - Tuning

    /// Кэш правил: 30 дней. Правила скачиваются при первом запуске (preload) и при необходимости.
    private let cacheLifetime: TimeInterval = 60 * 60 * 24 * 30
    private let staleCacheLifetime: TimeInterval = 60 * 60 * 24 * 90
    /// Одна попытка primary — быстрый переход на fallback при таймауте easylist.to
    private let maxRetries = 1
    private let retryBaseDelay: UInt64 = 1_000_000_000
    private let maxJsonSizeBytes = 6 * 1024 * 1024

    // MARK: - Internal state

    private var currentTask: Task<RulesUpdateResult, Never>?
    private var lastConfigHash: String?
    private let session: URLSession

    /// Prebuilt JSON в памяти — при включении не читаем с диска
    private var prebuiltAdsJson: String?
    private var prebuiltTrackersJson: String?
    private var prebuiltBothJson: String?
    /// Pre-merged: both + default whitelist — для быстрого включения без merge
    private var prebuiltBothWithDefaultWhitelist: String?

    // MARK: - Init

    init(customRulesStore: CustomRulesStore) {
        self.customRulesStore = customRulesStore

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 45
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        self.session = URLSession(configuration: config)

        let defaults = UserDefaults(suiteName: appGroupID)
        if defaults == nil { print("[AppGroup] RulesService init: UserDefaults nil") }
        lastConfigHash = defaults?.string(forKey: "lastConfigHash")
        lastRulesCount = defaults?.integer(forKey: "lastRulesCount") ?? 0

        if containerURL() == nil {
            print("[AppGroup] containerURL is nil")
        }
        loadPrebuiltIntoMemory() // Из кэша при перезапуске — включение мгновенно
        // preloadFilters вызывается из RootView.task при первом появлении экрана
    }

    /// Загружает prebuilt JSON из кэша в память (при перезапуске приложения)
    private func loadPrebuiltIntoMemory() {
        if let json = loadCache(key: "prebuilt_ads", maxAge: nil) { prebuiltAdsJson = json }
        if let json = loadCache(key: "prebuilt_trackers", maxAge: nil) { prebuiltTrackersJson = json }
        if let json = loadCache(key: "prebuilt_both", maxAge: nil) { prebuiltBothJson = json }
        if let json = loadCache(key: "prebuilt_both_whitelist", maxAge: nil) { prebuiltBothWithDefaultWhitelist = json }
    }

    // MARK: - Public API

    /// Скачивает правила при старте приложения (в фоне). Параллельная загрузка + конвертация в JSON в память.
    func preloadFilters() async {
        // Параллельная загрузка обоих фильтров (с fallback на GitHub при таймауте/ошибке)
        async let adsText = loadFilterWithRetry(url: filterSources[0].url, fallbackUrl: filterSources[0].fallbackUrl, cacheKey: filterSources[0].cacheKey)
        async let trackersText = loadFilterWithRetry(url: filterSources[1].url, fallbackUrl: filterSources[1].fallbackUrl, cacheKey: filterSources[1].cacheKey)
        let (ads, trackers) = await (adsText, trackersText)

        // Pre-convert в JSON в фоне + сохранить в память и на диск
        let maxBytes = maxJsonSizeBytes
        await Task.detached(priority: .utility) {
            if !ads.isEmpty {
                let lines = ads.components(separatedBy: .newlines)
                if let json = Self.staticConvertToJson(lines, maxJsonSizeBytes: maxBytes) {
                    await MainActor.run {
                        self.prebuiltAdsJson = json
                        self.saveCache(text: json, key: "prebuilt_ads")
                    }
                }
            }
            if !trackers.isEmpty {
                let lines = trackers.components(separatedBy: .newlines)
                if let json = Self.staticConvertToJson(lines, maxJsonSizeBytes: maxBytes) {
                    await MainActor.run {
                        self.prebuiltTrackersJson = json
                        self.saveCache(text: json, key: "prebuilt_trackers")
                    }
                }
            }
            if !ads.isEmpty && !trackers.isEmpty {
                let combined = ads.components(separatedBy: .newlines) + trackers.components(separatedBy: .newlines)
                if let json = Self.staticConvertToJson(combined, maxJsonSizeBytes: maxBytes) {
                    // Pre-merge с default whitelist в фоне (не блокируем MainActor)
                    let mergedJson = Self.staticMergePrebuiltWithExtra(baseJson: json, extraLines: Self.defaultWhitelistLines, maxJsonSizeBytes: maxBytes)?.json
                    await MainActor.run {
                        self.prebuiltBothJson = json
                        self.saveCache(text: json, key: "prebuilt_both")
                        if let merged = mergedJson {
                            self.prebuiltBothWithDefaultWhitelist = merged
                            self.saveCache(text: merged, key: "prebuilt_both_whitelist")
                        }
                    }
                }
            }
        }.value
    }

    func validateOnLaunch(config: ContentBlockerConfig) {
        let newHash = hashConfig(config)
        guard newHash != lastConfigHash else { return }
        Task { await updateRules(config: config, fromLaunch: true) }
    }

    @discardableResult
    func forceUpdate(config: ContentBlockerConfig) async -> RulesUpdateResult {
        lastConfigHash = nil
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: "lastConfigHash")
        return await updateRules(config: config)
    }

    @discardableResult
    func updateRules(config: ContentBlockerConfig, fromLaunch: Bool = false, userRequestedDisable: Bool = false) async -> RulesUpdateResult {
        let newHash = hashConfig(config)
        if newHash == lastConfigHash {
            return RulesUpdateResult(success: true, rulesCount: lastRulesCount, jsonSize: 0, errors: [])
        }
        currentTask?.cancel()
        let task = Task<RulesUpdateResult, Never> {
            await _performUpdate(config: config, hash: newHash, fromLaunch: fromLaunch, userRequestedDisable: userRequestedDisable)
        }
        currentTask = task
        return await task.value
    }

    func clearCaches() {
        for source in filterSources {
            deleteCacheFile(key: source.cacheKey)
        }
        for key in ["prebuilt_ads", "prebuilt_trackers", "prebuilt_both", "prebuilt_both_whitelist"] {
            deleteCacheFile(key: key)
        }
        prebuiltAdsJson = nil
        prebuiltTrackersJson = nil
        prebuiltBothJson = nil
        prebuiltBothWithDefaultWhitelist = nil
        lastConfigHash = nil
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.removeObject(forKey: "lastConfigHash")
        defaults?.removeObject(forKey: "lastRulesCount")
    }

    // MARK: - Core update logic

    private func _performUpdate(config: ContentBlockerConfig, hash: String, fromLaunch: Bool = false, userRequestedDisable: Bool = false) async -> RulesUpdateResult {
        isUpdating = true
        lastError = nil
        defer { isUpdating = false }

        guard config.isEnabled else {
            // Не перезаписываем полные правила пустым, если не пользователь явно выключил (иначе возможно сломанный App Group).
            if lastRulesCount > 1, !userRequestedDisable {
                return RulesUpdateResult(success: true, rulesCount: lastRulesCount, jsonSize: 0, errors: [])
            }
            if lastConfigHash == nil {
                if let readyJson = prebuiltBothWithDefaultWhitelist ?? loadCache(key: "prebuilt_both_whitelist", maxAge: nil) {
                    let count = countRules(from: readyJson)
                    let updateResult = await writeAndReload(json: readyJson, rulesCount: count)
                    if updateResult.success { saveHash(hash, rulesCount: count); lastRulesCount = count }
                    return updateResult
                }
                return RulesUpdateResult(success: true, rulesCount: 0, jsonSize: 0, errors: [])
            }
            let emptyRulesJSON = #"[{"action":{"type":"ignore-previous-rules"},"trigger":{"url-filter":".*"}}]"#
            let result = await writeAndReload(json: emptyRulesJSON, rulesCount: 1)
            if result.success { saveHash(hash, rulesCount: 0) }
            return result
        }

        guard !Task.isCancelled else { return .cancelled }

        // ──────────────────────────────────────
        // Fast path: prebuilt JSON из памяти или кэша + merge whitelist/custom
        // ──────────────────────────────────────
        let extraLines = buildExtraLines(config: config)
        // Самый быстрый путь: blockAds+blockTrackers, только default whitelist — используем pre-merged
        if config.blockAds && config.blockTrackers,
           config.whiteListedDomains.isEmpty,
           customRulesStore.filterLines().isEmpty,
           let readyJson = prebuiltBothWithDefaultWhitelist ?? loadCache(key: "prebuilt_both_whitelist", maxAge: nil) {
            let updateResult = await writeAndReload(json: readyJson, rulesCount: countRules(from: readyJson))
            if updateResult.success {
                saveHash(hash, rulesCount: countRules(from: readyJson))
                lastRulesCount = countRules(from: readyJson)
            }
            return updateResult
        }
        let baseJson = prebuiltJsonForConfig(config)
        if let baseJson {
            if extraLines.isEmpty {
                let updateResult = await writeAndReload(json: baseJson, rulesCount: countRules(from: baseJson))
                if updateResult.success {
                    saveHash(hash, rulesCount: countRules(from: baseJson))
                    lastRulesCount = countRules(from: baseJson)
                }
                return updateResult
            }
            if let merged = mergePrebuiltWithExtra(baseJson: baseJson, extraLines: extraLines) {
                let updateResult = await writeAndReload(json: merged.json, rulesCount: merged.count)
                if updateResult.success {
                    saveHash(hash, rulesCount: merged.count)
                    lastRulesCount = merged.count
                }
                return updateResult
            }
        }

        // ──────────────────────────────────────
        // 1. Global filters (EasyList, EasyPrivacy)
        // ──────────────────────────────────────
        var allLines: [String] = []
        var warnings: [String] = []
        var anyFilterLoaded = false

        for source in filterSources {
            guard config[keyPath: source.configFlag] else { continue }
            guard !Task.isCancelled else { return .cancelled }

            let text = await loadFilterWithRetry(url: source.url, fallbackUrl: source.fallbackUrl, cacheKey: source.cacheKey)

            if text.isEmpty {
                warnings.append("Failed to load \(source.cacheKey)")
            } else {
                anyFilterLoaded = true
                allLines.append(contentsOf: text.components(separatedBy: .newlines))
            }
        }

        let anyFilterRequested = filterSources.contains { config[keyPath: $0.configFlag] }
        if anyFilterRequested && !anyFilterLoaded {
            let msg = "No filter lists could be loaded. Check your internet connection."
            lastError = msg
            return RulesUpdateResult(success: false, rulesCount: 0, jsonSize: 0, errors: [msg])
        }

        guard !Task.isCancelled else { return .cancelled }

        // ──────────────────────────────────────
        // 2. Custom per-site rules
        // ──────────────────────────────────────
        let customLines = customRulesStore.filterLines()
        if !customLines.isEmpty {
            allLines.append(contentsOf: customLines)
        }

        guard !Task.isCancelled else { return .cancelled }

        // ──────────────────────────────────────
        // 3. Whitelist (ALWAYS LAST — overrides everything above)
        // ──────────────────────────────────────
        let allWhitelist = Set(config.whiteListedDomains + defaultVideoWhitelist)
        for domain in allWhitelist where !domain.isEmpty {
            let cleaned = domain
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: "www.", with: "")
            guard !cleaned.isEmpty else { continue }
            allLines.append("@@||\(cleaned)^$document")
            allLines.append("@@||\(cleaned)^")
        }

        guard !Task.isCancelled else { return .cancelled }

        // ──────────────────────────────────────
        // 4. Convert (в фоне — тяжёлая CPU-работа)
        // ──────────────────────────────────────
        let allLinesCopy = allLines
        let maxBytes = maxJsonSizeBytes
        let json: String
        let rulesCount: Int
        let convertResult = await Task.detached(priority: .userInitiated) {
            let result = ContentBlockerConverter().convertArray(
                rules: allLinesCopy,
                safariVersion: .safari16_4,
                advancedBlocking: false,
                maxJsonSizeBytes: maxBytes,
                progress: nil
            )
            let j = result.safariRulesJSON
            let count = (try? JSONSerialization.jsonObject(with: Data(j.utf8)) as? [[String: Any]])?.count ?? 0
            return (j, count)
        }.value

        json = convertResult.0
        rulesCount = convertResult.1

        guard !Task.isCancelled else { return .cancelled }

        if anyFilterLoaded && rulesCount < 100 {
            warnings.append("Unusually low rule count (\(rulesCount)). Filter files may be corrupt.")
        }

        // ──────────────────────────────────────
        // 5. Write and reload
        // ──────────────────────────────────────
        let updateResult = await writeAndReload(json: json, rulesCount: rulesCount, warnings: warnings)

        if updateResult.success {
            saveHash(hash, rulesCount: rulesCount)
            lastRulesCount = rulesCount
        } else {
            lastError = "Failed to reload content blocker"
        }

        return updateResult
    }

    // MARK: - Filter loading (bundle first, then cache/network)

    /// Загружает фильтры из файла в бандле приложения (easylist.txt / easyprivacy.txt).
    private func loadFilterFromBundle(cacheKey: String) -> String? {
        let name = (cacheKey as NSString).deletingPathExtension
        let ext = (cacheKey as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: ext.isEmpty ? "txt" : ext),
              let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8),
              text.count > 1000
        else { return nil }
        return text
    }

    private func loadFilterWithRetry(url: URL, fallbackUrl: URL, cacheKey: String) async -> String {
        if let fromBundle = loadFilterFromBundle(cacheKey: cacheKey) { return fromBundle }
        if let cached = loadCache(key: cacheKey, maxAge: nil) { return cached }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        if let cached = loadCache(key: cacheKey, maxAge: nil) { return cached }

        for attempt in 0 ..< maxRetries {
            guard !Task.isCancelled else { return "" }

            if attempt > 0 {
                let delay = retryBaseDelay * UInt64(attempt)
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled else { return "" }
            }

            if let text = await download(url: url), text.count > 1000 {
                saveCache(text: text, key: cacheKey)
                return text
            }
        }
        if let text = await download(url: fallbackUrl), text.count > 1000 {
            saveCache(text: text, key: cacheKey)
            return text
        }
        return ""
    }

    // MARK: - Networking

    private func download(url: URL) async -> String? {
        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200 ..< 300).contains(http.statusCode) { return nil }
            return String(data: data, encoding: .utf8)
        } catch is CancellationError {
            return nil
        } catch {
            return nil
        }
    }

    // MARK: - Cache

    private func containerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    private func cacheFileURL(key: String) -> URL? {
        containerURL()?.appendingPathComponent("cache_\(key)")
    }

    /// maxAge == nil — использовать кэш при любом возрасте (никогда не перекачивать)
    private func loadCache(key: String, maxAge: TimeInterval?) -> String? {
        guard let url = cacheFileURL(key: key),
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url)
        else { return nil }
        if let maxAge = maxAge {
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let modified = attrs[.modificationDate] as? Date,
                  Date().timeIntervalSince(modified) < maxAge
            else { return nil }
        }
        return String(data: data, encoding: .utf8)
    }

    private func saveCache(text: String, key: String) {
        guard let url = cacheFileURL(key: key) else { return }
        do {
            try text.data(using: .utf8)?.write(to: url, options: .atomic)
        } catch { }
    }

    private func deleteCacheFile(key: String) {
        guard let url = cacheFileURL(key: key) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - JSON write & Safari reload

    private func writeAndReload(json: String, rulesCount: Int, warnings: [String] = []) async -> RulesUpdateResult {
        guard let container = containerURL() else {
            print("[AppGroup] container nil → запись правил пропущена")
            return RulesUpdateResult(success: false, rulesCount: 0, jsonSize: 0, errors: ["App group container unavailable"])
        }
        let fileURL = container.appendingPathComponent(jsonFileName)
        do {
            try json.data(using: .utf8)?.write(to: fileURL, options: .atomic)
        } catch {
            return RulesUpdateResult(success: false, rulesCount: 0, jsonSize: 0, errors: ["JSON write failed: \(error.localizedDescription)"])
        }
        var reloadSuccess = false
        for attempt in 0 ..< 3 {
            if attempt > 0 { try? await Task.sleep(nanoseconds: 1_000_000_000) }
            reloadSuccess = await reloadContentBlocker()
            if reloadSuccess { break }
        }
        print("[RulesService] Applied \(rulesCount) rules, reload: \(reloadSuccess)")

        return RulesUpdateResult(
            success: reloadSuccess,
            rulesCount: rulesCount,
            jsonSize: json.utf8.count,
            errors: reloadSuccess ? warnings : warnings + ["Content blocker reload failed"]
        )
    }

    private func reloadContentBlocker() async -> Bool {
        await withCheckedContinuation { continuation in
            SFContentBlockerManager.reloadContentBlocker(withIdentifier: blockerID) { error in
                continuation.resume(returning: error == nil)
            }
        }
    }

    // MARK: - Hash (includes custom rules)

    private func hashConfig(_ config: ContentBlockerConfig) -> String {
        let raw = [
            "\(config.isEnabled)",
            "\(config.blockAds)",
            "\(config.blockTrackers)",
            "\(config.antiAdblock)",
            config.whiteListedDomains.sorted().joined(separator: ","),
            customRulesStore.contentHash(),
        ].joined(separator: "|")

        let hash = SHA256.hash(data: Data(raw.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func saveHash(_ hash: String, rulesCount: Int) {
        lastConfigHash = hash
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(hash, forKey: "lastConfigHash")
        defaults?.set(rulesCount, forKey: "lastRulesCount")
    }

    // MARK: - Prebuilt JSON helpers

    /// Возвращает prebuilt JSON из памяти или с диска
    private func prebuiltJsonForConfig(_ config: ContentBlockerConfig) -> String? {
        let ads = config.blockAds
        let trackers = config.blockTrackers
        if ads && trackers {
            return prebuiltBothJson ?? loadCache(key: "prebuilt_both", maxAge: nil)
        }
        if ads {
            return prebuiltAdsJson ?? loadCache(key: "prebuilt_ads", maxAge: nil)
        }
        if trackers {
            return prebuiltTrackersJson ?? loadCache(key: "prebuilt_trackers", maxAge: nil)
        }
        return nil
    }

    private func buildExtraLines(config: ContentBlockerConfig) -> [String] {
        var lines: [String] = []
        // Whitelist first — перекрывает блокировки
        let allWhitelist = Set(config.whiteListedDomains + defaultVideoWhitelist)
        for domain in allWhitelist where !domain.isEmpty {
            let cleaned = domain
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .replacingOccurrences(of: "www.", with: "")
            guard !cleaned.isEmpty else { continue }
            lines.append("@@||\(cleaned)^$document")
            lines.append("@@||\(cleaned)^")
        }
        lines.append(contentsOf: customRulesStore.filterLines())
        return lines
    }

    private func convertToJson(_ lines: [String]) -> String? {
        Self.staticConvertToJson(lines, maxJsonSizeBytes: maxJsonSizeBytes)
    }

    private nonisolated static func staticConvertToJson(_ lines: [String], maxJsonSizeBytes: Int) -> String? {
        let result = ContentBlockerConverter().convertArray(
            rules: lines,
            safariVersion: .safari16_4,
            advancedBlocking: false,
            maxJsonSizeBytes: maxJsonSizeBytes,
            progress: nil
        )
        return result.safariRulesJSON.isEmpty ? nil : result.safariRulesJSON
    }

    private func mergePrebuiltWithExtra(baseJson: String, extraLines: [String]) -> (json: String, count: Int)? {
        let extraJson = convertToJson(extraLines)
        guard let extraJson, !extraJson.isEmpty else { return nil }
        guard let result = Self.staticMergePrebuiltWithExtra(baseJson: baseJson, extraLines: extraLines, maxJsonSizeBytes: maxJsonSizeBytes)
        else { return nil }
        return (result.json, result.count)
    }

    private nonisolated static func staticMergePrebuiltWithExtra(baseJson: String, extraLines: [String], maxJsonSizeBytes: Int) -> (json: String, count: Int)? {
        guard let extraJson = staticConvertToJson(extraLines, maxJsonSizeBytes: maxJsonSizeBytes), !extraJson.isEmpty else { return nil }
        guard let baseArray = try? JSONSerialization.jsonObject(with: Data(baseJson.utf8)) as? [[String: Any]],
              let extraArray = try? JSONSerialization.jsonObject(with: Data(extraJson.utf8)) as? [[String: Any]]
        else { return nil }
        let merged = extraArray + baseArray
        guard let data = try? JSONSerialization.data(withJSONObject: merged),
              let json = String(data: data, encoding: .utf8)
        else { return nil }
        return (json, merged.count)
    }

    private func countRules(from json: String) -> Int {
        (try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: Any]])?.count ?? 0
    }
}
