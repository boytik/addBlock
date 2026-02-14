
import Foundation
import SafariServices
import Combine
import CryptoKit

@MainActor
final class RulesService {
    private let easyListService = EasyListService()
    private let easyPrivacyService = EasyPrivacyService()
    
    //limis
    private let maxTotalRules = 50_000
    private let maxEasyListWhenBoth = 35_000
    private let maxPrivacyWhenBoth = 15_000
    private let maxJsonSize: Double = 15
    //Protect
    private var currentTask: Task<Void, Never>?
    private var lastConfigHash: String?
    @Published private(set) var isUpdating: Bool = false
    
    init() {
        let defaults = UserDefaults(suiteName: "group.test.com.adblock")
        lastConfigHash = defaults?.string(forKey: "lastConfigHash")
        
        print("!!Loaded last Config Hash")
    }
    
    func validateOnLaunch(config: ContentBlockerConfig) {
        let newHash = hashConfig(config: config)

        if newHash != lastConfigHash {
            Task {
                await updateRules(config: config)
            }
            print("!! Config changed")
        } else {
            print("!! Config unchanged on launch")
        }
    }
    
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
                let defaults = UserDefaults(suiteName: "group.test.com.adblock")
                defaults?.set(newHash, forKey: "lastConfigHash")
            }
        }

        return true
    }
    

    func hashConfig(config: ContentBlockerConfig) -> String {
        let raw = "\(config.isEnabled)|\(config.blockAds)|\(config.blockTrackers)|\(config.antiAdblock)|\(config.whiteListedDomains.sorted().joined())"
        let data = Data(raw.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func performUpdate (config: ContentBlockerConfig) async -> Bool {
        guard !Task.isCancelled else { return false}
        
        guard config.isEnabled else {
            saveRulesToAppGroup(encodeRules([]))
            let success = await reloadContentBlocker()
            return success
        }
        
        async let easyRules = easyListService.buildBlockingRules()
        async let privacyRule: [BlockingRule] =
        config.blockTrackers
        ? easyPrivacyService.buildBlockingRules()
        : []
        
        let listRules = Array ((await easyRules).prefix(maxEasyListWhenBoth))
        guard !Task.isCancelled else { return false }
        let trackerRules = Array ((await privacyRule).prefix(maxPrivacyWhenBoth))
        guard !Task.isCancelled else { return false}
        
        var rules: [BlockingRule] = []
        
        rules.append(contentsOf: listRules)
        rules.append(contentsOf: trackerRules)
        
        rules.append(contentsOf: generateLocalRules(config: config))
        rules.append(contentsOf: generateWhitelistRules(config: config))
        print("!! Количество правил: \(rules.count)")
        guard !Task.isCancelled else { return false}
        
        rules = removeDuplicates(from: rules)
        print("!! Количество правил после дедупликации: \(rules.count)")
        guard let data = encodeRules(rules) else { return false}
        
        guard !Task.isCancelled else { return false}
        
        let sizeMB = Double(data.count) / 1024 / 1024
        
        guard sizeMB <= maxJsonSize else {
            return false
        }
        saveRulesToAppGroup(data)
        let reloadSuccess = await reloadContentBlocker()
        return reloadSuccess
    }
    
    
    
    func generateLocalRules(config: ContentBlockerConfig) -> [BlockingRule] {
        var rules: [BlockingRule] = []
        guard config.isEnabled else {
            return rules
        }
        
        if config.blockAds {
            rules.append(makeAdsBlockingRule())
        }
        
        if config.antiAdblock {
            rules.append(makeAntiAdblockRule())
        }
        
        return rules
    }
    
    func generateWhitelistRules(config: ContentBlockerConfig) -> [BlockingRule] {
        
        config.whiteListedDomains.map {
            makeWhitelistRule(for: $0)
        }
    }
    
    func makeAdsBlockingRule() -> BlockingRule {
        BlockingRule(trigger: BlockingTrigger(urlFilter: ".*ads.",
                                              ifDomain: nil,
                                              loadType: nil,
                                              resourceType: ["image", "script"]),
                     action: BlockingAction(type: .block))
    }
    
    func makeAntiAdblockRule() -> BlockingRule {
        BlockingRule(
            trigger: BlockingTrigger(
                urlFilter: ".*(adblock|antiadblock|blockdetect).*",
                ifDomain: nil,
                loadType: nil,
                resourceType: ["script"]
            ),
            action: BlockingAction(type: .block)
        )
    }
    
    
    func makeWhitelistRule(for domain: String ) -> BlockingRule {
        BlockingRule(trigger: BlockingTrigger(urlFilter: ".*",
                                              ifDomain: [domain],
                                              loadType: nil,
                                              resourceType: nil),
                     action: BlockingAction(type: .ignorePreviousRules))
    }
    
    func encodeRules(_ rules: [BlockingRule])-> Data? {
        let encoder = JSONEncoder()
        do {
            return try encoder.encode(rules)
        } catch {
            return nil
        }
    }
    
    func saveRulesToAppGroup( _ data : Data?) {
        guard let data,
              let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.test.com.adblock")
        else {
            return
        }
        let fileURL = containerURL.appendingPathComponent("blockerList.json")
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Faild to write blockerList", error.localizedDescription)
        }
    }
    
    private func removeDuplicates(from rules: [BlockingRule]) -> [BlockingRule] {
        var seen = Set<String>()
        var result: [BlockingRule] = []

        for rule in rules {
            let key = rule.dedupeKey

            if !seen.contains(key) {
                seen.insert(key)
                result.append(rule)
            }
        }

        return result
    }
    
    private func reloadContentBlocker() async -> Bool {
        await withCheckedContinuation { continuation in
            SFContentBlockerManager.reloadContentBlocker(
                withIdentifier: "test.com.adblock.blocker"
            ) { error in
                if error != nil {
                    continuation.resume(returning: false)
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
    }}
