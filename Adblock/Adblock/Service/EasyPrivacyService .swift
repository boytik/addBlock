//import Foundation
//
//final class EasyPrivacyService {
//    private let parser = EasyListParser()
//    private let converter = EasyListConverter()
//    private let url = URL(string: "https://easylist.to/easylist/easyprivacy.txt")!
//    
//    func buildBlockingRules() async -> [BlockingRule] {
//        
//        guard let text = await downloadEasyPrivacy() else {
//            return []
//        }
//        
//        let parsed = parser.parse(from: text)
//        return converter.convert(rules: parsed)
//    }
//    
//    private func downloadEasyPrivacy() async -> String? {
//        do {
//            let (data, _) = try await URLSession.shared.data(from: url)
//            return String(data: data, encoding: .utf8)
//        } catch {
//            print("❌ EasyPrivacy download error:", error)
//            return nil
//        }
//    }
//}
