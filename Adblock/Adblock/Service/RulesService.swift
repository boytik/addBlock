
import Foundation
import SafariServices

final class RulesService {
    private let easyListService = EasyListService()
    private let easyPrivacyService = EasyPrivacyService()
    
    private var currentTask: Task<Void, Never>?
    //limis
    private let maxTotalRules = 50_000
    private let maxEasyListWhenBoth = 35_000
    private let maxPrivacyWhenBoth = 15_000
    
    func updateRules(config: ContentBlockerConfig)  {
        
        currentTask?.cancel()
        
        currentTask = Task {[weak self] in
            await self?.performUpdate(config: config)
        }
    }
    private func performUpdate (config: ContentBlockerConfig) async {
        guard !Task.isCancelled else { return }
        
        guard config.isEnabled else {
            saveRulesToAppGroup(encodeRules([]))
            reloadContentBlocker()
            return
        }
        
        async let easyRules = easyListService.buildBlockingRules()
        async let privacyRule: [BlockingRule] =
        config.blockTrackers
        ? easyPrivacyService.buildBlockingRules()
        : []
        
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
        
        let data = encodeRules(rules)
        saveRulesToAppGroup(data)
        reloadContentBlocker()
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
        try? data.write(to: fileURL)
    }
    
    private func reloadContentBlocker() {
        SFContentBlockerManager.reloadContentBlocker(
               withIdentifier: "test.com.adblock.blocker"
           ) { error in
               if let error {
                   print("❌ Content Blocker reload failed:", error.localizedDescription)
               } else {
                   print("✅ Content Blocker reloaded successfully")
               }
           }
    }
 }
