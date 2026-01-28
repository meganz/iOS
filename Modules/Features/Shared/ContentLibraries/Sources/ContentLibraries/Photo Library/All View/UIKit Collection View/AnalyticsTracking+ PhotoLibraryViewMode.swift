import MEGAAnalyticsiOS
import MEGAAppPresentation

extension AnalyticsTracking {
    func trackViewModeChange(_ viewMode: PhotoLibraryViewMode) {
        let event: any EventIdentifier = switch viewMode {
        case .year: MediaScreenYearsFilterSelectedEvent()
        case .month: MediaScreenMonthsFilterSelectedEvent()
        case .day: MediaScreenDaysFilterSelectedEvent()
        case .all: MediaScreenAllFilterSelectedEvent()
        }
        trackAnalyticsEvent(with: event)
    }
}
