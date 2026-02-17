
import UIKit
import Foundation
import Combine
class QuickGuideViewModel: ObservableObject {
    private let coordinator: CoordinatorProtocol
    
    init(coordinator: CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    
    func closeSheet() {
        coordinator.closeQuickGuide()
    }
    
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
