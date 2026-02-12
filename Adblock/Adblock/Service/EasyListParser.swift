

import Foundation

struct EasyListParser {
    
    func parse(from text: String) -> [ABPRule] {
        let lines = text.components(separatedBy: .newlines)
        return lines.compactMap { line in
            parseLine(line)
        }
    }
    
    private func parseLine(_ line: String) -> ABPRule? {

        if line.hasPrefix("!") || line.isEmpty {
            return nil
        }

        // игнорируем CSS hiding
        if line.contains("##") || line.contains("#@#") {
            return nil
        }

        // исключение
        if line.hasPrefix("@@||") {
            let cleaned = String(line.dropFirst(2))
            return parseDomainRule(cleaned, type: .exception)
        }

        // обычная блокировка
        if line.hasPrefix("||") {
            return parseDomainRule(line, type: .block)
        }

        return nil
    }
    
    private func parseDomainRule(_ line: String, type: ABPRuleType) -> ABPRule? {
        guard line.hasPrefix("||"),
              line.hasSuffix("^") else {
            return nil
        }
        let trimmed = line
            .replacingOccurrences(of: "||", with: "")
            .replacingOccurrences(of: "^", with: "")
        return ABPRule(pattern: trimmed,
                       type: type)
    }
}
