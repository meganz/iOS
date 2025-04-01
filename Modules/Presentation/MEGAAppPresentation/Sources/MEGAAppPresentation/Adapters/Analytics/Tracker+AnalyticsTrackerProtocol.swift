import MEGAAnalyticsiOS

public protocol AnalyticsTracking: Sendable {
    func trackAnalyticsEvent(with eventIdentifier: any EventIdentifier)
}

extension Tracker: AnalyticsTracking, @unchecked @retroactive Sendable {
    public func trackAnalyticsEvent(with eventIdentifier: any EventIdentifier) {
        trackEvent(eventIdentifier: eventIdentifier)
    }
}
