import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGASwift

public final class MockTracker: AnalyticsTracking, @unchecked Sendable {
    @Atomic public var trackedEventIdentifiers: [any EventIdentifier] = []
    
    public init() {}
    
    public func trackAnalyticsEvent(with eventIdentifier: any EventIdentifier) {
        $trackedEventIdentifiers.mutate { $0.append(eventIdentifier) }
    }
    
    public func reset() {
        $trackedEventIdentifiers.mutate { $0 = [] }
    }
}
