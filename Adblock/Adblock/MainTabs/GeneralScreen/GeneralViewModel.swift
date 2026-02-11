
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
    
    //Services
    private let ruleServise: RulesService
    private let whiteList: WhiteListStore
    private var cancellables = Set<AnyCancellable>()
    
    
    init(coordinator: CoordinatorProtocol,
         ruleService: RulesService,
         whiteListStore: WhiteListStore
    ) {
        self.coordinator = coordinator
        self.ruleServise = ruleService
        self.whiteList = whiteListStore
        bindWhiteList()
        bindToggles()
    }
    //Создаем конфиг
    func makeConfig() -> ContentBlockerConfig {
        ContentBlockerConfig(isEnabled: isWorking,
                             blockAds: isBlockAds,
                             blockTrackers: isBlockTrackers,
                             whiteListedDomains: whiteList.domains)
    }
    ///Привязка к изменению состояния и отправка его в сафари
    private func bindToggles() {
        Publishers.CombineLatest4 ($isWorking,
                                   $isBlockAds,
                                   $isBlockTrackers,
                                   $isAntiAdblokKiller)
        .dropFirst()
        .sink{ [weak self] _, _, _, _ in
            self?.updateRules()
        }
        .store(in: &cancellables)
    }
    ///Привязка к изменению списка и отправка его в сафари
    func bindWhiteList() {
        whiteList.$whiteList
            .dropFirst()
            .sink { [ weak self] _ in
                self?.updateRules()
            }
            .store(in: &cancellables)
    }
    
    ///Обновляем правила
    func updateRules() {
        guard isWorking else {
            ruleServise.updateRules(config: makeConfig())
            return
        }
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
