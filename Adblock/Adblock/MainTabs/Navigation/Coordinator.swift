//
//  Coordinator.swift
//  Adblock
//
//  Created by Евгений on 02.02.2026.
//

import SwiftUI
import Combine

final class AppCoordinator: ObservableObject, CoordinatorProtocol {
    @Published var route: Route?
    
    @ViewBuilder
    func build(route: Route) -> some View {
        switch route {
        case .settings:
            SettingsView(viewModel: SettingsViewModal(coordinator: self))
        case .general:
            GeneralView(viewModel: GeneralViewModel(coordinator: self))
        case .custom:
                CustomView(viewModel: CstomViewModel(coordinator: self))
        case .addCustom:
            AddCustomRule(viewModel: AddCustomRuleViewModel(coordinator: self))
        case .whiteList:
            WhiteListView(viewModel: WhiteListViewModel(coordinator: self))
        }
    }
    
    //Settings
    
    func openSettings() {
        route = .settings
    }
    
    func closeSettings() {
        route = nil
    }
    
    //Custom Rule
    func addCustomRule() {
        route = .addCustom
    }
    
    func closeCustomRule() {
        route = nil
    }
    
    func openWhiteList() {
        route = .whiteList
    }
    
    func closeWhiteList() {
        route = nil
    }
}
//MARK: Contract
protocol CoordinatorProtocol: AnyObject {
    //Settings
    func openSettings()
    func closeSettings()
    //CustomRules
    func addCustomRule()
    func closeCustomRule()
    //White List
    func openWhiteList()
    func closeWhiteList()
    
    
}

//MARK: Screens
enum Route: Identifiable {
    
    var id: String {
        String(describing: self)
    }
    case general
    case settings
    case custom
    case addCustom
    case whiteList
}
