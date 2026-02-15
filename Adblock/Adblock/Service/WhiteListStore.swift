

import Foundation
import Combine

final class WhiteListStore: ObservableObject {
    @Published var whiteList: [WhiteListItem] = []
    var domains: [String] { whiteList.map { $0.url } }
    private var starageKey: String = "whiteList_items"
    
    init() {
        reStore()
    }
    
    private func normolizeDomain(input: String) -> String {
        var domain = input.lowercased()
        
        if domain.hasPrefix("http://")  {
            domain.removeFirst(7)
        }
        
        if domain.hasPrefix("https://") {
            domain.removeFirst(8)
        }
        
        if domain.hasPrefix("www.") {
            domain.removeFirst(4)
        }
        
        if let slashIndex = domain.firstIndex(of: "/") {
            domain = String(domain[..<slashIndex])
        }
        
        return domain
    }
    
    ///Добавляем элемент в список
    func add(url: String, name: String?) {
        let normolized = normolizeDomain(input: url)
        guard !whiteList.contains(where: { $0.url == normolized }) else {
            print("такой домен есть")
            return }
        whiteList.append(WhiteListItem(name: name, url: normolized))
        print("добавили")
        persist()
    }
    
    ///Удаляем элемент из списка
    func remove(id: UUID) {
        whiteList.removeAll {
            $0.id == id
        }
        persist()
    }
    
    ///Обновляем список
    private func persist() {
        guard
            let data = try? JSONEncoder().encode(whiteList),
            let defaults = UserDefaults(suiteName: "group.test.com.adblock") //поменять потом бандл
        else { return }
        defaults.set(data, forKey: starageKey)
    }
    
    ///Получаем сохраненные данные
    private func reStore() {
        guard
            let defaults = UserDefaults(suiteName: "group.test.com.adblock"), // поменять бандл
            let data = defaults.data(forKey: starageKey),
                let items = try? JSONDecoder().decode([WhiteListItem].self, from: data )
        else { return }
        
        self.whiteList = items
    }
    
}
