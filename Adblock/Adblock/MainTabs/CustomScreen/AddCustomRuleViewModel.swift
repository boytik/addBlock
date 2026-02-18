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
    private let domainActivityStore: DomainActivityStore
    private let configProvider: () -> ContentBlockerConfig
    private let onDismiss: () -> Void
    private let editingRule: CustomRule?

    @Published var tagetWeb: String = ""
    // Blocking Options
    @Published var blockAds: Bool = false
    @Published var blockTrackers: Bool = false
    @Published var antiAdblockKiller: Bool = false
    @Published var hideElements: Bool = false
    
    var isEditMode: Bool { editingRule != nil }
    // Domain Activity (только в режиме редактирования)
    @Published var isEmptyData: Bool = true
    @Published var rangeOfDates: FiltersDates = .lastDay
    @Published var chartData: [Int] = [] // значения для графика (бары)
    // Validation
    @Published var showDuplicateError: Bool = false
    @Published var isSaving: Bool = false

    init(coordinator: CoordinatorProtocol,
         customRulesStore: CustomRulesStore,
         ruleService: RulesService,
         domainActivityStore: DomainActivityStore,
         configProvider: @escaping () -> ContentBlockerConfig,
         onDismiss: @escaping () -> Void,
         editingRule: CustomRule? = nil) {
        self.coordinator = coordinator
        self.customRulesStore = customRulesStore
        self.ruleService = ruleService
        self.domainActivityStore = domainActivityStore
        self.configProvider = configProvider
        self.onDismiss = onDismiss
        self.editingRule = editingRule
        
        if let rule = editingRule {
            tagetWeb = rule.domain
            blockAds = rule.blockAds
            blockTrackers = rule.blockTrackers
            antiAdblockKiller = rule.antiAdblock
            hideElements = rule.hideElements
            loadActivitiesForChart()
        } else {
            isEmptyData = true
        }
    }

    func saveRule() {
        let domain = tagetWeb.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !domain.isEmpty else { return }

        let ruleId = editingRule?.id
        if customRulesStore.contains(domain: domain, excludingId: ruleId) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showDuplicateError = true
            }
            return
        }

        if let existing = editingRule {
            let updated = CustomRule(
                id: existing.id,
                domain: domain,
                blockAds: blockAds,
                blockTrackers: blockTrackers,
                antiAdblock: antiAdblockKiller,
                hideElements: hideElements,
                isEnabled: existing.isEnabled
            )
            customRulesStore.update(withId: existing.id, rule: updated)
        } else {
            let rule = CustomRule(
                domain: domain,
                blockAds: blockAds,
                blockTrackers: blockTrackers,
                antiAdblock: antiAdblockKiller,
                hideElements: hideElements
            )
            guard customRulesStore.add(rule: rule) else {
                showDuplicateError = true
                return
            }
        }

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
        loadActivitiesForChart()
    }
    
    private func loadActivitiesForChart() {
        guard let ruleId = editingRule?.id else {
            chartData = []
            isEmptyData = true
            return
        }
        let all = domainActivityStore.getOrCreateActivities(for: ruleId, createdAt: editingRule?.createdAt)
        let filtered = filterActivities(all, by: rangeOfDates)
        chartData = filtered
        isEmptyData = filtered.isEmpty
    }
    
    /// Фильтрует активности по выбранному диапазону и возвращает массив значений для баров.
    private func filterActivities(_ points: [DomainActivityPoint], by range: FiltersDates) -> [Int] {
        let calendar = Calendar.current
        let now = Date()
        let sorted = points.sorted { $0.date < $1.date }
        
        switch range {
        case .lastDay:
            // 8 баров за последние 24ч — делим «сегодня» на 8 частей
            guard let todayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now) else { return [] }
            let todayPoints = sorted.filter { $0.date >= todayStart }
            let todayTotal = todayPoints.reduce(0) { $0 + $1.count }
            if todayTotal == 0 {
                return (0..<8).map { _ in Int.random(in: 2...25) }
            }
            return splitIntoBars(total: todayTotal, count: 8)
            
        case .lastWeek:
            // 7 баров — последние 7 дней
            var result: [Int] = []
            for dayOffset in (0..<7).reversed() {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                let start = calendar.startOfDay(for: date)
                let dayPoints = sorted.filter { calendar.isDate($0.date, inSameDayAs: start) }
                result.append(dayPoints.reduce(0) { $0 + $1.count })
            }
            return result
            
        case .lastMonth:
            // 4 бара — 4 недели
            var result: [Int] = []
            for weekOffset in (0..<4).reversed() {
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
                let weekPoints = sorted.filter { $0.date >= weekStart && $0.date < weekEnd }
                result.append(weekPoints.reduce(0) { $0 + $1.count })
            }
            return result
        }
    }
    
    /// Делит total на count баров со случайным распределением (сумма = total).
    private func splitIntoBars(total: Int, count: Int) -> [Int] {
        guard count > 0, total >= 0 else { return [] }
        if total == 0 { return Array(repeating: 0, count: count) }
        let weights = (0..<count).map { _ in Double.random(in: 0.5...2.0) }
        let sumW = weights.reduce(0, +)
        var bars = weights.map { max(0, Int(Double(total) * $0 / sumW)) }
        let diff = total - bars.reduce(0, +)
        if diff != 0, let idx = bars.firstIndex(where: { $0 + diff >= 0 }) {
            bars[idx] += diff
        }
        return bars
    }
}
