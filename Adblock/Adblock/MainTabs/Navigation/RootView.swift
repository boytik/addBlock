
import SwiftUI



struct RootView: View{
    @EnvironmentObject var coordinator: AppCoordinator
   
    var body: some View {
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
