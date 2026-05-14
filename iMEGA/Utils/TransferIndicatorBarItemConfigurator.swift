import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import Transfer
import UIKit

@objc @MainActor
final class TransferIndicatorBarItemConfigurator: NSObject {

    static var toolbarFactory: TransferIndicatorToolbarFactory {
        DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosHomeRevampPhaseOne)
            ? .indicator(action: presentTransfers)
            : .hidden
    }

    static var tracker: some AnalyticsTracking = DIContainer.tracker

    @objc static func injectIfNeeded(into viewController: UIViewController) {
        toolbarFactory.injectIfNeeded(into: viewController)
    }

    /// True if the indicator is currently expected to appear in a navigation bar.
    /// Mirrors the condition used by `BarItemObserver` so callers that want to adapt
    /// layout (e.g. title width) stay in sync with actual bar item insertion.
    static var isIndicatorDisplayed: Bool {
        toolbarFactory.isEnabled && SharedTransferIndicator.isCurrentlyVisible
    }

    /// Presents the transfers screen modally. Also used by SwiftUI screens
    /// that add the indicator to their own toolbar.
    @objc static func presentTransfers() {
        tracker.trackAnalyticsEvent(with: TransfersToolbarWidgetPressedEvent())

        let rootVC: UIViewController
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newTransfers) {
            rootVC = TransfersListViewControllerFactory.make()
        } else {
            let transferWidgetVC = TransfersWidgetViewController.sharedTransfer()
            guard transferWidgetVC.presentingViewController == nil,
                  !transferWidgetVC.isBeingPresented else {
                return
            }
            rootVC = transferWidgetVC
        }

        let navigationController = MEGANavigationController(rootViewController: rootVC)
        navigationController.addLeftDismissButton(withText: Strings.Localizable.close)
        CrashlyticsLogger.log(category: .transfersWidget, "Showing transfers from nav bar indicator")
        UIApplication.mnz_visibleViewController().present(navigationController, animated: true)
    }
}
