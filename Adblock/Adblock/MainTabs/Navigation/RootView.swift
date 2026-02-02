
import SwiftUI

struct RootView: View{
    @EnvironmentObject var coordinator: AppCoordinator
    var body: some View {
        TapBarView()
            .fullScreenCover(item: $coordinator.route) { route in
                coordinator.build(route: route)
            }
    }
}
