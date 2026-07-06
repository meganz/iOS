import Combine
@testable import MEGAAppPresentation
import Testing

@Suite("SyncActivityTracker Tests - Verifies burst semantics driving the syncing indicator.")
struct SyncActivityTrackerTests {

    // MARK: - Helpers

    @MainActor
    private static func makeSUT(
        batchThreshold: Int = 5,
        quietInterval: Duration = .milliseconds(50)
    ) -> SyncActivityTracker {
        SyncActivityTracker(batchThreshold: batchThreshold, quietInterval: quietInterval)
    }

    /// Sleeps long enough for the tracker's quiet interval to elapse and its hide task to run.
    private static func waitForQuietInterval() async throws {
        try await Task.sleep(for: .milliseconds(200))
    }

    // MARK: - Showing

    @MainActor
    @Test("Single batch at or above the threshold sets isSyncing immediately")
    static func singleLargeBatchShowsIndicator() {
        let sut = makeSUT(batchThreshold: 5)

        sut.trackActivity(count: 5)

        #expect(sut.isSyncing == true)
    }

    @MainActor
    @Test("Counts accumulate across consecutive batches until the threshold is crossed")
    static func cumulativeBatchesCrossThreshold() {
        let sut = makeSUT(batchThreshold: 5)

        sut.trackActivity(count: 2)
        #expect(sut.isSyncing == false)

        sut.trackActivity(count: 2)
        #expect(sut.isSyncing == false)

        sut.trackActivity(count: 1)
        #expect(sut.isSyncing == true)
    }

    @MainActor
    @Test("Activity below the threshold never sets isSyncing")
    static func smallActivityDoesNotShowIndicator() {
        let sut = makeSUT(batchThreshold: 5)

        sut.trackActivity(count: 4)

        #expect(sut.isSyncing == false)
    }

    // MARK: - Hiding

    @MainActor
    @Test("isSyncing resets to false after the quiet interval elapses with no activity")
    static func quietIntervalHidesIndicator() async throws {
        let sut = makeSUT(batchThreshold: 5)
        sut.trackActivity(count: 5)
        #expect(sut.isSyncing == true)

        try await waitForQuietInterval()

        #expect(sut.isSyncing == false)
    }

    @MainActor
    @Test("The burst count resets after a quiet interval, so later small activity does not re-trigger")
    static func burstResetsAfterQuietInterval() async throws {
        let sut = makeSUT(batchThreshold: 5)
        sut.trackActivity(count: 4)

        try await waitForQuietInterval()

        // Pre-quiet 4 must not carry over; 4 more still below threshold.
        sut.trackActivity(count: 4)
        #expect(sut.isSyncing == false)
    }

    // MARK: - Staying visible between waves

    @MainActor
    @Test("Ongoing activity keeps isSyncing true past the original quiet deadline")
    static func ongoingActivityExtendsVisibility() async throws {
        let sut = makeSUT(batchThreshold: 5, quietInterval: .milliseconds(100))
        sut.trackActivity(count: 5)

        // Keep feeding small waves at intervals shorter than the quiet interval.
        for _ in 0..<3 {
            try await Task.sleep(for: .milliseconds(40))
            sut.trackActivity(count: 1)
            #expect(sut.isSyncing == true)
        }

        // Total elapsed (~120ms) exceeds the 100ms quiet interval, yet the indicator
        // stayed visible because every wave restarted the quiet timer.
        try await Task.sleep(for: .milliseconds(250))
        #expect(sut.isSyncing == false)
    }

    // MARK: - Publishing efficiency

    @MainActor
    @Test("Only actual state transitions are published — no redundant emissions per batch")
    static func noRedundantEmissions() async throws {
        let sut = makeSUT(batchThreshold: 5)
        var emissions: [Bool] = []
        let cancellable = sut.$isSyncing.sink { emissions.append($0) }

        sut.trackActivity(count: 5) // false -> true
        sut.trackActivity(count: 3) // already true: must not re-emit
        sut.trackActivity(count: 2) // already true: must not re-emit
        try await waitForQuietInterval() // true -> false

        sut.trackActivity(count: 1) // below threshold: no emission
        try await waitForQuietInterval() // never shown: must not emit false again

        #expect(emissions == [false, true, false])
        cancellable.cancel()
    }
}
