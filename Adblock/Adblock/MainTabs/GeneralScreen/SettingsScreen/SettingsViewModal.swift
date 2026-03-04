//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import SwiftUI
import Combine
import StoreKit

class SettingsViewModal: ObservableObject {
    
    private let coordinator: CoordinatorProtocol
    
    init(coordinator: CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    
    func closeSettings() {
        coordinator.closeSettings()
    }
    
    func shareFeedback() {
        let email = "support@example.com"
        let subject = "App Feedback".localized
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    func rateApp() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    func contactUs() {
        if let url = URL(string: "https://example.com/contact") {
            UIApplication.shared.open(url)
        }
    }
    
    func openPrivacyPolicy() {
        if let url = URL(string: "https://example.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    func openTermsOfService() {
        if let url = URL(string: "https://example.com/terms") {
            UIApplication.shared.open(url)
        }
    }
}
