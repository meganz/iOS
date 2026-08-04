import MEGAAnalyticsiOS

public struct NoOpAnalyticsTracker: AnalyticsTracking {
    public init() {}

    public func trackAnalyticsEvent(with eventIdentifier: any EventIdentifier) {
        print("[NoOpAnalyticsTracker]", eventIdentifier)
    }
}
