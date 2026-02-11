
import Foundation
import SafariServices

final class RulesService {
    private let easyListService = EasyListService()
    
    func updateRules(config: ContentBlockerConfig) {
        easyListService.buildBlockingTules { [weak self] easyRules in
            
            guard let self else { return }
            
            var rules = self.generateRules(config: config)
            rules.append(contentsOf: easyRules)
            
            let data = self.encodeRules(rules)
            
            self.saveRulesToAppGroup(data)
            self.reloadContentBlocker()
        }
    }
    
    func generateRules(config: ContentBlockerConfig) -> [BlockingRule] {
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
        
        for domain in config.whiteListedDomains {
            rules.append(makeWhitelistRule(for: domain))
        }
        
        return rules
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
