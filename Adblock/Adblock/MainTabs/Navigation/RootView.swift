//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import SwiftUI



struct RootView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        content
            .task {
                await coordinator.ruleService.preloadFilters()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.flow {
        case .onboarding:
            OnbordingView(viewModel: OnbordingViewModel(coordinator: coordinator))
        case .main:
            TapBarView()
                .fullScreenCover(item: $coordinator.route) { route in
                    coordinator.build(route: route)
                }
        }
    }
}
