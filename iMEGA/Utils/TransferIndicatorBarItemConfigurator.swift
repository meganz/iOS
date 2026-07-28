import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import Transfer
import UIKit

@objc @MainActor
final class TransferIndicatorBarItemConfigurator: NSObject {

    static var toolbarFactory: TransferIndicatorToolbarFactory {
        .indicator(action: presentTransfers)
    }

    static var tracker: some AnalyticsTracking = DIContainer.tracker

    @objc static func injectIfNeeded(into viewController: UIViewController) {
        toolbarFactory.injectIfNeeded(into: viewController)
    }

    /// True if the indicator is currently expected to appear in a navigation bar.
    /// Mirrors the condition used by `BarItemObserver` so callers that want to adapt
    /// layout (e.g. title width) stay in sync with actual bar item insertion.
    static var isIndicatorDisplayed: Bool {
        SharedTransferIndicator.isCurrentlyVisible
    }

    /// Presents the transfers screen modally. Also used by SwiftUI screens
    /// that add the indicator to their own toolbar.
    @objc static func presentTransfers() {
        tracker.trackAnalyticsEvent(with: TransfersToolbarWidgetPressedEvent())

        let rootVC: UIViewController
        var rowRouter: TransferRowActionRouter?
        // Filled in once the navigation controller below exists; the revamped
        // screen renders Close itself and calls this, rather than us attaching a
        // UIKit bar button it could not swap out while selecting.
        var dismissModal: (@MainActor () -> Void)?
        let isNewTransfers = DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newTransfers)
        if isNewTransfers {
            let router = TransferRowActionRouter()
            rowRouter = router
            rootVC = TransfersListViewControllerFactory.make(
                nodeUseCase: NodeUseCase(
                    nodeDataRepository: NodeDataRepository.newRepo,
                    nodeValidationRepository: NodeValidationRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo
                ),
                rowRouter: router,
                onClose: { dismissModal?() }
            )
        } else {
            let transferWidgetVC = TransfersWidgetViewController.sharedTransfer()
            guard transferWidgetVC.presentingViewController == nil,
                  !transferWidgetVC.isBeingPresented else {
                return
            }
            rootVC = transferWidgetVC
        }

        let navigationController = MEGANavigationController(rootViewController: rootVC)
        // Transfers is presented inside this modal nav; row actions push/present from it.
        rowRouter?.navigationController = navigationController
        if isNewTransfers {
            dismissModal = { [weak navigationController] in
                navigationController?.dismiss(animated: true)
            }
        } else {
            navigationController.addLeftDismissButton(withText: Strings.Localizable.close)
        }
        CrashlyticsLogger.log(category: .transfersWidget, "Showing transfers from nav bar indicator")
        UIApplication.mnz_visibleViewController().present(navigationController, animated: true)
    }
}
