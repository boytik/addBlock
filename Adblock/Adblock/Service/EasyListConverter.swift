
import Foundation

final class EasyListConverter {
    private let maxCountOfRules:Int = 47000
    
    func convert(rules: [ABPRule]) -> [BlockingRule] {
        let limited = rules.prefix(maxCountOfRules)
        return limited.map { convertRule(rule: $0)}
    }
    
    private func convertRule(rule: ABPRule) -> BlockingRule {
        let actionType: BlockingActionType = {
            switch rule.type {
            case .block :
                return .block
            case .exception:
                return .ignorePreviousRules
            }
        }()
        return BlockingRule(trigger: BlockingTrigger(urlFilter: rule.pattern,
                                                     ifDomain: nil,
                                                     loadType: nil,
                                                     resourceType: nil),
                            action: BlockingAction(type: actionType))
    }
}
