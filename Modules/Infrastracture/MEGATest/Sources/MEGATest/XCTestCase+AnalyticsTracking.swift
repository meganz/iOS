import MEGAAnalyticsiOS
import XCTest

public extension XCTestCase {
    func assertTrackAnalyticsEventCalled(
        trackedEventIdentifiers: [EventIdentifier],
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
