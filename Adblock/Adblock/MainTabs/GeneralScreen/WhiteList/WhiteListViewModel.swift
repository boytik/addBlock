import SwiftUI
import Combine

class WhiteListViewModel: ObservableObject {
    private let coordinator: CoordinatorProtocol
    private let whiteListStore: WhiteListStore
    private var cacellables = Set<AnyCancellable>()
    
    @Published private(set) var items:[WhiteListItem] = []
    
    init(coordinator: CoordinatorProtocol, whiteListStore: WhiteListStore) {
        self.coordinator = coordinator
        self.whiteListStore = whiteListStore
        bindStore()
    }
    
    func deleteUrl(id: UUID) {
        whiteListStore.remove(id: id)
    }
    
    func closeWhiteList() {
        coordinator.closeWhiteList()
    }
}

private extension WhiteListViewModel {
    func bindStore() {
        whiteListStore.$whiteList
            .sink { [weak self] newItems in
                self?.items = newItems
            }
            .store(in: &cacellables)
    }
}
