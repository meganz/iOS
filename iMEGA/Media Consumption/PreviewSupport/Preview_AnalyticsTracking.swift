import MEGAAnalyticsiOS
import MEGAPresentation

struct Preview_AnalyticsTracking: AnalyticsTracking {
    func trackAnalyticsEvent(with eventIdentifier: any EventIdentifier) {
        
    }
}

final class Preview_ScreenEvent: ScreenViewEventIdentifier {
    let eventName: String = "Preview"
    let uniqueIdentifier: Int32 = 1
    let screenName: String = "Preview"
}
