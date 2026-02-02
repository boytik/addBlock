

import SwiftUI
import Combine

class SettingsViewModal: ObservableObject {
    
    private let coordinator: CoordinatorProtocol
    
    init(coordinator: CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    
    func closeSettings() {
        coordinator.closeSettings()
    }
}
