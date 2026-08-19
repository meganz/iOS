import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import Testing
@testable import QuotaWarnings

/// One row of the analytics spec: the dialog, who is looking at it, and the three events they must produce.
private struct SpecRow {
    let kind: QuotaWarningDialogView.Kind
    let audience: QuotaDialogAudience
    let screenView: any EventIdentifier
    let upgrade: any EventIdentifier
    let viewAllPlans: any EventIdentifier
}

@Suite("QuotaDialogTrackingUseCase")
struct QuotaDialogTrackingUseCaseTests {
    /// Every dialog the app can show, against the events the spec pairs it with. The two full-storage
    /// triggers share the storage-full events, and download and streaming share the transfer events. Only the
    /// transfer dialog can be reached signed out, and it has its own not-logged-in events.
    private var spec: [SpecRow] {
        [
            SpecRow(
                kind: .storage(.almostFull), audience: .free,
                screenView: StorageAlmostFullFreeUserDialogScreenEvent(),
                upgrade: StorageAlmostFullFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageAlmostFullFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .storage(.almostFull), audience: .paid,
                screenView: StorageAlmostFullProUserDialogScreenEvent(),
                upgrade: StorageAlmostFullProUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageAlmostFullProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .storage(.full(.storageState)), audience: .free,
                screenView: StorageFullFreeUserDialogScreenEvent(),
                upgrade: StorageFullFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageFullFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .storage(.full(.storageState)), audience: .paid,
                screenView: StorageFullProUserDialogScreenEvent(),
                upgrade: StorageFullProUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageFullProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .storage(.full(.uploadAttempt)), audience: .free,
                screenView: StorageFullFreeUserDialogScreenEvent(),
                upgrade: StorageFullFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageFullFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .storage(.full(.uploadAttempt)), audience: .paid,
                screenView: StorageFullProUserDialogScreenEvent(),
                upgrade: StorageFullProUserUpgradeButtonPressedEvent(),
                viewAllPlans: StorageFullProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.limitedDownload), audience: .free,
                screenView: TransferAlmostUsedFreeUserDialogScreenEvent(),
                upgrade: TransferAlmostUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAlmostUsedFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.limitedDownload), audience: .paid,
                screenView: TransferAlmostUsedProUserDialogScreenEvent(),
                upgrade: TransferAlmostUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAlmostUsedProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.limitedStreaming), audience: .free,
                screenView: TransferAlmostUsedFreeUserDialogScreenEvent(),
                upgrade: TransferAlmostUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAlmostUsedFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.limitedStreaming), audience: .paid,
                screenView: TransferAlmostUsedProUserDialogScreenEvent(),
                upgrade: TransferAlmostUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAlmostUsedProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.downloadExceeded), audience: .free,
                screenView: TransferAllUsedFreeUserDialogScreenEvent(),
                upgrade: TransferAllUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAllUsedFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.downloadExceeded), audience: .paid,
                screenView: TransferAllUsedProUserDialogScreenEvent(),
                upgrade: TransferAllUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAllUsedProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.streamingExceeded), audience: .free,
                screenView: TransferAllUsedFreeUserDialogScreenEvent(),
                upgrade: TransferAllUsedFreeUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAllUsedFreeUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.streamingExceeded), audience: .paid,
                screenView: TransferAllUsedProUserDialogScreenEvent(),
                upgrade: TransferAllUsedProUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAllUsedProUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.limitedDownload), audience: .signedOut,
                screenView: TransferAlmostUsedNotLoggedInUserDialogScreenEvent(),
                upgrade: TransferAlmostUsedNotLoggedInUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAlmostUsedNotLoggedInUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.limitedStreaming), audience: .signedOut,
                screenView: TransferAlmostUsedNotLoggedInUserDialogScreenEvent(),
                upgrade: TransferAlmostUsedNotLoggedInUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAlmostUsedNotLoggedInUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.downloadExceeded), audience: .signedOut,
                screenView: TransferAllUsedNotLoggedInUserDialogScreenEvent(),
                upgrade: TransferAllUsedNotLoggedInUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAllUsedNotLoggedInUserViewAllPlansButtonPressedEvent()
            ),
            SpecRow(
                kind: .transfer(.streamingExceeded), audience: .signedOut,
                screenView: TransferAllUsedNotLoggedInUserDialogScreenEvent(),
                upgrade: TransferAllUsedNotLoggedInUserUpgradeButtonPressedEvent(),
                viewAllPlans: TransferAllUsedNotLoggedInUserViewAllPlansButtonPressedEvent()
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
        let sut = QuotaDialogTrackingUseCase(kind: .storage(.almostFull), audience: .free, tracker: tracker)

        sut.trackScreenView()
        sut.trackUpgradeTapped()
        sut.trackViewAllPlansTapped()

        let trackedEvents = tracker.trackedEventIdentifiers.map(eventName)
        #expect(trackedEvents.count == 3)
        #expect(Set(trackedEvents).count == 3)
    }

    @Test(arguments: [StorageQuotaSeverity.almostFull, .full(.storageState), .full(.uploadAttempt)])
    func signedOutStorageDialog_tracksNothing(severity: StorageQuotaSeverity) {
        let tracker = MockTracker()
        let sut = QuotaDialogTrackingUseCase(kind: .storage(severity), audience: .signedOut, tracker: tracker)

        sut.trackScreenView()
        sut.trackUpgradeTapped()
        sut.trackViewAllPlansTapped()

        #expect(tracker.trackedEventIdentifiers.isEmpty)
    }

    // MARK: - Private

    private func assertEachSpecRow(
        track: (QuotaDialogTrackingUseCase) -> Void,
        expected: KeyPath<SpecRow, any EventIdentifier>
    ) {
        for row in spec {
            let tracker = MockTracker()
            let sut = QuotaDialogTrackingUseCase(kind: row.kind, audience: row.audience, tracker: tracker)

            track(sut)

            let context = Comment(rawValue: "\(row.kind), audience: \(row.audience)")
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
