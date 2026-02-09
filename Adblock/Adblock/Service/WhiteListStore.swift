

import Foundation
import Combine

final class WhiteListStore: ObservableObject {
    @Published var whiteList: [WhiteListItem] = []
    var domains: [String] { whiteList.map { $0.url } }
    private var starageKey: String = "whiteList_items"
    
    init() {
        reStore()
    }
    
    ///Добавляем элемент в список
    func add(url: String, name: String?) {
        guard !whiteList.contains(where: { $0.url == url }) else { return }
        whiteList.append(WhiteListItem(name: name, url: url))
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
            let defaults = UserDefaults(suiteName: "group.com.boytik.adblock") //поменять потом бандл
        else { return }
        defaults.set(data, forKey: starageKey)
    }
    
    ///Получаем сохраненные данные
    private func reStore() {
        guard
            let defaults = UserDefaults(suiteName: "group.com.boytik.adblock"), // поменять бандл
            let data = defaults.data(forKey: starageKey),
                let items = try? JSONDecoder().decode([WhiteListItem].self, from: data )
        else { return }
        
        self.whiteList = items
    }
    
}
