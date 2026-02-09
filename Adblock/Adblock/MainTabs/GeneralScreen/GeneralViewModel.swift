
import SwiftUI
import Combine


class GeneralViewModel: ObservableObject {
    
   
    //MARK: Properties
    private let coordinator: CoordinatorProtocol
    
    @Published var selectedRange: TimeRange = .today
    @Published var isWorking: Bool = false
    //Info About Work
    @Published var adsBlockedCount: Int = 0
    @Published var trackersBlokedCount: Int = 0
    //Protection Rules
    @Published var isBlockAds: Bool = false
    @Published var isBlockTrackers: Bool = false
    @Published var isAntiAdblokKiller: Bool = false
    var whiteList:[String] = []
    
    private let ruleServise: RulesService
    
    init(coordinator: CoordinatorProtocol,
         ruleService: RulesService) {
        self.coordinator = coordinator
        self.ruleServise = ruleService
    }
    //Создаем конфиг
    func makeConfig() -> ContentBlockerConfig {
        ContentBlockerConfig(isEnabled: isWorking,
                             blockAds: isBlockAds,
                             blockTrackers: isBlockTrackers,
                             whiteListedDomains: whiteList)
    }
    //Обновляем правила
    func updateRules() {
        let config = makeConfig()
        ruleServise.updateRules(config: config)
    }
    
    //MARK: Navigation
    func didTapSettings() {
        coordinator.openSettings()
    }
    
    func openWhiteList(){
        coordinator.openWhiteList()
    }
}

enum TimeRange: CaseIterable {
    case today
    case week
    case allTime
    
    var titel: String {
        switch self {
        case .today: return "Today"
        case .week: return "Week"
        case .allTime: return "All Time"
        }
    }
}
