
import SwiftUI
import Combine
import SafariServices


class GeneralViewModel: ObservableObject {
    
    private static let blockerID = "test.com.adblock.blocker"
   
    //MARK: Properties
    private let coordinator: CoordinatorProtocol
    
    @Published var selectedRange: TimeRange = .today
    @Published var isWorking: Bool = false
    /// Content Blocker (AdblockSafariExtension) включён в настройках Safari
    @Published var isExtensionEnabled: Bool = false
    //Info About Work
    @Published var adsBlockedCount: Int = 0
    @Published var trackersBlokedCount: Int = 0
    //Protection Rules — изначально все включены
    @Published var isBlockAds: Bool = true
    @Published var isBlockTrackers: Bool = true
    @Published var isAntiAdblokKiller: Bool = true
    
    @Published private(set) var isUpdatingRules: Bool = false
    
    //Services
    private let ruleServise: RulesService
    private let whiteList: WhiteListStore
    private let blockedStatsStore = BlockedStatsStore()
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
        bindBlockedCountToRange()
        loadBlockedCount()
        loadExtensionState()
    }
    
    /// Загружает фактическое состояние Content Blocker в настройках Safari
    func loadExtensionState() {
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Self.blockerID) { [weak self] state, _ in
            DispatchQueue.main.async {
                self?.isExtensionEnabled = state?.isEnabled ?? false
            }
        }
    }
    
    /// Content Blocker включён в настройках Safari
    var areExtensionsEnabled: Bool {
        isExtensionEnabled
    }
    //Создаем конфиг
    func makeConfig() -> ContentBlockerConfig {
        ContentBlockerConfig(isEnabled: isWorking,
                             blockAds: isBlockAds,
                             blockTrackers: isBlockTrackers,
                             antiAdblock: isAntiAdblokKiller,
                             whiteListedDomains: whiteList.domains)
    }
    
    //Подсчет блокировки с учётом выбранного диапазона (Today / Week / All Time)
    func loadBlockedCount() {
        let stats = blockedStatsStore.loadStats(range: selectedRange)
        adsBlockedCount = stats.ads
        trackersBlokedCount = stats.trackers
    }
    
    private func bindBlockedCountToRange() {
        $selectedRange
            .dropFirst()
            .sink { [weak self] _ in
                self?.loadBlockedCount()
            }
            .store(in: &cancellables)
    }
    
    func didTapMainButton() {
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Self.blockerID) { [weak self] blockerState, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                let blockerOn = blockerState?.isEnabled ?? false
                self.isExtensionEnabled = blockerOn
                if blockerOn {
                    self.toggleProtection()
                } else {
                    self.coordinator.openQuickGuide()
                }
            }
        }
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
        
        // При первом входе — главная кнопка выключена, остальные тоглы включены
        isWorking = defaults?.bool(forKey: Keys.isWorking) ?? false
        isBlockAds = defaults?.object(forKey: Keys.blockAds) as? Bool ?? true
        isBlockTrackers = defaults?.object(forKey: Keys.blockTrackers) as? Bool ?? true
        isAntiAdblokKiller = defaults?.object(forKey: Keys.antiAdblock) as? Bool ?? true
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
    
    func didTapQuickGuide() {
        coordinator.openQuickGuide()
    }
}

enum TimeRange: CaseIterable {
    case today
    case week
    case allTime
    
    var titel: String {
        switch self {
        case .today: return "Today".localized
        case .week: return "Week".localized
        case .allTime: return "All Time".localized
        }
    }
}
