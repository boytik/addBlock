

import Foundation
import Combine

class AddWebSiteViewModel: ObservableObject {
    var coordinator: AppCoordinator
    var whiteListStore: WhiteListStore
    
    @Published var titel: String = ""
    @Published var url: String = ""
    
    init(coordinator:AppCoordinator, whitelist: WhiteListStore) {
        self.coordinator = coordinator
        self.whiteListStore = whitelist
    }
    
    func addNewUrl() {
        let normolTitel = titel.isEmpty ? nil : titel
        whiteListStore.add(url: url, name: normolTitel)
    }
}
