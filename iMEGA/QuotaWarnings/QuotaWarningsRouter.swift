import MEGAAppPresentation
import MEGASdk
import QuotaWarnings
import SwiftUI
import UIKit

@MainActor
@objc final class QuotaWarningsRouter: NSObject {

    private var isRedesignEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .quotaWarningsRevamp)
    }

    @objc func presentStorageQuotaWarning(event: MEGAEvent) {
        Task { @MainActor in
            let presenter = UIApplication.mnz_presentingViewController()

            if isRedesignEnabled {
                let severity: StorageQuotaSeverity = event.number == StorageState.orange.rawValue ? .almostFull : .full
                let hostingController = UIHostingController(
                    rootView: StorageQuotaDialogView(severity: severity, onClose: { [weak presenter] in
                        presenter?.dismiss(animated: true)
                    })
                )
                let nvc = MEGANavigationController(rootViewController: hostingController)
                presenter.present(nvc, animated: true)
            } else {
                // Old logic, copied over
                CustomModalAlertStorageRouter(.storageEvent, event: event, presenter: presenter).start()
            }
        }
    }

    func presentTransferQuotaWarning(mode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode) {
        let presenter = UIApplication.mnz_presentingViewController()

        if isRedesignEnabled {
            let hostingController = UIHostingController(rootView: TransferQuotaDialogView())
            presenter.present(hostingController, animated: true)
        } else {
            // Old logic, copied over
            CustomModalAlertRouter(
                .transferDownloadQuotaError,
                presenter: presenter,
                transferQuotaDisplayMode: mode,
                actionHandler: { completion in
                    if AudioPlayerManager.shared.isPlayerAlive() {
                        Task {
                            await AudioPlayerManager.shared.dismissFullScreenPlayer()
                            AudioPlayerManager.shared.closePlayer()
                            completion()
                        }
                    } else {
                        completion()
                    }
                },
                dismissHandler: {
                    if AudioPlayerManager.shared.isPlayerAlive() {
                        Task {
                            await AudioPlayerManager.shared.dismissFullScreenPlayer()
                            AudioPlayerManager.shared.closePlayer()
                        }
                    }
                }
            ).start()
        }
    }
}
