//
//  File.swift
//  Adblock
//
//  Created by Telegram: @Boytik_E on 03.02.2026.
//
import SwiftUI
import UIKit

enum Screens {
    case general
    case custom
}

struct TapBarView: View {
    @State private var selectedTab: Screens = .general
    @EnvironmentObject var coordinator: AppCoordinator

    init() {
        // Тёмный tab bar для версий до iOS 26, на 26 — системный
        if #available(iOS 26.0, *) {
            // iOS 26+ — не переопределяем
        } else {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .black
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                coordinator.build(route: .general)
                    .tabItem {
                        Label("General", image: "GeneralTab")
                    }
                    .tag(Screens.general)

                coordinator.build(route: .custom)
                    .tabItem {
                        Label("Custom", image: "CustomTab")
                    }
                    .tag(Screens.custom)
            }
            .background(Color.black)
        }
    }
}

