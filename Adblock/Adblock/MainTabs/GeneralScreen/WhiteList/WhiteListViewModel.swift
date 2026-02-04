//
//  WhiteListViewModel.swift
//  Adblock
//
//  Created by Евгений on 04.02.2026.
//

import SwiftUI
import Combine

class WhiteListViewModel: ObservableObject {
    private let coordinator: CoordinatorProtocol
    
    init(coordinator: CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    
    func closeWhiteList() {
        coordinator.closeWhiteList()
    }
}
