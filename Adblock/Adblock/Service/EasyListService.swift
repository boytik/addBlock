//
//import Foundation
//
//final class EasyListService {
//    private let parser = EasyListParser()
//    private let converter = EasyListConverter()
//    private let url = URL(string: "https://easylist.to/easylist/easylist.txt")!
//    private let appGroupID = "group.test.com.adblock"
//    private let fileName = "easylist.txt"
//    private let cacheLifetime: TimeInterval = 60*60*24
//    
//    func buildBlockingRules() async -> [BlockingRule] {
//        if isCacheValid(),
//           let cached = loadCacheList() {
//            let parsed = parser.parse(from: cached)
//            let converted = converter.convert(rules: parsed)
//            return converted
//        }
//        
//        guard let text = await downloadEasyList() else {
//            return []
//        }
//        
//        saveToCache(text: text)
//        
//        let parsed = parser.parse(from: text)
//        let converted = converter.convert(rules: parsed)
//        
//        return converted
//    }
//    
//    //Скачиваем список
//    private func downloadEasyList() async -> String? {
//        do {
//            let (data, _) = try await URLSession.shared.data(from: url)
//            return String(data: data, encoding: .utf8)
//        } catch {
//            print("Easy List error download")
//            return nil
//        }
//    }
//        
//    ///Путь к списку
//    private func easyListFileURL() -> URL? {
//        FileManager.default
//            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
//            .appendingPathComponent(fileName)
//    }
//    
//    ///Проверка наличия кэша
//    private func loadCacheList() -> String? {
//        guard
//            let url = easyListFileURL(),
//            FileManager.default.fileExists(atPath: url.path),
//            let data = try? Data(contentsOf: url),
//            let text = String(data: data , encoding: .utf8)
//        else {
//            return nil
//        }
//        return text
//    }
//    
//    //Сохраняем кэш
//    private func saveToCache(text: String) {
//        guard let url = easyListFileURL() else { return }
//        try? text.data(using: .utf8)?.write(to: url)
//    }
//    
//    //Проверка актуальности
//    private func isCacheValid() -> Bool {
//        guard
//                let url = easyListFileURL(),
//                FileManager.default.fileExists(atPath: url.path),
//                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
//                let modificationDate = attributes[.modificationDate] as? Date
//            else {
//                return false
//            }
//
//            let age = Date().timeIntervalSince(modificationDate)
//            return age < cacheLifetime
//    }
//}
