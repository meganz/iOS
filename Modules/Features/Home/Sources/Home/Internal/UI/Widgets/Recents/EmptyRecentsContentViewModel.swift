import MEGAAnalyticsiOS
import MEGAAppPresentation

struct EmptyRecentsContentViewModel {
    private let tracker: any AnalyticsTracking

    init() {
        self.init(tracker: DIContainer.tracker)
    }

    package init(tracker: some AnalyticsTracking) {
        self.tracker = tracker
    }

    func trackUploadButtonTapped() {
        tracker.trackAnalyticsEvent(with: RecentsEmptyStateUploadButtonPressedEvent())
    }
}
