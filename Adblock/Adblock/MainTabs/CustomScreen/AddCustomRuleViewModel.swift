//
//  AddCustomRuleViewModel.swift
//  Adblock
//
//  Created by Евгений on 01.02.2026.
//

import SwiftUI
import Combine

class AddCustomRuleViewModel: ObservableObject {
    private let coordinator: CoordinatorProtocol
    
    @Published var tagetWeb: String = ""
    //Blocking Options
    @Published var blockAds: Bool = false
    @Published var blockTrackers: Bool = false
    @Published var antiAdblockKiller: Bool = false
    @Published var hideElements: Bool = false
    
    init(coordinator: CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    
    func closeScreen() {
        coordinator.closeCustomRule()
    }
}
