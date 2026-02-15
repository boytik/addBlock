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
    
    /// Добавляем элемент в список. Возвращает true если добавлен, false если дубликат.
    @discardableResult
    func add(url: String, name: String?) -> Bool {
        let normolized = normolizeDomain(input: url)
        guard !normolized.isEmpty else { return false }
        guard !whiteList.contains(where: { $0.url == normolized }) else {
            return false
        }
        whiteList.append(WhiteListItem(name: name, url: normolized))
        persist()
        return true
    }
    
    /// Проверяет, есть ли домен уже в списке
    func contains(url: String) -> Bool {
        let normolized = normolizeDomain(input: url)
        return whiteList.contains(where: { $0.url == normolized })
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
            let defaults = UserDefaults(suiteName: "group.test.com.adblock")
        else { return }
        defaults.set(data, forKey: starageKey)
    }
    
    ///Получаем сохраненные данные
    private func reStore() {
        guard
            let defaults = UserDefaults(suiteName: "group.test.com.adblock"),
            let data = defaults.data(forKey: starageKey),
            let items = try? JSONDecoder().decode([WhiteListItem].self, from: data)
        else { return }
        
        self.whiteList = items
    }
}
