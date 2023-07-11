import MEGAAnalyticsiOS

public protocol AnalyticsTracking {
    func trackAnalyticsEvent(with eventIdentifier: any EventIdentifier)
}

extension Tracker: AnalyticsTracking {
    public func trackAnalyticsEvent(with eventIdentifier: any EventIdentifier) {
        trackEvent(eventIdentifier: eventIdentifier)
    }
}
