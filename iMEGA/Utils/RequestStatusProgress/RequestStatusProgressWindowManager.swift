import Accounts
import SwiftUI

@MainActor
final class RequestStatusProgressWindowManager {
    private var hostingController: UIHostingController<RequestStatusProgressView>?

    func showProgressView(with viewModel: RequestStatusProgressViewModel, in tabBarController: MainTabBarController) {
        guard hostingController == nil else { return }

        let hostingController = UIHostingController(rootView: RequestStatusProgressView(viewModel: viewModel))
        hostingController.view.backgroundColor = .clear

        // Drive the bar through the tab bar's bottom-overlay container. It already positions content
        // above the tab bar, drops to the bottom safe area when the tab bar is hidden, and refreshes
        // on navigation, so it stays correctly placed across iOS versions and screen changes. The
        // `.highest` priority keeps the bar at the very bottom of the overlay, just above the tab bar.
        tabBarController.addSubviewToOverlay(
            hostingController.view,
            type: .requestStatusProgress,
            priority: .highest
        )

        self.hostingController = hostingController
    }

    func hideProgressView(in tabBarController: MainTabBarController) {
        tabBarController.removeSubviewFromOverlay(.requestStatusProgress)
        hostingController = nil
    }
}
