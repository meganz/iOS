import Foundation
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing
@testable import Transfer

/// The row reads as `<file name>, <state>, <progress>` — deliberately not the
/// visible subtitle, which is `↑`/`·` shorthand plus byte counts and a speed that
/// churn once a second. The progress is the *value*, not part of the label, so a
/// 1 Hz update does not make VoiceOver re-announce the focused row from the top.
@Suite("TransferRowState accessibility label")
struct TransferRowStateAccessibilityTests {

    private func state(
        type: TransferTypeEntity = .upload,
        transferredBytes: Int = 0,
        totalBytes: Int = 0,
        fileName: String = "photo.jpg",
        state: TransferStateEntity
    ) -> TransferRowState {
        TransferEntityMapper.rowState(
            for: TransferEntity(
                type: type,
                transferredBytes: transferredBytes,
                totalBytes: totalBytes,
                fileName: fileName,
                state: state
            ),
            isRetryable: false
        )
    }

    @Test func active_readsNameAndStateWithThePercentageAsTheValue() {
        let sut = state(transferredBytes: 48, totalBytes: 100, state: .active)

        #expect(sut.accessibilityLabel == "photo.jpg, \(Strings.Localizable.Transfers.Tab.active)")
        #expect(sut.accessibilityValue == "48%")
    }

    @Test func paused_keepsThePercentageAndNamesThePausedState() {
        let sut = state(transferredBytes: 48, totalBytes: 100, state: .paused)

        #expect(sut.accessibilityLabel == "photo.jpg, \(Strings.Localizable.paused)")
        #expect(sut.accessibilityValue == "48%")
    }

    /// The percentage is what changes once a second. Keeping it out of the label
    /// is what stops VoiceOver re-announcing a focused row — and resetting its
    /// action rotor — on every progress tick.
    @Test func label_isUnchangedByProgress() {
        let early = state(transferredBytes: 10, totalBytes: 100, state: .active)
        let late = state(transferredBytes: 90, totalBytes: 100, state: .active)

        #expect(early.accessibilityLabel == late.accessibilityLabel)
        #expect(early.accessibilityValue != late.accessibilityValue)
    }

    /// A queued transfer has made no progress worth reading, so the value is empty
    /// rather than a bare "0 percent".
    @Test func queued_hasNoValue() {
        let sut = state(state: .queued)

        #expect(sut.accessibilityLabel == "photo.jpg, \(Strings.Localizable.queued)")
        #expect(sut.accessibilityValue.isEmpty)
    }

    @Test(
        "terminal states name themselves and drop the percentage",
        arguments: [
            (TransferStateEntity.complete, Strings.Localizable.Transfers.Tab.completed),
            (TransferStateEntity.failed, Strings.Localizable.Transfers.Tab.failed),
            (TransferStateEntity.cancelled, Strings.Localizable.cancelled)
        ]
    )
    func terminal_readsNameThenState(entityState: TransferStateEntity, expected: String) {
        let sut = state(transferredBytes: 100, totalBytes: 100, state: entityState)

        #expect(sut.accessibilityLabel == "photo.jpg, \(expected)")
        #expect(sut.accessibilityValue.isEmpty)
    }

    /// The visible subtitle carries `↑`, `·` separators, byte counts and a speed —
    /// none of which reads back usefully — so the label must not just mirror it.
    @Test func label_isNotTheVisibleSubtitle() {
        let sut = state(transferredBytes: 48, totalBytes: 100, state: .active)

        #expect(sut.accessibilityLabel.contains("↑") == false)
        #expect(sut.accessibilityLabel.contains("·") == false)
        #expect(sut.accessibilityLabel != "photo.jpg, \(sut.subtitle)")
    }

    @Test func percentage_isRoundedNotTruncated() {
        let sut = state(transferredBytes: 2, totalBytes: 3, state: .active)

        #expect(sut.accessibilityValue == "67%")
    }
}
