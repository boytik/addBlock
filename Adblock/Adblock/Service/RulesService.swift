
import Foundation
import SafariServices

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
    
    init() {
        let defaults = UserDefaults(suiteName: "group.test.om.adblock")
        lastConfigHash = defaults?.string(forKey: "lastConfigHash")
        
        print("!!Loaded last Config Hash")
    }
    
    func validateOnLaunch(config: ContentBlockerConfig) {
        let newHas = hashConfig(config: config)
        
        if newHas != lastConfigHash {
            updateRules(config: config)
            print("!!Config changed")
        } else {
            print("!!Config unchanged on launch")
        }
    }
    
    func updateRules(config: ContentBlockerConfig)  {
        let newHash = hashConfig(config: config)
        
        guard newHash != lastConfigHash else {
            return
        }
        
        lastConfigHash = newHash
        
        currentTask?.cancel()
        
        currentTask = Task {[weak self] in
            await self?.performUpdate(config: config)
        }
    }
    
    func hashConfig(config: ContentBlockerConfig) -> String {
        let raw = "\(config.isEnabled)|\(config.blockAds)|\(config.blockTrackers)|\(config.antiAdblock)|\(config.whiteListedDomains.joined())"
        return String(raw.hashValue)
    }
    
    private func performUpdate (config: ContentBlockerConfig) async {
        guard !Task.isCancelled else { return }
        
        guard config.isEnabled else {
            saveRulesToAppGroup(encodeRules([]))
            reloadContentBlocker()
            return
        }
        
        let downloadStart = Date()
        
        async let easyRules = easyListService.buildBlockingRules()
        async let privacyRule: [BlockingRule] =
        config.blockTrackers
        ? easyPrivacyService.buildBlockingRules()
        : []
        let downloadTime = Date().timeIntervalSince(downloadStart)
        print("⏱ Download time:", String(format: "%.2f sec", downloadTime))
        
        let listRules = Array ((await easyRules).prefix(maxEasyListWhenBoth))
        print("🔵 EasyList rules:", listRules.count)
        let trackerRules = Array ((await privacyRule).prefix(maxPrivacyWhenBoth))
        print("🟣 EasyPrivacy rules:", trackerRules.count)
        
        var rules: [BlockingRule] = []
        
        rules.append(contentsOf: listRules)
        rules.append(contentsOf: trackerRules)
        
        rules.append(contentsOf: generateLocalRules(config: config))
        rules.append(contentsOf: generateWhitelistRules(config: config))
        
        print("📦 Total rules:", rules.count)
        rules = removeDuplicates(from: rules)
        let encodeStart = Date()
        guard let data = encodeRules(rules) else { return }
        let encodeTime = Date().timeIntervalSince(encodeStart)
        print("⏱ Encode time:", String(format: "%.2f sec", encodeTime))
        let sizeMB = Double(data.count) / 1024 / 1024
        
        guard sizeMB <= maxJsonSize else {
            return
        }
        saveRulesToAppGroup(data)
        reloadContentBlocker()
        let totalTime = Date().timeIntervalSince(downloadStart)
        print("🚀 Total update time:", String(format: "%.2f sec", totalTime))
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
    
    private func reloadContentBlocker() {
        let reloadStart = Date()

        SFContentBlockerManager.reloadContentBlocker(
            withIdentifier: "test.com.adblock.blocker"
        ) { error in
            let reloadTime = Date().timeIntervalSince(reloadStart)

            if let error {
                print("❌ Reload failed:", error.localizedDescription)
            } else {
                print("✅ Reload success")
            }

            print("⏱ Reload time:", String(format: "%.2f sec", reloadTime))
        }
    }
}
