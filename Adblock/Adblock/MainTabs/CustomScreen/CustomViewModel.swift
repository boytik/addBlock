//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import SwiftUI
import Combine

class CstomViewModel: ObservableObject {
    private let coordinator: CoordinatorProtocol
    private let customRulesStore: CustomRulesStore
    private let ruleService: RulesService
    private let configProvider: () -> ContentBlockerConfig
    private var cancellables = Set<AnyCancellable>()

    @Published var searchText: String = ""
    @Published private(set) var activeRules: [CustomRule] = []
    @Published private(set) var inactiveRules: [CustomRule] = []
    @Published var showAddCustomRule: Bool = false
    @Published var editingRule: CustomRule? = nil

    init(coordinator: CoordinatorProtocol,
         customRulesStore: CustomRulesStore,
         ruleService: RulesService,
         configProvider: @escaping () -> ContentBlockerConfig) {
        self.coordinator = coordinator
        self.customRulesStore = customRulesStore
        self.ruleService = ruleService
        self.configProvider = configProvider
        bindStore()
    }

    // MARK: - Binding

    private func bindStore() {
        Publishers.CombineLatest(customRulesStore.$rules, $searchText)
            .map { rules, search in
                if search.trimmingCharacters(in: .whitespaces).isEmpty {
                    return rules
                }
                return rules.filter { $0.domain.localizedCaseInsensitiveContains(search) }
            }
            .sink { [weak self] filtered in
                self?.activeRules = filtered.filter { $0.isEnabled }
                self?.inactiveRules = filtered.filter { !$0.isEnabled }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func toggleRule(_ rule: CustomRule) {
        var updated = rule
        updated = CustomRule(
            domain: rule.domain,
            blockAds: rule.blockAds,
            blockTrackers: rule.blockTrackers,
            antiAdblock: rule.antiAdblock,
            hideElements: rule.hideElements,
            isEnabled: !rule.isEnabled
        )
        // Сохраняем id
        customRulesStore.update(withId: rule.id, rule: updated)

        Task {
            await ruleService.updateRules(config: configProvider())
        }
    }

    func deleteRule(_ rule: CustomRule) {
        customRulesStore.remove(id: rule.id)

        Task {
            await ruleService.updateRules(config: configProvider())
        }
    }

    func subtitle(for rule: CustomRule) -> String {
        var parts: [String] = []
        if rule.blockAds { parts.append("ads") }
        if rule.blockTrackers { parts.append("trackers") }
        if rule.antiAdblock { parts.append("anti-adblock") }
        if rule.hideElements { parts.append("elements") }

        if parts.isEmpty {
            return "No rules configured"
        }
        return "Blocking " + parts.joined(separator: ", ")
    }

    func openAddCustomRule() {
        editingRule = nil
        showAddCustomRule = true
    }
    
    func openEditRule(_ rule: CustomRule) {
        editingRule = rule
        showAddCustomRule = true
    }
    
    func dismissAddCustomRule() {
        showAddCustomRule = false
        editingRule = nil
    }
}
