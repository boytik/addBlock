//
//  AddNewUrlViewModel.swift
//  Adblock
//
//  Created by Евгений on 09.02.2026.
//

import Foundation
import Combine

class AddWebSiteViewModel: ObservableObject {
    var coordinator: AppCoordinator
    var whiteListStore: WhiteListStore
//    private var cacellables = Set<AnyCancellable>()
    
    @Published var titel: String?
    @Published var url: String
    
    init(coordinator:AppCoordinator, whitelist: WhiteListStore) {
        self.coordinator = coordinator
        self.whiteListStore = whitelist
    }
    
    func addNewUrl(titel: String?, web: String) {
        whiteListStore.add(url: web, name: titel)
    }
}
