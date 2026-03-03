import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import NodeBackgroundDownloader
import Testing

@Suite("BGTaskAnalyticsUseCase Tests")
struct BGTaskAnalyticsUseCaseTests {

    // MARK: - Task Completed

    @Test("trackTaskCompleted sends completed event and duration bucket")
    func trackTaskCompleted() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackTaskCompleted(durationSeconds: 30)

        assertTrackedEvents(
            tracker,
            expectedTypes: [BGTaskCompletedEvent.self, BGTaskDurationUnder1MinEvent.self]
        )
    }

    // MARK: - Task Expired

    @Test("trackTaskExpired sends expired event, duration, progress, and app state")
    func trackTaskExpired() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackTaskExpired(
            durationSeconds: 120,
            completionPercentage: 40,
            appState: .background
        )

        assertTrackedEvents(
            tracker,
            expectedTypes: [
                BGTaskExpiredEvent.self,
                BGTaskDurationUnder5MinEvent.self,
                BGTaskProgressAtExpirationUnder50Event.self,
                BGTaskExpiredWhileAppBackgroundEvent.self
            ]
        )
    }

    @Test("trackTaskExpired with active app state sends active event")
    func trackTaskExpiredWhileActive() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackTaskExpired(
            durationSeconds: 5,
            completionPercentage: 80,
            appState: .active
        )

        assertTrackedEvents(
            tracker,
            expectedTypes: [
                BGTaskExpiredEvent.self,
                BGTaskDurationUnder1MinEvent.self,
                BGTaskProgressAtExpirationOver75Event.self,
                BGTaskExpiredWhileAppActiveEvent.self
            ]
        )
    }

    // MARK: - Duration Bucketing

    @Test("Duration under 1 min")
    func durationUnder1Min() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackTaskCompleted(durationSeconds: 30)

        let hasExpectedDurationEvent = tracker.trackedEventIdentifiers.contains {
            type(of: $0) == BGTaskDurationUnder1MinEvent.self
        }
        #expect(hasExpectedDurationEvent, "Expected duration event for 30s")
    }

    @Test("Duration under 5 min")
    func durationUnder5Min() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackTaskCompleted(durationSeconds: 120)

        let hasExpectedDurationEvent = tracker.trackedEventIdentifiers.contains {
            type(of: $0) == BGTaskDurationUnder5MinEvent.self
        }
        #expect(hasExpectedDurationEvent, "Expected duration event for 120s")
    }

    @Test("Duration under 10 min")
    func durationUnder10Min() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackTaskCompleted(durationSeconds: 400)

        let hasExpectedDurationEvent = tracker.trackedEventIdentifiers.contains {
            type(of: $0) == BGTaskDurationUnder10MinEvent.self
        }
        #expect(hasExpectedDurationEvent, "Expected duration event for 400s")
    }

    @Test("Duration over 10 min")
    func durationOver10Min() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackTaskCompleted(durationSeconds: 700)

        let hasExpectedDurationEvent = tracker.trackedEventIdentifiers.contains {
            type(of: $0) == BGTaskDurationOver10MinEvent.self
        }
        #expect(hasExpectedDurationEvent, "Expected duration event for 700s")
    }

    // MARK: - Progress Bucketing

    @Test("Progress under 25%")
    func progressUnder25() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackTaskExpired(
            durationSeconds: 10,
            completionPercentage: 10,
            appState: .background
        )

        let hasExpectedProgressEvent = tracker.trackedEventIdentifiers.contains {
            type(of: $0) == BGTaskProgressAtExpirationUnder25Event.self
        }
        #expect(hasExpectedProgressEvent, "Expected progress event for 10%")
    }

    @Test("Progress under 50%")
    func progressUnder50() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackTaskExpired(
            durationSeconds: 10,
            completionPercentage: 30,
            appState: .background
        )

        let hasExpectedProgressEvent = tracker.trackedEventIdentifiers.contains {
            type(of: $0) == BGTaskProgressAtExpirationUnder50Event.self
        }
        #expect(hasExpectedProgressEvent, "Expected progress event for 30%")
    }

    @Test("Progress under 75%")
    func progressUnder75() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackTaskExpired(
            durationSeconds: 10,
            completionPercentage: 60,
            appState: .background
        )

        let hasExpectedProgressEvent = tracker.trackedEventIdentifiers.contains {
            type(of: $0) == BGTaskProgressAtExpirationUnder75Event.self
        }
        #expect(hasExpectedProgressEvent, "Expected progress event for 60%")
    }

    @Test("Progress over 75%")
    func progressOver75() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackTaskExpired(
            durationSeconds: 10,
            completionPercentage: 90,
            appState: .background
        )

        let hasExpectedProgressEvent = tracker.trackedEventIdentifiers.contains {
            type(of: $0) == BGTaskProgressAtExpirationOver75Event.self
        }
        #expect(hasExpectedProgressEvent, "Expected progress event for 90%")
    }

    // MARK: - Schedule Failure

    @Test("trackScheduleFailure with registerFailed sends register failed event")
    func scheduleFailureRegister() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackScheduleFailure(reason: .registerFailed)

        assertTrackedEvents(tracker, expectedTypes: [BGTaskScheduleFailedRegisterEvent.self])
    }

    @Test("trackScheduleFailure with submitFailed sends submit failed event")
    func scheduleFailureSubmit() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackScheduleFailure(reason: .submitFailed)

        assertTrackedEvents(tracker, expectedTypes: [BGTaskScheduleFailedSubmitEvent.self])
    }

    // MARK: - Scheduling Delay Bucketing

    @Test("Scheduling delay under 5s")
    func schedulingDelayUnder5s() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackSchedulingDelay(delaySeconds: 2)

        assertTrackedEvents(tracker, expectedTypes: [BGTaskSchedulingDelayUnder5sEvent.self])
    }

    @Test("Scheduling delay under 30s")
    func schedulingDelayUnder30s() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackSchedulingDelay(delaySeconds: 15)

        assertTrackedEvents(tracker, expectedTypes: [BGTaskSchedulingDelayUnder30sEvent.self])
    }

    @Test("Scheduling delay under 1 min")
    func schedulingDelayUnder1Min() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackSchedulingDelay(delaySeconds: 45)

        assertTrackedEvents(tracker, expectedTypes: [BGTaskSchedulingDelayUnder1MinEvent.self])
    }

    @Test("Scheduling delay over 1 min")
    func schedulingDelayOver1Min() {
        let tracker = MockTracker()
        let sut = BGTaskAnalyticsUseCase(tracker: tracker)

        sut.trackSchedulingDelay(delaySeconds: 120)

        assertTrackedEvents(tracker, expectedTypes: [BGTaskSchedulingDelayOver1MinEvent.self])
    }

    // MARK: - Helpers

    private func assertTrackedEvents(
        _ tracker: MockTracker,
        expectedTypes: [any EventIdentifier.Type],
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(
            tracker.trackedEventIdentifiers.count == expectedTypes.count,
            "Expected \(expectedTypes.count) events but got \(tracker.trackedEventIdentifiers.count)",
            sourceLocation: sourceLocation
        )
        for expectedType in expectedTypes {
            let found = tracker.trackedEventIdentifiers.contains {
                type(of: $0) == expectedType
            }
            #expect(found, "Expected event of type \(expectedType) not found", sourceLocation: sourceLocation)
        }
    }
}
