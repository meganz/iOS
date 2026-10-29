@testable import MEGA
import Testing

struct CameraUploadRetrySchedulerTests {
    private final class Lookups {
        var failedRecord = 0
        var runningRetryCount = 0
    }

    private let new = "never failed"
    private let retry = "failed"

    private func picks(
        _ sut: CameraUploadRetryScheduler,
        count: Int,
        neverFailedRecord: String? = "never failed",
        failedRecord: String? = "failed",
        failureCount: Int = 0,
        runningRetryCount: Int = 0,
        concurrentCount: Int = 4,
        lookups: Lookups = Lookups()
    ) -> [String?] {
        (0..<count).map { _ in
            sut.nextRecord(
                neverFailedRecord: neverFailedRecord,
                concurrentCount: concurrentCount,
                failedRecord: {
                    lookups.failedRecord += 1
                    return failedRecord
                },
                failureCount: { _ in failureCount },
                runningRetryCount: {
                    lookups.runningRetryCount += 1
                    return runningRetryCount
                }
            ) as? String
        }
    }

    // MARK: - Spacing

    @Test func servesRetryAfterBaseIntervalNewRecordsWhenNotFailedInThisLaunch() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)

        #expect(picks(sut, count: 8) == [new, new, new, retry, new, new, new, retry])
    }

    @Test(arguments: [(1, 6), (2, 12), (3, 24)])
    func doublesIntervalPerFailureInThisLaunch(failureCount: Int, expectedInterval: Int) {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)

        let expected = Array(repeating: new, count: expectedInterval) + [retry]
        #expect(picks(sut, count: expectedInterval + 1, failureCount: failureCount) == expected)
    }

    @Test func intervalRestartsAfterServingRetry() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)
        _ = picks(sut, count: 7, failureCount: 1)

        #expect(picks(sut, count: 4) == [new, new, new, retry])
    }

    @Test func defaultBaseIntervalIsThree() {
        let sut = CameraUploadRetryScheduler()

        #expect(picks(sut, count: 4) == [new, new, new, retry])
    }

    @Test func hugeFailureCountDoesNotOverflow() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)

        #expect(picks(sut, count: 10, failureCount: .max).allSatisfy { $0 == new })
    }

    @Test func negativeFailureCountIsTreatedAsZero() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)

        #expect(picks(sut, count: 4, failureCount: -1) == [new, new, new, retry])
    }

    // MARK: - Running retries

    @Test func doesNotServeRetryWhileOneIsRunning() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)

        #expect(picks(sut, count: 10, runningRetryCount: 1).allSatisfy { $0 == new })
    }

    @Test(arguments: [1, 0, -1])
    func doesNotLookForRetryWithoutASpareSlot(concurrentCount: Int) {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)
        let lookups = Lookups()

        #expect(picks(sut, count: 10, concurrentCount: concurrentCount, lookups: lookups).allSatisfy { $0 == new })
        #expect(lookups.failedRecord == 0)
        #expect(lookups.runningRetryCount == 0)
    }

    @Test func servesRetryWithinBaseIntervalAfterRunningRetryFinishes() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)
        _ = picks(sut, count: 5, runningRetryCount: 1)

        #expect(picks(sut, count: 2) == [new, retry])
    }

    // MARK: - Lanes

    @Test func servesFailedRecordsWhenNoRecordNeverFailed() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)

        #expect(picks(sut, count: 3, neverFailedRecord: nil, runningRetryCount: 1) == [retry, retry, retry])
    }

    @Test func servesNeverFailedRecordsWhenNoRecordFailed() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)

        #expect(picks(sut, count: 8, failedRecord: nil).allSatisfy { $0 == new })
    }

    @Test func servesNothingWhenBothLanesAreEmpty() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)

        #expect(picks(sut, count: 1, neverFailedRecord: nil, failedRecord: nil) == [nil])
    }

    // MARK: - Lookups

    @Test func looksUpNothingBeforeBaseInterval() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)
        let lookups = Lookups()

        _ = picks(sut, count: 3, lookups: lookups)

        #expect(lookups.failedRecord == 0)
        #expect(lookups.runningRetryCount == 0)
    }

    @Test func looksUpEmptyFailedLaneOncePerBaseInterval() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)
        let lookups = Lookups()

        _ = picks(sut, count: 9, failedRecord: nil, lookups: lookups)

        #expect(lookups.failedRecord == 2)
        #expect(lookups.runningRetryCount == 0)
    }

    @Test func waitsForCandidateIntervalBeforeLookingUpAgain() {
        let sut = CameraUploadRetryScheduler(baseInterval: 3)
        let lookups = Lookups()

        _ = picks(sut, count: 12, failureCount: 2, lookups: lookups)

        #expect(lookups.failedRecord == 1)
        #expect(lookups.runningRetryCount == 0)
    }
}
