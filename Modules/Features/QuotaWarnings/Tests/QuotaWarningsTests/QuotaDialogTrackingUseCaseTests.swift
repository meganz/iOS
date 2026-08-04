import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import Testing
@testable import QuotaWarnings

/// One row of the analytics spec: the dialog, the user tier, and the three events they must produce.
private struct SpecRow {
    let kind: QuotaWarningDialogView.Kind
    let isFreeUser: Bool
    let screenView: any EventIdentifier
    let upgrade: any EventIdentifier
    let viewAllPlans: any EventIdentifier
}

@Suite("QuotaDialogTrackingUseCase")
struct QuotaDialogTrackingUseCaseTests {
    /// Every dialog the app can show, against the events the spec pairs it with. The two full-storage
    /// triggers share the storage-full events, and download and streaming share the transfer events.
    private var spec: [SpecRow] {
        [
            SpecRow(
                kind: .storage(.almostFull), isFreeUser: true,
                screenView: StorageAlmostFullFreeUserDialogScreenEvent(),
                upgrade: StorageAlmostFullFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageAlmostFullFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .storage(.almostFull), isFreeUser: false,
                screenView: StorageAlmostFullProUserDialogScreenEvent(),
                upgrade: StorageAlmostFullProUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageAlmostFullProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .storage(.full(.storageState)), isFreeUser: true,
                screenView: StorageFullFreeUserDialogScreenEvent(),
                upgrade: StorageFullFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageFullFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .storage(.full(.storageState)), isFreeUser: false,
                screenView: StorageFullProUserDialogScreenEvent(),
                upgrade: StorageFullProUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageFullProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .storage(.full(.uploadAttempt)), isFreeUser: true,
                screenView: StorageFullFreeUserDialogScreenEvent(),
                upgrade: StorageFullFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageFullFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .storage(.full(.uploadAttempt)), isFreeUser: false,
                screenView: StorageFullProUserDialogScreenEvent(),
                upgrade: StorageFullProUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageFullProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.limitedDownload), isFreeUser: true,
                screenView: TransferAlmostUsedFreeUserDialogScreenEvent(),
                upgrade: TransferAlmostUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAlmostUsedFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.limitedDownload), isFreeUser: false,
                screenView: TransferAlmostUsedProUserDialogScreenEvent(),
                upgrade: TransferAlmostUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAlmostUsedProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.limitedStreaming), isFreeUser: true,
                screenView: TransferAlmostUsedFreeUserDialogScreenEvent(),
                upgrade: TransferAlmostUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAlmostUsedFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.limitedStreaming), isFreeUser: false,
                screenView: TransferAlmostUsedProUserDialogScreenEvent(),
                upgrade: TransferAlmostUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAlmostUsedProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.downloadExceeded), isFreeUser: true,
                screenView: TransferAllUsedFreeUserDialogScreenEvent(),
                upgrade: TransferAllUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAllUsedFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.downloadExceeded), isFreeUser: false,
                screenView: TransferAllUsedProUserDialogScreenEvent(),
                upgrade: TransferAllUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAllUsedProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.streamingExceeded), isFreeUser: true,
                screenView: TransferAllUsedFreeUserDialogScreenEvent(),
                upgrade: TransferAllUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAllUsedFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.streamingExceeded), isFreeUser: false,
                screenView: TransferAllUsedProUserDialogScreenEvent(),
                upgrade: TransferAllUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAllUsedProUserViewAllPlansButtonPressedEvent()
            )
        ]
    }

    @Test func trackScreenView_tracksTheScreenEventOfTheDialogAndTier() {
        assertEachSpecRow(
            track: { $0.trackScreenView() },
            expected: \.screenView
        )
    }

    @Test func trackUpgradeTapped_tracksTheUpgradeEventOfTheDialogAndTier() {
        assertEachSpecRow(
            track: { $0.trackUpgradeTapped() },
            expected: \.upgrade
        )
    }

    @Test func trackViewAllPlansTapped_tracksTheViewAllPlansEventOfTheDialogAndTier() {
        assertEachSpecRow(
            track: { $0.trackViewAllPlansTapped() },
            expected: \.viewAllPlans
        )
    }

    @Test func theThreeActionsOfOneDialogTrackThreeDistinctEvents() {
        let tracker = MockTracker()
        let sut = QuotaDialogTrackingUseCase(kind: .storage(.almostFull), isFreeUser: true, tracker: tracker)

        sut.trackScreenView()
        sut.trackUpgradeTapped()
        sut.trackViewAllPlansTapped()

        let trackedEvents = tracker.trackedEventIdentifiers.map(eventName)
        #expect(trackedEvents.count == 3)
        #expect(Set(trackedEvents).count == 3)
    }

    // MARK: - Private

    private func assertEachSpecRow(
        track: (QuotaDialogTrackingUseCase) -> Void,
        expected: KeyPath<SpecRow, any EventIdentifier>
    ) {
        for row in spec {
            let tracker = MockTracker()
            let sut = QuotaDialogTrackingUseCase(kind: row.kind, isFreeUser: row.isFreeUser, tracker: tracker)

            track(sut)

            let context = Comment(rawValue: "\(row.kind), isFreeUser: \(row.isFreeUser)")
            #expect(tracker.trackedEventIdentifiers.count == 1, context)
            #expect(
                tracker.trackedEventIdentifiers.first.map(eventName) == eventName(row[keyPath: expected]),
                context
            )
        }
    }

    /// The generated event's type name. `uniqueIdentifier` is only unique within an event category, so a
    /// screen view and a button press can share one — the type is what pins the exact event down.
    private func eventName(_ event: any EventIdentifier) -> String {
        String(describing: type(of: event))
    }
}
