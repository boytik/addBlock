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

    private let filterSources: [(url: URL, cacheKey: String, configFlag: KeyPath<ContentBlockerConfig, Bool>)] = [
        (URL(string: "https://raw.githubusercontent.com/boytik/addBlock/048611aa447398290f441445e5743c329d017ad9/easylist.txt")!, "easylist.txt", \.blockAds),
        (URL(string: "https://raw.githubusercontent.com/boytik/addBlock/048611aa447398290f441445e5743c329d017ad9/easyprivacy.txt")!, "easyprivacy.txt", \.blockTrackers),
    ]

    private let defaultVideoWhitelist = [
        "youtube.com", "googlevideo.com", "ytimg.com",
        "twitch.tv", "ttvnw.net", "jtvnw.net", "live-video.net",
        "vimeo.com", "vimeocdn.com",
    ]

    // MARK: - Stores

    private let customRulesStore: CustomRulesStore

    // MARK: - Tuning

    /// Кэш правил: 30 дней. Правила скачиваются при первом запуске (preload) и при необходимости.
    private let cacheLifetime: TimeInterval = 60 * 60 * 24 * 30
    private let staleCacheLifetime: TimeInterval = 60 * 60 * 24 * 90
    private let maxRetries = 3
    private let retryBaseDelay: UInt64 = 2_000_000_000
    private let maxJsonSizeBytes = 6 * 1024 * 1024

    // MARK: - Internal state

    private var currentTask: Task<RulesUpdateResult, Never>?
    private var lastConfigHash: String?
    private let session: URLSession

    // MARK: - Init

    init(customRulesStore: CustomRulesStore) {
        self.customRulesStore = customRulesStore

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        self.session = URLSession(configuration: config)

        let defaults = UserDefaults(suiteName: appGroupID)
        lastConfigHash = defaults?.string(forKey: "lastConfigHash")
        lastRulesCount = defaults?.integer(forKey: "lastRulesCount") ?? 0

        Task { await preloadFilters() }
    }

    // MARK: - Public API

    /// Скачивает правила при старте приложения (в фоне). Пока пользователь на онбординге — правила уже в кэше.
    func preloadFilters() async {
        for source in filterSources {
            _ = await loadFilterWithRetry(url: source.url, cacheKey: source.cacheKey)
        }
        print("[RulesService] Preload завершён — правила в кэше")
    }

    func validateOnLaunch(config: ContentBlockerConfig) {
        let newHash = hashConfig(config)
        guard newHash != lastConfigHash else { return }
        Task { await updateRules(config: config) }
    }

    @discardableResult
    func forceUpdate(config: ContentBlockerConfig) async -> RulesUpdateResult {
        lastConfigHash = nil
        UserDefaults(suiteName: appGroupID)?.removeObject(forKey: "lastConfigHash")
        return await updateRules(config: config)
    }

    @discardableResult
    func updateRules(config: ContentBlockerConfig) async -> RulesUpdateResult {
        let newHash = hashConfig(config)

        if newHash == lastConfigHash {
            return RulesUpdateResult(success: true, rulesCount: lastRulesCount, jsonSize: 0, errors: [])
        }

        currentTask?.cancel()

        let task = Task<RulesUpdateResult, Never> {
            await _performUpdate(config: config, hash: newHash)
        }
        currentTask = task
        return await task.value
    }

    func clearCaches() {
        for source in filterSources {
            deleteCacheFile(key: source.cacheKey)
        }
        lastConfigHash = nil
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.removeObject(forKey: "lastConfigHash")
        defaults?.removeObject(forKey: "lastRulesCount")
    }

    // MARK: - Core update logic

    private func _performUpdate(config: ContentBlockerConfig, hash: String) async -> RulesUpdateResult {
        isUpdating = true
        lastError = nil
        defer { isUpdating = false }

        guard config.isEnabled else {
            // Пустой массив [] иногда вызывает сбой reload. Используем минимальное правило (ignore-previous-rules),
            // которое не блокирует ничего, но позволяет reload пройти успешно.
            let emptyRulesJSON = #"[{"action":{"type":"ignore-previous-rules"},"trigger":{"url-filter":".*"}}]"#
            let result = await writeAndReload(json: emptyRulesJSON, rulesCount: 1)
            if result.success { saveHash(hash, rulesCount: 0) }
            return result
        }

        guard !Task.isCancelled else { return .cancelled }

        // ──────────────────────────────────────
        // 1. Global filters (EasyList, EasyPrivacy)
        // ──────────────────────────────────────
        var allLines: [String] = []
        var warnings: [String] = []
        var anyFilterLoaded = false

        for source in filterSources {
            guard config[keyPath: source.configFlag] else { continue }
            guard !Task.isCancelled else { return .cancelled }

            let text = await loadFilterWithRetry(url: source.url, cacheKey: source.cacheKey)

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

    // MARK: - Filter loading with retry + stale fallback

    private func loadFilterWithRetry(url: URL, cacheKey: String) async -> String {
        if let cached = loadCache(key: cacheKey, maxAge: nil) {
            print("[RulesService] \(cacheKey): из кэша (\(cached.count) символов)")
            return cached
        }

        for waitSeconds in [2, 4] {
            try? await Task.sleep(nanoseconds: UInt64(waitSeconds) * 1_000_000_000)
            if let cached = loadCache(key: cacheKey, maxAge: nil) {
                print("[RulesService] \(cacheKey): из кэша после ожидания preload (\(cached.count) символов)")
                return cached
            }
        }

        for attempt in 0 ..< maxRetries {
            guard !Task.isCancelled else { return "" }

            if attempt > 0 {
                let delay = retryBaseDelay * UInt64(attempt)
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled else { return "" }
            }

            if let text = await download(url: url) {
                guard text.count > 1000 else {
                    print("[RulesService] Suspicious small response (\(text.count) bytes) from \(url.lastPathComponent), retrying...")
                    continue
                }
                saveCache(text: text, key: cacheKey)
                print("[RulesService] \(cacheKey): скачано (\(text.count) символов)")
                return text
            }
        }

        print("[RulesService] All attempts failed for \(cacheKey)")
        return ""
    }

    // MARK: - Networking

    private func download(url: URL) async -> String? {
        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200 ..< 300).contains(http.statusCode) {
                print("[RulesService] HTTP \(http.statusCode) from \(url.lastPathComponent)")
                return nil
            }
            return String(data: data, encoding: .utf8)
        } catch is CancellationError {
            return nil
        } catch {
            print("[RulesService] Download error (\(url.lastPathComponent)): \(error.localizedDescription)")
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
        } catch {
            print("[RulesService] Cache write error (\(key)): \(error.localizedDescription)")
        }
    }

    private func deleteCacheFile(key: String) {
        guard let url = cacheFileURL(key: key) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - JSON write & Safari reload

    private func writeAndReload(json: String, rulesCount: Int, warnings: [String] = []) async -> RulesUpdateResult {
        guard let container = containerURL() else {
            return RulesUpdateResult(success: false, rulesCount: 0, jsonSize: 0, errors: ["App group container unavailable"])
        }

        let fileURL = container.appendingPathComponent(jsonFileName)

        do {
            try json.data(using: .utf8)?.write(to: fileURL, options: .atomic)
        } catch {
            return RulesUpdateResult(success: false, rulesCount: 0, jsonSize: 0, errors: ["JSON write failed: \(error.localizedDescription)"])
        }

        print("[Обновляем правила] - отправлено \(rulesCount) правил")
        var reloadSuccess = false
        for attempt in 0 ..< 3 {
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            reloadSuccess = await reloadContentBlocker()
            if reloadSuccess { break }
        }

        let size = json.utf8.count
        print("[RulesService] Wrote \(rulesCount) rules (\(size) bytes), reload: \(reloadSuccess)")

        return RulesUpdateResult(
            success: reloadSuccess,
            rulesCount: rulesCount,
            jsonSize: size,
            errors: reloadSuccess ? warnings : warnings + ["Content blocker reload failed"]
        )
    }

    private func reloadContentBlocker() async -> Bool {
        await withCheckedContinuation { continuation in
            SFContentBlockerManager.reloadContentBlocker(withIdentifier: blockerID) { error in
                if let error {
                    print("ОШИБКА ПЕРЕЗАГРУЗКИ ПРАВИЛ")
                }
                print("Правила обновились")
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
}
