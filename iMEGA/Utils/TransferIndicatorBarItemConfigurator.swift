import MEGAAppPresentation
import MEGAL10n
import Transfer
import UIKit

@objc @MainActor
final class TransferIndicatorBarItemConfigurator: NSObject {
    static var toolbarFactory: TransferIndicatorToolbarFactory {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .homeRevampPhaseOne)
            ? .indicator(action: presentTransfers)
            : .hidden
    }

    @objc static func injectIfNeeded(into viewController: UIViewController) {
        toolbarFactory.injectIfNeeded(into: viewController)
    }

    /// Presents the transfers screen modally. Also used by SwiftUI screens
    /// that add the indicator to their own toolbar.
    @objc static func presentTransfers() {
        let transferWidgetVC = TransfersWidgetViewController.sharedTransfer()

        guard transferWidgetVC.presentingViewController == nil,
              !transferWidgetVC.isBeingPresented else {
            return
        }

        let navigationController = MEGANavigationController(rootViewController: transferWidgetVC)
        navigationController.addLeftDismissButton(withText: Strings.Localizable.close)
        CrashlyticsLogger.log(category: .transfersWidget, "Showing transfers from nav bar indicator")
        UIApplication.mnz_visibleViewController().present(navigationController, animated: true)
    }
}
