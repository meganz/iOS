import MEGAAnalyticsiOS
import MEGAPresentation
import MEGASwift

public final class MockTracker: AnalyticsTracking, @unchecked Sendable {
    @Atomic public var trackedEventIdentifiers: [EventIdentifier] = []
    
    public init() {}
    
    public func trackAnalyticsEvent(with eventIdentifier: EventIdentifier) {
        $trackedEventIdentifiers.mutate { $0.append(eventIdentifier) }
    }
}
