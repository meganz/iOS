import MEGAAnalyticsiOS
import MEGAPresentation
import XCTest

final class MockTracker: AnalyticsTracking {
    private(set) var trackedEventIdentifiers: [EventIdentifier] = []

    init() {}

    func trackAnalyticsEvent(with eventIdentifier: EventIdentifier) {
        trackedEventIdentifiers.append(eventIdentifier)
    }

    func assertTrackAnalyticsEventCalled(
        with expectedEventIdentifiers: [EventIdentifier],
        file: StaticString = #file, line: UInt = #line
    ) {
        XCTAssertEqual(
            trackedEventIdentifiers.count,
            expectedEventIdentifiers.count,
            file: file, line: line
        )

        for (tracked, expected) in zip(expectedEventIdentifiers, trackedEventIdentifiers) {
            XCTAssertEqual(
                tracked.stringValue,
                expected.stringValue,
                file: file, line: line
            )
        }
    }
}

private extension EventIdentifier {
    var stringValue: String {
        String(describing: type(of: self))
    }
}
