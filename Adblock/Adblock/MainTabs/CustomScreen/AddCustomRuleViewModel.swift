

import SwiftUI
import Combine

enum FiltersDates: String {
    case lastDay = "Last 24h "
    case lastWeek = "Last week"
    case lastMonth = "Last month"
}

class AddCustomRuleViewModel: ObservableObject {
    private let coordinator: CoordinatorProtocol
    
    @Published var tagetWeb: String = ""
    //Blocking Options
    @Published var blockAds: Bool = false
    @Published var blockTrackers: Bool = false
    @Published var antiAdblockKiller: Bool = false
    @Published var hideElements: Bool = false
    //Domain Activity
    @Published var isEmptyData:Bool = true
    @Published var showMenu = false
    @Published var rangeOfDates: FiltersDates = .lastDay
    
    init(coordinator: CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    
    func closeScreen() {
        coordinator.closeCustomRule()
    }
    
    func opneAndCloseMenu(range: FiltersDates) {
        self.showMenu.toggle()
        self.rangeOfDates = range
    }
}
