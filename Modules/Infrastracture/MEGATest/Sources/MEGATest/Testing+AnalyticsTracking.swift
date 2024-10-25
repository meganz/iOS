import MEGAAnalyticsiOS
import Testing

public extension Test {
    static func assertTrackAnalyticsEventCalled(
        trackedEventIdentifiers: [any EventIdentifier],
        with expectedEventIdentifiers: [any EventIdentifier],
        message: Comment? = nil
    ) {
        #expect(trackedEventIdentifiers.count == expectedEventIdentifiers.count, "Tracked event identifiers and expected event identifiers count is not equal")
        
        for (tracked, expected) in zip(expectedEventIdentifiers, trackedEventIdentifiers) {
            #expect(tracked.stringValue == expected.stringValue, message)
        }
    }
}

private extension EventIdentifier {
    var stringValue: String {
        String(describing: type(of: self))
    }
}
