//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import Foundation
import Combine

class AddWebSiteViewModel: ObservableObject {
    var coordinator: AppCoordinator
    var whiteListStore: WhiteListStore
    
    @Published var titel: String = ""
    @Published var url: String = ""
    @Published var showDuplicateError: Bool = false
    
    init(coordinator: AppCoordinator, whitelist: WhiteListStore) {
        self.coordinator = coordinator
        self.whiteListStore = whitelist
    }
    
    func addNewUrl() {
        let normolTitel = titel.isEmpty ? nil : titel
        let success = whiteListStore.add(url: url, name: normolTitel)
        
        if success {
            showDuplicateError = false
            coordinator.dismissSheet()
        } else {
            showDuplicateError = true
        }
    }
    
    func clearError() {
        if showDuplicateError {
            showDuplicateError = false
        }
    }
    
    func closeSheet() {
        coordinator.dismissSheet()
    }
}
