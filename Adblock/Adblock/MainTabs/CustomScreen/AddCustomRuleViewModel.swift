//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import SwiftUI
import Combine

enum FiltersDates: String {
    case lastDay = "Last 24h "
    case lastWeek = "Last week"
    case lastMonth = "Last month"
    
    var localized: String {
        return self.rawValue.localized
    }
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
    // Domain Activity (всегда показываем — для create маркетинговая модель)
    @Published var isEmptyData: Bool = false
    @Published var rangeOfDates: FiltersDates = .lastDay
    @Published var chartData: [DomainActivityPoint] = []
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
        }
        loadActivitiesForChart()
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
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        rangeOfDates = range
        loadActivitiesForChart()
    }

    private var activityRange: DomainActivityRange {
        switch rangeOfDates {
        case .lastDay: return .last24h
        case .lastWeek: return .lastWeek
        case .lastMonth: return .lastMonth
        }
    }

    private func loadActivitiesForChart() {
        if let ruleId = editingRule?.id {
            let all = domainActivityStore.getOrCreateActivities(for: ruleId, createdAt: editingRule?.createdAt)
            let aggregated = aggregateActivities(all, by: rangeOfDates)
            chartData = aggregated
            isEmptyData = aggregated.allSatisfy { $0.count == 0 }
        } else {
            let marketing = domainActivityStore.generateMarketingActivities(
                blockTrackers: blockTrackers,
                antiAdblock: antiAdblockKiller,
                hideElements: hideElements,
                range: activityRange
            )
            chartData = marketing
            isEmptyData = marketing.allSatisfy { $0.count == 0 }
        }
    }

    /// Агрегирует сырые точки в 7 buckets для любого режима.
    private func aggregateActivities(_ points: [DomainActivityPoint], by range: FiltersDates) -> [DomainActivityPoint] {
        let calendar = Calendar.current
        let now = Date()
        let bucketCount = 7

        switch range {
        case .lastDay:
            var result: [DomainActivityPoint] = []
            let hoursPerBucket = 24 / bucketCount
            for i in 0..<bucketCount {
                let hourStart = -24 + i * hoursPerBucket
                guard let bucketStart = calendar.date(byAdding: .hour, value: hourStart, to: now),
                      let start = calendar.date(bySetting: .minute, value: 0, of: bucketStart) else { continue }
                let end = calendar.date(byAdding: .hour, value: hoursPerBucket, to: start) ?? start
                let sum = points.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.count }
                result.append(DomainActivityPoint(date: start, count: sum))
            }
            return result

        case .lastWeek:
            var result: [DomainActivityPoint] = []
            for dayOffset in (0..<7).reversed() {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                let start = calendar.startOfDay(for: date)
                let sum = points.filter { calendar.isDate($0.date, inSameDayAs: start) }.reduce(0) { $0 + $1.count }
                result.append(DomainActivityPoint(date: start, count: sum))
            }
            return result

        case .lastMonth:
            var result: [DomainActivityPoint] = []
            let daysPerBucket = 30 / bucketCount
            for i in 0..<bucketCount {
                let dayStart = -30 + i * daysPerBucket
                guard let bucketStart = calendar.date(byAdding: .day, value: dayStart, to: now) else { continue }
                let start = calendar.startOfDay(for: bucketStart)
                let end = calendar.date(byAdding: .day, value: daysPerBucket, to: start) ?? start
                let sum = points.filter { $0.date >= start && $0.date < end }.reduce(0) { $0 + $1.count }
                result.append(DomainActivityPoint(date: start, count: sum))
            }
            return result
        }
    }
}
