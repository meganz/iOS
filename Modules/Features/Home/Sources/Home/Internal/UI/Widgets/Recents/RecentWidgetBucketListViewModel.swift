import MEGAAnalyticsiOS
import MEGAAppPresentation

struct RecentWidgetBucketListViewModel {
    private let tracker: any AnalyticsTracking

    init() {
        self.init(tracker: DIContainer.tracker)
    }

    package init(tracker: some AnalyticsTracking) {
        self.tracker = tracker
    }

    func trackViewAllTapped() {
        tracker.trackAnalyticsEvent(with: RecentsViewAllButtonPressedEvent())
    }
}
