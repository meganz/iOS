import MEGAAnalyticsiOS

/// Use this where analytics events should not actually be sent, such as previews, QA settings
public struct NoOpAnalyticsTracker: AnalyticsTracking {
    public init() {}

    public func trackAnalyticsEvent(with eventIdentifier: any EventIdentifier) {}
}
