
import SwiftUI

@main
struct AdblockApp: App {
    @StateObject private var coordinator = AppCoordinator()
    var body: some Scene {
        WindowGroup {
//            RootView()
//                .environmentObject(coordinator)
//            QuickGuideView()
            OnbordingView()
        }
    }
}
