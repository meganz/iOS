import MEGAAnalyticsiOS
import MEGAAppPresentation

struct Preview_AnalyticsTracking: AnalyticsTracking {
    func trackAnalyticsEvent(with eventIdentifier: any EventIdentifier) {
        
    }
}

final class Preview_ScreenEvent: ScreenViewEventIdentifier {
    let eventName: String = "Preview"
    let uniqueIdentifier: Int32 = 1
    let screenName: String = "Preview"
}
final class Preview_ButtonPressedEvent: ButtonPressedEventIdentifier {
    let buttonName: String = "Button"
    let dialogName: String? = nil
    let screenName: String? = nil
    let eventName: String = "Preview_ButtonPressedEvent"
    let uniqueIdentifier: Int32 = 123
}
