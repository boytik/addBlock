
import Foundation

final class RulesService {
    
    func updateRules(config: ContentBlockerConfig) {
        let rules = generateRules(config: config)
        let data = encodeRules(rules)
        saveRulesToAppGroup(data)
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
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.boytik.adblock")
        else {
            return
        }
        let fileURL = containerURL.appendingPathComponent("blockerList.json")
        try? data.write(to: fileURL)
    }
 }
