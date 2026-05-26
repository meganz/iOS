import ActivityKit
import Combine
import Foundation
import Testing
@testable import Transfer

@MainActor
struct TransferLiveActivityManagerTests {

    // MARK: - Starting an activity (staleDate per state)

    @Test
    func firstActiveSnapshot_callsRequestWithStaleDateApproximatelyNowPlus8Seconds() async throws {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        let before = Date()
        env.subject.send(.fixture())
        await waitForTasks()
        let after = Date()

        #expect(env.provider.requestCalls.count == 1)
        let call = try #require(env.provider.requestCalls.first)
        let staleDate = try #require(call.staleDate)
        #expect(staleDate.timeIntervalSince(before) >= 8.0 - 0.5)
        #expect(staleDate.timeIntervalSince(after) <= 8.0 + 0.5)
    }

    @Test
    func firstPausedSnapshot_callsRequestWithNilStaleDate() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(isPaused: true))
        await waitForTasks()

        #expect(env.provider.requestCalls.count == 1)
        #expect(env.provider.requestCalls.first?.staleDate == nil)
        #expect(env.provider.requestCalls.first?.state.state == .paused)
    }

    @Test
    func firstErrorSnapshot_callsRequestWithNilStaleDate() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(hasError: true))
        await waitForTasks()

        #expect(env.provider.requestCalls.first?.staleDate == nil)
        #expect(env.provider.requestCalls.first?.state.state == .error)
    }

    @Test
    func firstOverquotaSnapshot_callsRequestWithNilStaleDate() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(hasOverquota: true))
        await waitForTasks()

        #expect(env.provider.requestCalls.first?.staleDate == nil)
        #expect(env.provider.requestCalls.first?.state.state == .overquota)
    }

    @Test
    func firstCompletedSnapshot_doesNotStartActivity() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(isCompleted: true))
        await waitForTasks()

        #expect(env.provider.requestCalls.isEmpty)
        #expect(env.provider.updateCalls.isEmpty)
        #expect(env.provider.endCalls.isEmpty)
    }

    // MARK: - Start guards

    @Test
    func activitiesNotEnabled_skipsRequest() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.provider.areActivitiesEnabled = false
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture())
        await waitForTasks()

        #expect(env.provider.requestCalls.isEmpty)
    }

    @Test
    func hasActiveActivityFromSystem_skipsRequest() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.provider.hasActiveActivity = true
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture())
        await waitForTasks()

        #expect(env.provider.requestCalls.isEmpty)
    }

    // MARK: - Adoption

    @Test
    func startMonitoringWithExistingActivityId_adoptsAndDoesNotCallRequest() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.provider.activeActivityId = "already-running"
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture())
        await waitForTasks()

        // Adopted id is reused: no new request, but updates flow to the adopted id.
        #expect(env.provider.requestCalls.isEmpty)
        #expect(env.provider.updateCalls.first?.activityId == "already-running")
    }

    // MARK: - Throttling

    @Test
    func sameStateSnapshotWithinThrottleWindow_doesNotPushExtraUpdate() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(progress: 0.5))
        await waitForTasks()
        let updatesAfterFirst = env.provider.updateCalls.count

        env.subject.send(.fixture(progress: 0.51))
        await waitForTasks()

        #expect(env.provider.updateCalls.count == updatesAfterFirst)
    }

    @Test
    func stateChangeSnapshot_pushesUpdateImmediately() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(progress: 0.5))
        await waitForTasks()
        let updatesAfterFirst = env.provider.updateCalls.count

        env.subject.send(.fixture(progress: 0.5, isPaused: true))
        await waitForTasks()

        #expect(env.provider.updateCalls.count == updatesAfterFirst + 1)
        #expect(env.provider.updateCalls.last?.state.state == .paused)
    }

    // MARK: - Ending

    @Test
    func nilSnapshotAfterActive_doesNotCallEndImmediately() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture())
        await waitForTasks()

        env.subject.send(nil)
        await waitForTasks()

        // scheduleEndActivity sleeps 6 s before calling end; within waitForTasks no end fires.
        #expect(env.provider.endCalls.isEmpty)
    }

    @Test
    func stopMonitoring_callsEndImmediatelyWithZeroDismissInterval() async throws {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture())
        await waitForTasks()

        env.sut.stopMonitoring()
        await waitForTasks()

        #expect(env.provider.endCalls.count == 1)
        let call = try #require(env.provider.endCalls.first)
        #expect(call.dismissTimeInterval == 0)
    }

    // MARK: - External end events

    @Test
    func dismissedStateUpdate_resetsManagerSoNextSnapshotStartsFreshActivity() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture())
        await waitForTasks()
        #expect(env.provider.requestCalls.count == 1)

        env.provider.emitActivityState(.dismissed)
        await waitForTasks()

        env.subject.send(.fixture())
        await waitForTasks()

        #expect(env.provider.requestCalls.count == 2)
    }

    @Test
    func endedStateUpdate_resetsManagerSoNextSnapshotStartsFreshActivity() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture())
        await waitForTasks()
        #expect(env.provider.requestCalls.count == 1)

        env.provider.emitActivityState(.ended)
        await waitForTasks()

        env.subject.send(.fixture())
        await waitForTasks()

        #expect(env.provider.requestCalls.count == 2)
    }

    // MARK: - Mapping (observed via captured request/update state)

    @Test
    func uploadOnlySnapshot_setsDirectionUploading() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(activeUploadCount: 2, activeDownloadCount: 0))
        await waitForTasks()

        #expect(env.provider.requestCalls.first?.state.direction == .uploading)
    }

    @Test
    func downloadOnlySnapshot_setsDirectionDownloading() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(activeUploadCount: 0, activeDownloadCount: 3))
        await waitForTasks()

        #expect(env.provider.requestCalls.first?.state.direction == .downloading)
    }

    @Test
    func mixedSnapshot_setsDirectionMixed() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(activeUploadCount: 1, activeDownloadCount: 1))
        await waitForTasks()

        #expect(env.provider.requestCalls.first?.state.direction == .mixed)
    }

    @Test
    func zeroActiveCounts_setsDirectionNil() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(activeUploadCount: 0, activeDownloadCount: 0))
        await waitForTasks()

        #expect(env.provider.requestCalls.first?.state.direction == nil)
    }

    @Test(arguments: [
        (0.0, "0%"),
        (0.5, "50%"),
        (0.99, "99%"),
        (0.999, "99%"),
        (1.0, "100%")
    ])
    func percentageText_clampsAt99UntilProgressReachesOne(progress: Double, expected: String) async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(progress: progress))
        await waitForTasks()

        #expect(env.provider.requestCalls.first?.state.percentageText == expected)
    }

    @Test
    func pausedSnapshot_hasEmptyFormattedSpeed() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture(isPaused: true, speedBytesPerSecond: 5_000_000))
        await waitForTasks()

        #expect(env.provider.requestCalls.first?.state.formattedSpeed == "")
    }

    // MARK: - Race / lifecycle / recovery

    @Test
    func rapidSnapshots_onlyRequestOnce() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        for _ in 0..<20 {
            env.subject.send(.fixture())
        }
        await waitForTasks()

        #expect(env.provider.requestCalls.count == 1)
    }

    @Test
    func startMonitoringAfterStop_createsNewActivity() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())
        env.subject.send(.fixture())
        await waitForTasks()

        env.sut.stopMonitoring()
        await waitForTasks()

        // `stopMonitoring` cancels the Combine subscription, so a fresh
        // `startMonitoring` is needed before the next snapshot can reach the manager.
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())
        env.subject.send(.fixture())
        await waitForTasks()

        #expect(env.provider.requestCalls.count == 2)
    }

    @Test
    func requestFailure_nextSnapshotRetriesRequest() async {
        guard #available(iOS 16.2, *) else { return }
        enum TestError: Error { case failed }

        let env = makeSUT()
        env.provider.requestError = TestError.failed
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture())
        await waitForTasks()
        #expect(env.provider.requestCalls.isEmpty)

        env.provider.requestError = nil
        env.subject.send(.fixture())
        await waitForTasks()

        #expect(env.provider.requestCalls.count == 1)
    }

    @Test
    func updateAfterActiveStateRestoration_carriesFutureStaleDate() async throws {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture())                          // .active → request (8 s) + update
        await waitForTasks()

        env.subject.send(.fixture(progress: 0.8, isPaused: true))  // .paused → update (nil staleDate)
        await waitForTasks()

        let before = Date()
        env.subject.send(.fixture(progress: 0.9))             // back to .active → update (8 s)
        await waitForTasks()

        let staleDate = try #require(env.provider.updateCalls.last?.staleDate)
        #expect(staleDate.timeIntervalSince(before) >= 8.0 - 0.5)
    }

    @Test
    func completedSnapshotAfterActive_pushesCompletedUpdateAndSchedulesEnd() async {
        guard #available(iOS 16.2, *) else { return }
        let env = makeSUT()
        env.sut.startMonitoring(snapshotPublisher: env.subject.eraseToAnyPublisher())

        env.subject.send(.fixture())
        await waitForTasks()
        let updatesBeforeCompletion = env.provider.updateCalls.count

        env.subject.send(.fixture(isCompleted: true))
        await waitForTasks()

        #expect(env.provider.updateCalls.count == updatesBeforeCompletion + 1)
        #expect(env.provider.updateCalls.last?.state.state == .completed)
        // `scheduleEndActivity` sleeps 6 s before calling `end`; no end fires within waitForTasks.
        #expect(env.provider.endCalls.isEmpty)
    }

    // MARK: - Helpers

    @available(iOS 16.2, *)
    private struct SUT {
        let sut: TransferLiveActivityManager
        let provider: MockTransferLiveActivityProviding
        let subject: PassthroughSubject<TransferStatusSnapshot?, Never>
    }

    @available(iOS 16.2, *)
    private func makeSUT() -> SUT {
        let provider = MockTransferLiveActivityProviding()
        let manager = TransferLiveActivityManager(activityProvider: provider)
        let subject = PassthroughSubject<TransferStatusSnapshot?, Never>()
        return SUT(sut: manager, provider: provider, subject: subject)
    }

    private func waitForTasks() async {
        for _ in 0..<10 {
            await Task.yield()
        }
    }
}
