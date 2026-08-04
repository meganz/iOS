import MEGAAnalyticsiOS
import MEGAAppPresentation

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
    private let isFreeUser: Bool
    private let tracker: any AnalyticsTracking

    init(
        kind: QuotaWarningDialogView.Kind,
        isFreeUser: Bool,
        tracker: some AnalyticsTracking
    ) {
        self.dialog = TrackedDialog(kind: kind)
        self.isFreeUser = isFreeUser
        self.tracker = tracker
    }

    func trackScreenView() {
        tracker.trackAnalyticsEvent(with: events.screenView)
    }

    func trackUpgradeTapped() {
        tracker.trackAnalyticsEvent(with: events.upgradeButtonPressed)
    }

    func trackViewAllPlansTapped() {
        tracker.trackAnalyticsEvent(with: events.viewAllPlansButtonPressed)
    }

    // MARK: - Private

    private var events: DialogEvents {
        switch (dialog, isFreeUser) {
        case (.storageAlmostFull, true):
            DialogEvents(
                screenView: StorageAlmostFullFreeUserDialogScreenEvent(),
                upgradeButtonPressed: StorageAlmostFullFreeUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: StorageAlmostFullFreeUserViewAllPlansButtonPressedEvent()
            )
        case (.storageAlmostFull, false):
            DialogEvents(
                screenView: StorageAlmostFullProUserDialogScreenEvent(),
                upgradeButtonPressed: StorageAlmostFullProUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: StorageAlmostFullProUserViewAllPlansButtonPressedEvent()
            )
        case (.storageFull, true):
            DialogEvents(
                screenView: StorageFullFreeUserDialogScreenEvent(),
                upgradeButtonPressed: StorageFullFreeUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: StorageFullFreeUserViewAllPlansButtonPressedEvent()
            )
        case (.storageFull, false):
            DialogEvents(
                screenView: StorageFullProUserDialogScreenEvent(),
                upgradeButtonPressed: StorageFullProUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: StorageFullProUserViewAllPlansButtonPressedEvent()
            )
        case (.transferAlmostUsed, true):
            DialogEvents(
                screenView: TransferAlmostUsedFreeUserDialogScreenEvent(),
                upgradeButtonPressed: TransferAlmostUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: TransferAlmostUsedFreeUserViewAllPlansButtonPressedEvent()
            )
        case (.transferAlmostUsed, false):
            DialogEvents(
                screenView: TransferAlmostUsedProUserDialogScreenEvent(),
                upgradeButtonPressed: TransferAlmostUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: TransferAlmostUsedProUserViewAllPlansButtonPressedEvent()
            )
        case (.transferAllUsed, true):
            DialogEvents(
                screenView: TransferAllUsedFreeUserDialogScreenEvent(),
                upgradeButtonPressed: TransferAllUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: TransferAllUsedFreeUserViewAllPlansButtonPressedEvent()
            )
        case (.transferAllUsed, false):
            DialogEvents(
                screenView: TransferAllUsedProUserDialogScreenEvent(),
                upgradeButtonPressed: TransferAllUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlansButtonPressed: TransferAllUsedProUserViewAllPlansButtonPressedEvent()
            )
        }
    }
}
