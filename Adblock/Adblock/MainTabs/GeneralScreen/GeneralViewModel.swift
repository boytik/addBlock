
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
    
    @Published private(set) var isUpdatingRules: Bool = false
    
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
        loadState()
        bindStatePersistance()
        bindConfigChanges()
        
        let config = makeConfig()
        ruleService.validateOnLaunch(config: config)
        
        ruleServise.$isUpdating
            .receive(on: DispatchQueue.main)
            .assign(to: &$isUpdatingRules)
        loadBlockedCount()
    }
    //Создаем конфиг
    func makeConfig() -> ContentBlockerConfig {
        ContentBlockerConfig(isEnabled: isWorking,
                             blockAds: isBlockAds,
                             blockTrackers: isBlockTrackers,
                             antiAdblock: isAntiAdblokKiller,
                             whiteListedDomains: whiteList.domains)
    }
    
    //Подсчет блокировки
    func loadBlockedCount() {
        let defaults = UserDefaults(suiteName: "group.test.com.adblock")
        adsBlockedCount = defaults?.integer(forKey: "blockedAdsCount") ?? 0
        trackersBlokedCount = defaults?.integer(forKey: "blockedTrackersCount") ?? 0
    }
    
    func toggleProtection() {
        let newValue = !isWorking

        Task {
            let result = await ruleServise.updateRules(
                config: makeConfig(with: newValue)
            )

            if result.success {
                self.isWorking = newValue
            }
        }
    }
    
    func makeConfig(with isEnabled: Bool) -> ContentBlockerConfig {
        ContentBlockerConfig(
            isEnabled: isEnabled,
            blockAds: isBlockAds,
            blockTrackers: isBlockTrackers,
            antiAdblock: isAntiAdblokKiller,
            whiteListedDomains: whiteList.domains
        )
    }
    
    private func bindConfigChanges() {
        Publishers.CombineLatest3(
            $isBlockAds,
            $isBlockTrackers,
            whiteList.$whiteList
        )
        .dropFirst()
        .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
        .sink { [weak self] _, _, _ in
            self?.updateRules()
        }
        .store(in: &cancellables)
    }
    
    private func loadState() {
        let defaults = UserDefaults(suiteName: "group.test.com.adblock")
        
        isWorking = defaults?.bool(forKey: Keys.isWorking) ?? false
        isBlockAds = defaults?.bool(forKey: Keys.blockAds) ?? false
        isBlockTrackers = defaults?.bool(forKey: Keys.blockTrackers) ?? false
        isAntiAdblokKiller = defaults?.bool(forKey: Keys.antiAdblock) ?? false
        
    }
    
    private func bindStatePersistance() {
        let defaults = UserDefaults(suiteName: "group.test.com.adblock")
        
        $isWorking
            .sink { defaults?.set($0, forKey: Keys.isWorking) }
            .store(in: &cancellables)
        $isBlockAds
            .sink { defaults?.set($0, forKey: Keys.blockAds) }
            .store(in: &cancellables)
        $isBlockTrackers
            .sink { defaults?.set($0, forKey: Keys.blockTrackers) }
            .store(in: &cancellables)
        $isAntiAdblokKiller
            .sink { defaults?.set($0, forKey: Keys.antiAdblock) }
            .store(in: &cancellables)
    }
    
    
    ///Обновляем правила
    func updateRules() {
        let config = makeConfig()

        Task {
             await ruleServise.updateRules(config: config)
        }
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
