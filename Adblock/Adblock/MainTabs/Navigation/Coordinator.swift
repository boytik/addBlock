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
    @Published var sheet: Sheet?
    
    private let ruleService = RulesService()
    private let whiteList = WhiteListStore()
    var whiteListStore: WhiteListStore {
          whiteList
      }
    
    @ViewBuilder
    func build(route: Route) -> some View {
        switch route {
        case .settings:
            SettingsView(viewModel: SettingsViewModal(coordinator: self))
        case .general:
            GeneralView(viewModel: GeneralViewModel(coordinator: self,
                                                    ruleService: ruleService,
                                                    whiteListStore: whiteListStore))
        case .custom:
                CustomView(viewModel: CstomViewModel(coordinator: self))
        case .addCustom:
            AddCustomRule(viewModel: AddCustomRuleViewModel(coordinator: self))
        case .whiteList:
            WhiteListView(viewModel: WhiteListViewModel(coordinator: self,
                                                        whiteListStore: whiteList))
        }
    }
    
    //MARK: NAVIGATION
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
    //WhiteList
    func openWhiteList() {
        route = .whiteList
    }
    
    func closeWhiteList() {
        route = nil
    }
    
    //MARK: SHEETS
    func presentAddWebsite() {
        sheet = .addWebsite
    }
    
    func dismissSheet() {
        sheet = nil
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
    //Sheets
    func presentAddWebsite()
    func dismissSheet()
    
    
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
//MARK: Sheets
enum Sheet: Identifiable {
    case addWebsite
    var id: String {
        switch self {
        case .addWebsite:
            return "addWebSite"
        }
    }
}
