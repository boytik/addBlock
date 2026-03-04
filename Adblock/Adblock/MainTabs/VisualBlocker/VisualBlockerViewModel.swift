//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//

import SwiftUI
import Combine

class VisualBlockerViewModel: ObservableObject {
    private let coordinator: CoordinatorProtocol
    
    init(coordinator: CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    
    func close() {
        coordinator.closeVisualBlocker()
    }
    
    func openSafariTutorial() {
        // TODO: открыть Safari Tutorial URL
        if let url = URL(string: "https://support.apple.com/guide/iphone/add-a-web-app-to-the-home-screen-iph42df402e6/ios") {
            UIApplication.shared.open(url)
        }
    }
}
