import MEGAAnalyticsiOS
import MEGAAppPresentation

struct ShortcutsWidgetViewModel {
    private let tracker: any AnalyticsTracking

    init() {
        self.init(tracker: DIContainer.tracker)
    }

    package init(tracker: some AnalyticsTracking) {
        self.tracker = tracker
    }

    func trackShortcutTapped(_ type: ShortcutType) {
        tracker.trackAnalyticsEvent(with: type.analyticsEvent)
    }
}

private extension ShortcutType {
    var analyticsEvent: any EventIdentifier {
        switch self {
        case .favourites:
            FavouritesChipButtonPressedEvent()
        case .audios:
            AudioChipButtonPressedEvent()
        case .offline:
            OfflineChipButtonPressedEvent()
        }
    }
}
