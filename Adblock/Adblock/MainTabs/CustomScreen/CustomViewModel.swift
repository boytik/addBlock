
import SwiftUI
import Combine

class CstomViewModel: ObservableObject {
    private let coordinator: CoordinatorProtocol
    
    @Published var searchText: String = ""
    @Published var blockAllDomains: Bool = false
    
    init(coordinator: CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    
    func openAddCustomRule() {
        coordinator.addCustomRule()
    }
}
