//
//  EasyListService.swift
//  Adblock
//
//  Created by Евгений on 11.02.2026.
//

import Foundation

final class EasyListService {
    private let parser = EasyListParser()
    private let converter = EasyListConverter()
    private let url = URL(string: "https://easylist.to/easylist/easylist.txt")!
    private let appGroupID = "group.test.com.adblock"
    private let fileName = "easylist.txt"
    
    func downloadEasyList(completion: @escaping (String?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data,
                    error == nil,
                  let text = String(data: data, encoding: .utf8)
            else {
                completion(nil)
                return
            }
            completion(text)
        }.resume()
    }
    
    func buildBlockingRules(completion: @escaping([BlockingRule]) -> Void) {
        //Если кэш есть
        if let cached = loadCacheList() {
            let parsed = parser.parse(from: cached)
            let converted = converter.convert(rules: parsed)
            completion(converted)
            return
        }
        // Если кэша нет 
        downloadEasyList { [weak self] text in
            guard let self,
                  let text else {
                completion([])
                return
            }
            
            let parsed = self.parser.parse(from: text)
            let converted = self.converter.convert(rules: parsed)
            completion(converted)
        }
    }
    ///Путь к списку
    private func easyListFileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }
    
    ///Проверка наличия кэша
    private func loadCacheList() -> String? {
        guard
            let url = easyListFileURL(),
            FileManager.default.fileExists(atPath: url.path()),
            let data = try? Data(contentsOf: url),
            let text = String(data: data , encoding: .utf8)
        else {
            return nil
        }
        return text
    }
    
    private func saveToCache(text: String) {
        guard let url = easyListFileURL() else { return }
        try? text.data(using: .utf8)?.write(to: url)
    }
}
