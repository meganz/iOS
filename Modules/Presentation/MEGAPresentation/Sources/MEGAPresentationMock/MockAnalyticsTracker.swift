import MEGAAnalyticsiOS
import MEGAPresentation

public final class MockTracker: AnalyticsTracking {
    private(set) public var trackedEventIdentifiers: [EventIdentifier] = []
    
    public init() {}
    
    public func trackAnalyticsEvent(with eventIdentifier: EventIdentifier) {
        trackedEventIdentifiers.append(eventIdentifier)
    }
}
