import Foundation
import SafariServices
import ContentBlockerConverter
import CryptoKit
import Combine

@MainActor
final class RulesService {
    
    private let maxJsonSize: Double = 15
    private var currentTask: Task<Void, Never>?
    private var lastConfigHash: String?
    @Published private(set) var isUpdating: Bool = false
    
    private let appGroupID = "group.test.com.adblock"
    private let blockerID = "test.com.adblock.blocker"
    
    // URL фильтров
    private let easyListURL = URL(string: "https://easylist.to/easylist/easylist.txt")!
    private let easyPrivacyURL = URL(string: "https://easylist.to/easylist/easyprivacy.txt")!
    
    private let cacheLifetime: TimeInterval = 60 * 60 * 24
    
    init() {
        let defaults = UserDefaults(suiteName: appGroupID)
        lastConfigHash = defaults?.string(forKey: "lastConfigHash")
    }
    
    func validateOnLaunch(config: ContentBlockerConfig) {
        let newHash = hashConfig(config: config)
        if newHash != lastConfigHash {
            Task { await updateRules(config: config) }
        }
    }
    
    @discardableResult
    func updateRules(config: ContentBlockerConfig) async -> Bool {
        let newHash = hashConfig(config: config)
        guard newHash != lastConfigHash else { return true }
        
        currentTask?.cancel()
        currentTask = Task {
            self.isUpdating = true
            defer { self.isUpdating = false }
            
            let success = await performUpdate(config: config)
            if success {
                self.lastConfigHash = newHash
                let defaults = UserDefaults(suiteName: appGroupID)
                defaults?.set(newHash, forKey: "lastConfigHash")
            }
        }
        return true
    }

    
    private func performUpdate(config: ContentBlockerConfig) async -> Bool {
        guard !Task.isCancelled else { return false }
        
        guard config.isEnabled else {
            saveJSON("[]")
            return await reloadContentBlocker()
        }
        
        var lines: [String] = []
        
        if config.blockAds {
            let text = await loadFilter(url: easyListURL, cacheKey: "easylist.txt")
            lines.append(contentsOf: text.components(separatedBy: .newlines))
        }
        
        if config.blockTrackers {
            let text = await loadFilter(url: easyPrivacyURL, cacheKey: "easyprivacy.txt")
            lines.append(contentsOf: text.components(separatedBy: .newlines))
        }
        
        guard !Task.isCancelled else { return false }
        
        // Whitelist
        let allWhitelist = Set(config.whiteListedDomains + defaultVideoWhitelist)
        for domain in allWhitelist {
            lines.append("@@||\(domain)^$document")
            lines.append("@@||\(domain)^")
        }
        
        // Конвертируем с лимитом 6MB
        let result = ContentBlockerConverter().convertArray(
            rules: lines,
            safariVersion: .safari16_4,
            advancedBlocking: false,
            maxJsonSizeBytes: 6 * 1024 * 1024,
            progress: nil
        )
        
        guard !Task.isCancelled else { return false }
        
        let json = result.safariRulesJSON
        print("!! JSON size: \(json.count) bytes")
        
        saveJSON(json)
        let success = await reloadContentBlocker()
        print("!! Reload success: \(success)")
        return success
    }
    // MARK: - Video whitelist
    
    private let defaultVideoWhitelist = [
        "youtube.com",
        "googlevideo.com",
        "ytimg.com",
        "twitch.tv",
        "ttvnw.net",
        "jtvnw.net",
        "live-video.net",
        "vimeo.com",
        "vimeocdn.com"
    ]
    
    // MARK: - Filter loading with cache
    
    private func loadFilter(url: URL, cacheKey: String) async -> String {
        if let cached = loadCache(key: cacheKey) {
            return cached
        }
        
        guard let text = await download(url: url) else { return "" }
        saveCache(text: text, key: cacheKey)
        return text
    }
    
    private func download(url: URL) async -> String? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return String(data: data, encoding: .utf8)
        } catch {
            print("!! Download error: \(error)")
            return nil
        }
    }
    
    private func cacheURL(key: String) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(key)
    }
    
    private func loadCache(key: String) -> String? {
        guard let url = cacheURL(key: key),
              FileManager.default.fileExists(atPath: url.path),
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modified = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(modified) < cacheLifetime,
              let data = try? Data(contentsOf: url)
        else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func saveCache(text: String, key: String) {
        guard let url = cacheURL(key: key) else { return }
        try? text.data(using: .utf8)?.write(to: url)
    }
    
    // MARK: - JSON save & reload
    
    private func saveJSON(_ json: String) {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
        else { return }
        let fileURL = containerURL.appendingPathComponent("blockerList.json")
        try? json.data(using: .utf8)?.write(to: fileURL, options: .atomic)
    }
    
    private func reloadContentBlocker() async -> Bool {
        await withCheckedContinuation { continuation in
            SFContentBlockerManager.reloadContentBlocker(
                withIdentifier: blockerID
            ) { error in
                continuation.resume(returning: error == nil)
            }
        }
    }
    
    func hashConfig(config: ContentBlockerConfig) -> String {
        let raw = "\(config.isEnabled)|\(config.blockAds)|\(config.blockTrackers)|\(config.antiAdblock)|\(config.whiteListedDomains.sorted().joined())"
        let hash = SHA256.hash(data: Data(raw.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
