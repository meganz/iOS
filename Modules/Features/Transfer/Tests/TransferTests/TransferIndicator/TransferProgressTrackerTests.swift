import CoreGraphics
import MEGADomain
import MEGADomainMock
import Testing
@testable import Transfer

/// Regression coverage for the Live Activity running ahead of the Transfer Manager.
///
/// The SDK's `transferredBytes` is not monotonic: it rewinds to the last contiguous
/// completed block whenever a transfer's connection slot is rebuilt (pause/resume,
/// chunk timeout, retry). The tracker must follow it down, because the Transfer Manager
/// row renders that same raw value.
@Suite("TransferProgressTrackerTests")
struct TransferProgressTrackerTests {

    private static let mb = 1024 * 1024

    @Test("SDK rewinding mid-transfer pulls batch progress back down with it")
    func upsert_whenSDKRewinds_progressFollowsItDown() async {
        let sut = TransferProgressTracker()

        await sut.upsert(upload(tag: 1, transferred: 300 * Self.mb, total: 400 * Self.mb))
        #expect(await sut.progress() == 0.75)

        // Chunk timeout: the in-flight bytes are dropped and the SDK reports less.
        await sut.upsert(upload(tag: 1, transferred: 200 * Self.mb, total: 400 * Self.mb))

        #expect(await sut.progress() == 0.5)
    }

    @Test("A download rewinding without a retry pulls progress back down too")
    func upsert_whenDownloadRewinds_progressFollowsItDown() async {
        let sut = TransferProgressTracker()

        await sut.upsert(download(tag: 1, transferred: 300 * Self.mb, total: 400 * Self.mb))
        #expect(await sut.progress() == 0.75)

        // Downloads rewind without a chunk retry: a rebuilt connection gives back the
        // in-flight bytes it had not yet had confirmed.
        await sut.upsert(download(tag: 1, transferred: 200 * Self.mb, total: 400 * Self.mb))

        #expect(await sut.progress() == 0.5)
    }

    @Test("Pause then resume rewinds progress instead of freezing it")
    func upsert_whenPausedAndResumedAtAnEarlierOffset_progressRewinds() async {
        let sut = TransferProgressTracker()

        await sut.upsert(upload(tag: 1, transferred: 384 * Self.mb, total: 512 * Self.mb))
        await sut.upsert(upload(tag: 1, transferred: 384 * Self.mb, total: 512 * Self.mb, state: .paused))

        // Resuming rebuilds the slot; the SDK restarts from the last contiguous block.
        await sut.upsert(upload(tag: 1, transferred: 256 * Self.mb, total: 512 * Self.mb))

        #expect(await sut.progress() == 0.5)
    }

    @Test("The denominator picks up a file size the SDK only reports later")
    func upsert_whenTotalBytesArriveAfterQueueing_denominatorCorrectsItself() async {
        let sut = TransferProgressTracker()

        // Queued before the SDK knows the size.
        await sut.upsert(upload(tag: 1, transferred: 0, total: 0))
        await sut.upsert(upload(tag: 1, transferred: 100 * Self.mb, total: 400 * Self.mb))

        #expect(await sut.progress() == 0.25)
    }

    @Test("A transfer finishing below its size contributes what the SDK reported, like its row")
    func trackFinish_whenCompletedBelowItsSize_matchesTheRowInsteadOfRoundingUp() async {
        let sut = TransferProgressTracker()

        await sut.upsert(upload(tag: 1, transferred: 0, total: 400 * Self.mb))
        await sut.upsert(upload(tag: 2, transferred: 0, total: 400 * Self.mb))
        // A deduplicated upload finishes having moved only part of the file. Its row shows
        // that same fraction, so the batch total must not invent the missing bytes.
        await sut.trackFinish(
            upload(tag: 1, transferred: 100 * Self.mb, total: 400 * Self.mb, state: .complete)
        )

        #expect(await sut.progress() == 0.125)
    }

