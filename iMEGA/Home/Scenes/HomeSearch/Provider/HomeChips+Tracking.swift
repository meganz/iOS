import MEGAAnalyticsiOS
import MEGAAppPresentation
import Search

extension AnalyticsTracking {
    func trackChip(tapped chip: SearchChipEntity, selected: Bool) {
        if selected, let event = chip.analyticsEvent {
            trackAnalyticsEvent(with: event)
        } else {
            trackAnalyticsEvent(with: SearchResetFilterPressedEvent())
        }
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
        default: nil
        }
    }
}
