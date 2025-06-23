import MEGAAccountManagement
import SwiftUI

@main
struct PlayerApp: App {
    @UIApplicationDelegateAdaptor var delegate: AppDelegate

    @StateObject var viewModel = PlayerAppViewModel.shared

    var body: some Scene {
        WindowGroup {
            LaunchView(viewModel: viewModel.launchViewModel)
                .modifier(OffboardingHandlerViewModifier(viewModel: .liveValue))
        }
    }
}