    @Test("Cancelling a rewound transfer leaves no bytes behind for the next one")
    func trackFinish_whenCancelledAfterARewind_doesNotLeakIntoTheNextTransfer() async {
        let sut = TransferProgressTracker()

        await sut.upsert(upload(tag: 1, transferred: 300 * Self.mb, total: 400 * Self.mb))
        await sut.upsert(upload(tag: 1, transferred: 200 * Self.mb, total: 400 * Self.mb))
        await sut.trackFinish(
            upload(tag: 1, transferred: 200 * Self.mb, total: 400 * Self.mb, state: .cancelled)
        )

        // A brand new upload that has not sent a single byte must read 0%.
        await sut.upsert(upload(tag: 2, transferred: 0, total: 400 * Self.mb))

        #expect(await sut.progress() == 0)
    }

    @Test("Completed transfers stay banked while an in-flight one rewinds")
    func calculateProgress_withCompletedAndRewindingTransfers_onlyRewindsTheActivePart() async {
        let sut = TransferProgressTracker()

        await sut.upsert(upload(tag: 1, transferred: 0, total: 400 * Self.mb))
        await sut.upsert(upload(tag: 2, transferred: 0, total: 400 * Self.mb))
        await sut.trackFinish(
            upload(tag: 1, transferred: 400 * Self.mb, total: 400 * Self.mb, state: .complete)
        )
        await sut.upsert(upload(tag: 2, transferred: 200 * Self.mb, total: 400 * Self.mb))
        #expect(await sut.progress() == 0.75)

        await sut.upsert(upload(tag: 2, transferred: 100 * Self.mb, total: 400 * Self.mb))

        #expect(await sut.progress() == 0.625)
    }

    @Test("A completed transfer is not counted twice when a late update arrives")
    func upsert_afterTrackFinish_doesNotDoubleCountTheCompletedTransfer() async {
        let sut = TransferProgressTracker()

        await sut.upsert(upload(tag: 1, transferred: 0, total: 400 * Self.mb))
        await sut.upsert(upload(tag: 2, transferred: 0, total: 400 * Self.mb))
        await sut.trackFinish(
            upload(tag: 1, transferred: 400 * Self.mb, total: 400 * Self.mb, state: .complete)
        )

        // A stale update for the finished tag must be ignored, not re-added.
        await sut.upsert(upload(tag: 1, transferred: 400 * Self.mb, total: 400 * Self.mb))

        #expect(await sut.progress() == 0.5)
    }

    @Test("A repeated finish event does not bank the same transfer twice")
    func trackFinish_whenTheSameTagFinishesTwice_banksItOnce() async {
        let sut = TransferProgressTracker()

        await sut.upsert(upload(tag: 1, transferred: 0, total: 400 * Self.mb))
        await sut.upsert(upload(tag: 2, transferred: 0, total: 400 * Self.mb))
        let finished = upload(tag: 1, transferred: 400 * Self.mb, total: 400 * Self.mb, state: .complete)

        await sut.trackFinish(finished)
        await sut.trackFinish(finished)

        #expect(await sut.progress() == 0.5)
    }

    // MARK: - Helpers

    private func upload(
        tag: Int,
        transferred: Int,
        total: Int,
        state: TransferStateEntity = .active
    ) -> TransferEntity {
        TransferEntity(
            type: .upload,
            transferredBytes: transferred,
            totalBytes: total,
            tag: tag,
            state: state
        )
    }

    private func download(
        tag: Int,
        transferred: Int,
        total: Int,
        state: TransferStateEntity = .active
    ) -> TransferEntity {
        TransferEntity(
            type: .download,
            transferredBytes: transferred,
            totalBytes: total,
            tag: tag,
            state: state
        )
    }
}

private extension TransferProgressTracker {
    func progress() async -> CGFloat? {
        await snapshot(isGloballyPaused: false)?.progress
    }
}
