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
            if isRedesignEnabled {
                let severity: StorageQuotaSeverity = event.number == StorageState.orange.rawValue ? .almostFull : .full
                presentStorageDialog(severity: severity)
            } else {
                // Old logic, copied over
                CustomModalAlertStorageRouter(
                    .storageEvent,
                    event: event,
                    presenter: UIApplication.mnz_presentingViewController()
                ).start()
            }
        }
    }
    
    @objc func presentStorageQuotaWarning(error: MEGAError, legacyMode: CustomModalAlertMode) {
        Task { @MainActor in
            if isRedesignEnabled {
                presentStorageDialog(severity: error.type == .apiEOverQuota ? .full : .almostFull)
            } else {
                CustomModalAlertRouter(
                    legacyMode,
                    presenter: UIApplication.mnz_presentingViewController()
                ).start()
            }
        }
    }

    func presentTransferQuotaWarning(mode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode) {
        let presenter = UIApplication.mnz_presentingViewController()

        if isRedesignEnabled {
            let severity: TransferQuotaSeverity = switch mode {
            case .limitedDownload: .limitedDownload
            case .downloadExceeded: .downloadExceeded
            case .streamingExceeded: .streamingExceeded
            }
            presentQuotaDialog(for: .transfer(severity))
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

    /// Presents the redesigned storage quota dialog directly (guarded against stacking). For callers that
    /// have already resolved the feature flag and own their own legacy fallback, e.g. album-import.
    func presentStorageDialog(severity: StorageQuotaSeverity) {
        presentQuotaDialog(for: .storage(severity))
    }

    /// Presents a quota dialog, wrapped in a navigation controller for its toolbar close button.
    /// Skips presentation when a quota dialog is already visible
    private func presentQuotaDialog(for kind: QuotaWarningDialogView.Kind) {
        guard !isQuotaDialogAlreadyPresented else { return }
        let presenter = UIApplication.mnz_presentingViewController()
        let onClose: @MainActor () -> Void = { [weak presenter] in presenter?.dismiss(animated: true) }
        let hostingController = QuotaWarningDialogHostingController(rootView: QuotaWarningDialogView(kind: kind, onClose: onClose))
        let navigationController = MEGANavigationController(rootViewController: hostingController)
        presenter.present(navigationController, animated: true)
    }

    private var isQuotaDialogAlreadyPresented: Bool {
        UIApplication.mnz_visibleViewController() is any QuotaWarningDialogHosting
    }
}

/// Marker so an already-presented revamp quota dialog can be detected via `mnz_visibleViewController()`,
/// Check `isQuotaDialogAlreadyPresented`
private protocol QuotaWarningDialogHosting {}

private final class QuotaWarningDialogHostingController<Content: View>: UIHostingController<Content>, QuotaWarningDialogHosting {}

private struct QuotaWarningDialogView: View {
    enum Kind {
        case storage(StorageQuotaSeverity)
        case transfer(TransferQuotaSeverity)
    }
    
    let kind: Kind
    let onClose: @MainActor () -> Void
    
    var body: some View {
        switch kind {
        case .storage(let storageQuotaSeverity):
            StorageQuotaDialogView(severity: storageQuotaSeverity, onClose: onClose)
        case .transfer(let transferQuotaSeverity):
            TransferQuotaDialogView(severity: transferQuotaSeverity, onClose: onClose)
        }
    }
}
