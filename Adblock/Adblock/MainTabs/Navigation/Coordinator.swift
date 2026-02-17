
import SwiftUI
import Combine

enum AppFlow {
    case onboarding
    case main
}

final class AppCoordinator: ObservableObject, CoordinatorProtocol {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnbording: Bool = false
    @Published var flow: AppFlow = .onboarding
    @Published var route: Route?
    @Published var sheet: Sheet?
    
    private let customRulesStore = CustomRulesStore()
    private lazy var ruleService = RulesService(customRulesStore: customRulesStore)
    private let whiteList = WhiteListStore()
    var whiteListStore: WhiteListStore {
        whiteList
    }
    init(){
        flow = hasSeenOnbording ? .main : .onboarding
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
            CustomView(viewModel: CstomViewModel(
                coordinator: self,
                customRulesStore: customRulesStore,
                ruleService: ruleService,
                configProvider: { [weak self] in
                    guard let self else {
                        return ContentBlockerConfig(isEnabled: false, blockAds: false,
                            blockTrackers: false, antiAdblock: false, whiteListedDomains: [])
                    }
                    let defaults = UserDefaults(suiteName: "group.test.com.adblock")
                    return ContentBlockerConfig(
                        isEnabled: defaults?.bool(forKey: "isWorking") ?? false,
                        blockAds: defaults?.bool(forKey: "blockAds") ?? false,
                        blockTrackers: defaults?.bool(forKey: "blockTrackers") ?? false,
                        antiAdblock: defaults?.bool(forKey: "antiAdblock") ?? false,
                        whiteListedDomains: self.whiteList.domains
                    )
                }
            ))
        case .addCustom:
            AddCustomRule(viewModel: AddCustomRuleViewModel(
                coordinator: self,
                customRulesStore: customRulesStore,
                ruleService: ruleService,
                configProvider: { [weak self] in
                    guard let self else {
                        return ContentBlockerConfig(isEnabled: false, blockAds: false,
                            blockTrackers: false, antiAdblock: false, whiteListedDomains: [])
                    }
                    return ContentBlockerConfig(
                        isEnabled: UserDefaults(suiteName: "group.test.com.adblock")?.bool(forKey: "isWorking") ?? false,
                        blockAds: UserDefaults(suiteName: "group.test.com.adblock")?.bool(forKey: "blockAds") ?? false,
                        blockTrackers: UserDefaults(suiteName: "group.test.com.adblock")?.bool(forKey: "blockTrackers") ?? false,
                        antiAdblock: UserDefaults(suiteName: "group.test.com.adblock")?.bool(forKey: "antiAdblock") ?? false,
                        whiteListedDomains: self.whiteList.domains
                    )
                }
            ))
        case .whiteList:
            WhiteListView(viewModel: WhiteListViewModel(coordinator: self,
                                                        whiteListStore: whiteList))
        case .quickGuide:
            QuickGuideView(viewModel: QuickGuideViewModel(coordinator: self))
        }
    }
    
    func finishOnbording() {
        hasSeenOnbording = true
        flow = .main
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
    
    func openQuickGuide() {
        route = .quickGuide
    }

    func closeQuickGuide() {
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
    //Sheets
    func presentAddWebsite()
    func dismissSheet()
    
    func openQuickGuide()
    func closeQuickGuide()
    
    
}

//MARK: Screens
enum Route: Identifiable {
    var id: String { String(describing: self) }
    case general
    case settings
    case custom
    case addCustom
    case whiteList
    case quickGuide  // ← add this
}

//MARK: Sheets
enum Sheet: Identifiable {
    case addWebsite
    case quickGuide
    var id: String {
        switch self {
        case .addWebsite:
            return "addWebSite"
        case .quickGuide:
            return "quickGuide"
        }
    }
}
