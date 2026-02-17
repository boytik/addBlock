import SwiftUI
import Combine

enum FiltersDates: String {
    case lastDay = "Last 24h "
    case lastWeek = "Last week"
    case lastMonth = "Last month"
}

class AddCustomRuleViewModel: ObservableObject {
    private let coordinator: CoordinatorProtocol
    private let customRulesStore: CustomRulesStore
    private let ruleService: RulesService
    private let configProvider: () -> ContentBlockerConfig
    private let onDismiss: () -> Void

    @Published var tagetWeb: String = ""
    // Blocking Options
    @Published var blockAds: Bool = false
    @Published var blockTrackers: Bool = false
    @Published var antiAdblockKiller: Bool = false
    @Published var hideElements: Bool = false
    // Domain Activity
    @Published var isEmptyData: Bool = true
    @Published var rangeOfDates: FiltersDates = .lastDay
    // Validation
    @Published var showDuplicateError: Bool = false
    @Published var isSaving: Bool = false

    init(coordinator: CoordinatorProtocol,
         customRulesStore: CustomRulesStore,
         ruleService: RulesService,
         configProvider: @escaping () -> ContentBlockerConfig,
         onDismiss: @escaping () -> Void) {
        self.coordinator = coordinator
        self.customRulesStore = customRulesStore
        self.ruleService = ruleService
        self.configProvider = configProvider
        self.onDismiss = onDismiss
    }

    func saveRule() {
        let domain = tagetWeb.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !domain.isEmpty else { return }

        // Проверка дубликата
        if customRulesStore.contains(domain: domain) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showDuplicateError = true
            }
            return
        }

        let rule = CustomRule(
            domain: domain,
            blockAds: blockAds,
            blockTrackers: blockTrackers,
            antiAdblock: antiAdblockKiller,
            hideElements: hideElements
        )

        let added = customRulesStore.add(rule: rule)
        guard added else {
            showDuplicateError = true
            return
        }

        // Обновляем Safari правила
        isSaving = true
        Task {
            await ruleService.updateRules(config: configProvider())
            isSaving = false
            onDismiss()
        }
    }

    func clearError() {
        if showDuplicateError {
            showDuplicateError = false
        }
    }

    func closeScreen() {
        onDismiss()
    }

    func selectDateRange(_ range: FiltersDates) {
        rangeOfDates = range
    }
}
