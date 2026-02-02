
import SwiftUI

enum Screens {
    case general
    case custom
}

struct TapBarView: View {
    @State private var selectedTab: Screens = .general
    @EnvironmentObject var coordinator: AppCoordinator

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

