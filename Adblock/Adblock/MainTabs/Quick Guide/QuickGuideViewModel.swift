//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
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
        // Открываем настройки Safari, а не приложения
        if let url = URL(string: "App-Prefs:Safari") {
            UIApplication.shared.open(url)
        }
    }
}
