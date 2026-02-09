import SwiftUI
import Combine

class WhiteListViewModel: ObservableObject {
    private let coordinator: CoordinatorProtocol
    private let whiteListStore: WhiteListStore
//
    init(coordinator: CoordinatorProtocol, whiteListStore: WhiteListStore) {
        self.coordinator = coordinator
        self.whiteListStore = whiteListStore
    }
    
    func closeWhiteList() {
        coordinator.closeWhiteList()
    }
}
