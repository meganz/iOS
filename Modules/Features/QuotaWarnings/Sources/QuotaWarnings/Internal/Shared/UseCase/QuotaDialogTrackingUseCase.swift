import MEGAAnalyticsiOS
import MEGAAppPresentation

enum QuotaDialogAudience: Equatable {
    case free
    case paid
    case signedOut
}

struct QuotaDialogTrackingUseCase: QuotaDialogTrackingUseCaseProtocol {
    private enum TrackedDialog {
        case storageAlmostFull
        case storageFull
        case transferAlmostUsed
        case transferAllUsed

        init(kind: QuotaWarningDialogView.Kind) {
            self = switch kind {
            case .storage(.almostFull): .storageAlmostFull
            case .storage(.full): .storageFull
            case .transfer(.limitedDownload), .transfer(.limitedStreaming): .transferAlmostUsed
            case .transfer(.downloadExceeded), .transfer(.streamingExceeded): .transferAllUsed
            }
        }
    }

    private struct DialogEvents {
        let screenView: any ScreenViewEventIdentifier
        let upgradeButtonPressed: any ButtonPressedEventIdentifier
        let viewAllPlansButtonPressed: any ButtonPressedEventIdentifier
    }

    private let dialog: TrackedDialog
    private let audience: QuotaDialogAudience
    private let tracker: any AnalyticsTracking

    init(
        kind: QuotaWarningDialogView.Kind,
        audience: QuotaDialogAudience,
        tracker: some AnalyticsTracking
    ) {
        self.dialog = TrackedDialog(kind: kind)
        self.audience = audience
        self.tracker = tracker
    }

    func trackScreenView() {
        guard let events else { return }
        tracker.trackAnalyticsEvent(with: events.screenView)
    }

    func trackUpgradeTapped() {
        guard let events else { return }
        tracker.trackAnalyticsEvent(with: events.upgradeButtonPressed)
    }

    func trackViewAllPlansTapped() {
        guard let events else { return }
        tracker.trackAnalyticsEvent(with: events.viewAllPlansButtonPressed)
    }

    // MARK: - Private

    private var events: DialogEvents? {
        switch (dialog, audience) {
        case (.storageAlmostFull, .free):
            return DialogEvents(
                screenView: StorageAlmostFullFreeUserDialogScreenEvent(),
                upgradeButtonPressed: StorageAlmostFullFreeUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: StorageAlmostFullFreeUserViewAllPlansButtonPressedEvent()
            )
        case (.storageAlmostFull, .paid):
            return DialogEvents(
                screenView: StorageAlmostFullProUserDialogScreenEvent(),
                upgradeButtonPressed: StorageAlmostFullProUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: StorageAlmostFullProUserViewAllPlansButtonPressedEvent()
            )
        case (.storageFull, .free):
            return DialogEvents(
                screenView: StorageFullFreeUserDialogScreenEvent(),
                upgradeButtonPressed: StorageFullFreeUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: StorageFullFreeUserViewAllPlansButtonPressedEvent()
            )
        case (.storageFull, .paid):
            return DialogEvents(
                screenView: StorageFullProUserDialogScreenEvent(),
                upgradeButtonPressed: StorageFullProUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: StorageFullProUserViewAllPlansButtonPressedEvent()
            )
        case (.storageAlmostFull, .signedOut), (.storageFull, .signedOut):
            /// Unreachable. Can not consume storage (upload, camera upload, send file in chat etc...) while signed out.
            return nil
        case (.transferAlmostUsed, .free):
            return DialogEvents(
                screenView: TransferAlmostUsedFreeUserDialogScreenEvent(),
                upgradeButtonPressed: TransferAlmostUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: TransferAlmostUsedFreeUserViewAllPlansButtonPressedEvent()
            )
        case (.transferAlmostUsed, .paid):
            return DialogEvents(
                screenView: TransferAlmostUsedProUserDialogScreenEvent(),
                upgradeButtonPressed: TransferAlmostUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: TransferAlmostUsedProUserViewAllPlansButtonPressedEvent()
            )
        case (.transferAlmostUsed, .signedOut):
            return DialogEvents(
                screenView: TransferAlmostUsedNotLoggedInUserDialogScreenEvent(),
                upgradeButtonPressed: TransferAlmostUsedNotLoggedInUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: TransferAlmostUsedNotLoggedInUserViewAllPlansButtonPressedEvent()
            )
        case (.transferAllUsed, .free):
            return DialogEvents(
                screenView: TransferAllUsedFreeUserDialogScreenEvent(),
                upgradeButtonPressed: TransferAllUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: TransferAllUsedFreeUserViewAllPlansButtonPressedEvent()
            )
        case (.transferAllUsed, .paid):
            return DialogEvents(
                screenView: TransferAllUsedProUserDialogScreenEvent(),
                upgradeButtonPressed: TransferAllUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: TransferAllUsedProUserViewAllPlansButtonPressedEvent()
            )
        case (.transferAllUsed, .signedOut):
            return DialogEvents(
                screenView: TransferAllUsedNotLoggedInUserDialogScreenEvent(),
                upgradeButtonPressed: TransferAllUsedNotLoggedInUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: TransferAllUsedNotLoggedInUserViewAllPlansButtonPressedEvent()
            )
        }
    }
}
