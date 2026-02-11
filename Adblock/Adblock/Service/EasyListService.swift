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
    
    func buildBlockingTules(completion: @escaping([BlockingRule]) -> Void) {
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
}
