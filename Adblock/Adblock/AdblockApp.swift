//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//

import SwiftUI

@main
struct AdblockApp: App {
    @StateObject private var coordinator: AppCoordinator

    init() {
        // Создаём RulesService при запуске приложения — preloadFilters стартует сразу в init()
        let customRulesStore = CustomRulesStore()
        let ruleService = RulesService(customRulesStore: customRulesStore)
        _coordinator = StateObject(wrappedValue: AppCoordinator(
            customRulesStore: customRulesStore,
            ruleService: ruleService
        ))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(coordinator)
        }
    }
}
