//
//
//import Foundation
//
//struct EasyListParser {
//    
//    func parse(from text: String) -> [ABPRule] {
//        let lines = text.components(separatedBy: .newlines)
//        return lines.compactMap { line in
//            parseLine(line)
//        }
//    }
//    
//    private func parseLine(_ line: String) -> ABPRule? {
//        
//        if line.hasPrefix("!") || line.isEmpty {
//            return nil
//        }
//        
//        // игнорируем CSS hiding
//        if line.contains("##") || line.contains("#@#") {
//            return nil
//        }
//        
//        // исключение
//        if line.hasPrefix("@@||") {
//            let cleaned = String(line.dropFirst(2))
//            return parseDomainRule(cleaned, type: .exception)
//        }
//        
//        // обычная блокировка
//        if line.hasPrefix("||") {
//            return parseDomainRule(line, type: .block)
//        }
//        
//        return nil
//    }
//    
//    private func parseDomainRule(_ line: String, type: ABPRuleType) -> ABPRule? {
//
//        guard line.hasPrefix("||") else { return nil }
//
//        var rule = line.replacingOccurrences(of: "||", with: "")
//
//        var resourceTypes: [String] = []
//
//        // Парсим $опции
//        if let dollarIndex = rule.firstIndex(of: "$") {
//            let optionsPart = rule[dollarIndex...]
//            rule = String(rule[..<dollarIndex])
//
//            let optionsString = optionsPart.dropFirst()
//            resourceTypes = optionsString
//                .split(separator: ",")
//                .map { String($0) }
//        }
//
//        // Убираем ^
//        rule = rule.replacingOccurrences(of: "^", with: "")
//
//        return ABPRule(
//            pattern: rule,
//            type: type,
//            resourceTypes: resourceTypes
//        )
//    }
//}
