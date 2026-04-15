import MEGAAnalyticsiOS
import MEGAAppPresentation
import Search

extension AppDelegate {
    @objc func injectSearchDependencies() {
        Search.DIContainer.searchTracker = SearchAnalyticsTracker()
    }
}

struct SearchAnalyticsTracker: SearchAnalyticsTracking {
    private let tracker: any AnalyticsTracking

    init(tracker: any AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }

    func trackChipTapped(_ chip: SearchChipEntity, selected: Bool) {
        if selected, let event = chip.analyticsEvent {
            tracker.trackAnalyticsEvent(with: event)
        } else {
            tracker.trackAnalyticsEvent(with: SearchResetFilterPressedEvent())
        }
    }

    func trackChipPickerShow(_ chip: SearchChipEntity) {
        guard let event = chip.analyticsEvent else { return }
        tracker.trackAnalyticsEvent(with: event)
    }

    func trackResultContextMenuTapped() {
        tracker.trackAnalyticsEvent(with: CloudDriveChildNodeMoreButtonPressedEvent())
    }
}

extension SearchChipEntity {
    var analyticsEvent: (any EventIdentifier)? {
        switch id {
        case SearchChipEntity.images.id: SearchImageFilterPressedEvent()
        case SearchChipEntity.docs.id: SearchDocsFilterPressedEvent()
        case SearchChipEntity.audio.id: SearchAudioFilterPressedEvent()
        case SearchChipEntity.video.id: SearchVideosFilterPressedEvent()
        case SearchChipEntity.nodeFormatsGroupChipId: SearchFileTypeDropdownChipPressedEvent()
        case SearchChipEntity.timeFilterGroupChipId: SearchLastModifiedDropdownChipPressedEvent()
        case SearchChipEntity.last7DaysChipId: SearchLastModifiedLastSevenDaysClickedEvent()
        case SearchChipEntity.last30DaysChipId: SearchLastModifiedLastThirtyDaysClickedEvent()
        case SearchChipEntity.thisYearChipId: SearchLastModifiedThisYearClickedEvent()
        case SearchChipEntity.lastYearChipId: SearchLastModifiedLastYearClickedEvent()
        case SearchChipEntity.olderChipId: SearchLastModifiedOlderClickedEvent()
        default: nil
        }
    }
}
