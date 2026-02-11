
import Foundation
import SafariServices

final class RulesService {
    private let easyListService = EasyListService()
    
    func updateRules(config: ContentBlockerConfig) {

        easyListService.buildBlockingRules { [weak self] easyRules in

            guard let self else { return }

            let localRules = self.generateLocalRules(config: config)
            let whitelistRules = self.generateWhitelistRules(config: config)

            var rules: [BlockingRule] = []

            rules.append(contentsOf: easyRules)      // Изи лист
            rules.append(contentsOf: localRules)     // Локальные
            rules.append(contentsOf: whitelistRules) // Наш вайт лист
            
            //На время дебага
            print("🔵 EasyList rules:", easyRules.count)
            print("🟢 Local rules:", localRules.count)
            print("🟣 Whitelist rules:", whitelistRules.count)
            print("📦 Total rules:", rules.count)
            print("----- FIRST 3 RULES -----")
            rules.prefix(3).forEach { print($0) }

            print("----- LAST 3 RULES -----")
            rules.suffix(3).forEach { print($0) }

            let data = self.encodeRules(rules)
            self.saveRulesToAppGroup(data)
            self.reloadContentBlocker()
        }
    }
    

    
    func generateLocalRules(config: ContentBlockerConfig) -> [BlockingRule] {
        var rules: [BlockingRule] = []
        guard config.isEnabled else {
            return rules
        }

        if config.blockAds {
            rules.append(makeAdsBlockingRule())
        }

        if config.blockTrackers {
            rules.append(makeTrackersBlockingRule())
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
 
    
    func makeTrackersBlockingRule() -> BlockingRule {
        BlockingRule(trigger: BlockingTrigger(urlFilter: ".*",
                                              ifDomain: nil,
                                              loadType: ["third-party"],
                                              resourceType: nil),
                     action: BlockingAction(type: .block))
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
        encoder.outputFormatting = [.prettyPrinted]
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
