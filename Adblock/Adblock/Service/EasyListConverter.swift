//import Foundation
//
//final class EasyListConverter {
//
//    private let allowedTypes: Set<String> = [
//        "script",
//        "image",
//        "stylesheet",
//        "font"
//    ]
//
//    // Домены, которые НИКОГДА не блокируем (видео-CDN)
//    private let protectedDomains = [
//        "*youtube.com",
//        "*googlevideo.com",
//        "*ytimg.com",
//        "*yt3.ggpht.com",
//        "*twitch.tv",
//        "*ttvnw.net",
//        "*jtvnw.net",
//        "*live-video.net",
//        "*vimeo.com",
//        "*vimeocdn.com",
//        "*dailymotion.com"
//    ]
//
//    func convert(rules: [ABPRule]) -> [BlockingRule] {
//
//        rules.compactMap { rule -> BlockingRule? in
//            guard rule.type == .block else { return nil }
//            guard isSafePattern(rule.pattern) else { return nil }
//
//            return BlockingRule(
//                trigger: BlockingTrigger(
//                    urlFilter: "^[^:]+://([^/]+\\.)?\(escape(rule.pattern))(/|$)",
//                    ifDomain: nil,
//                    unlessDomain: protectedDomains,
//                    loadType: ["third-party"],
//                    resourceType: makeSafeTypes(from: rule.resourceTypes)
//                ),
//                action: BlockingAction(type: .block)
//            )
//        }
//    }
//
//    private func makeSafeTypes(from types: [String]) -> [String] {
//
//        let filtered = types.filter { allowedTypes.contains($0) }
//
//        return filtered.isEmpty ? ["script"] : filtered
//    }
//
//    private func escape(_ pattern: String) -> String {
//        NSRegularExpression.escapedPattern(for: pattern)
//    }
//
//    private func isSafePattern(_ pattern: String) -> Bool {
//
//        let lower = pattern.lowercased()
//
//        if lower.count < 6 {
//            return false
//        }
//
//        let protectedPatterns = [
//            "googlevideo.com",
//            "youtube.com",
//            "ytimg.com",
//            "yt3.ggpht.com",
//            "ttvnw.net",
//            "usher.ttvnw",
//            "twitch.tv",
//            "jtvnw.net",
//            "live-video.net",
//            "vimeo.com",
//            "vimeocdn.com",
//            "dailymotion.com",
//            "akamai",
//            "cloudfront",
//            "fastly",
//            "fbcdn.net"
//        ]
//
//        if protectedPatterns.contains(where: { lower.contains($0) }) {
//            return false
//        }
//
//        return true
//    }
//}
