import MEGAAnalyticsiOS
import MEGAAppPresentation

extension AnalyticsTracking {
    func trackMediaBottomToolbarAction(_ action: MediaBottomToolbarAction) {
        let event: (any EventIdentifier)? = switch action {
        case .shareLink, .manageLink: MediaScreenLinkButtonPressedEvent()
        case .download: MediaScreenDownloadButtonPressedEvent()
        case .sendToChat: MediaScreenRespondButtonPressedEvent()
        case .more: MediaScreenMoreButtonPressedEvent()
        case .moveToRubbishBin: MediaScreenTrashButtonPressedEvent()
        case .addToAlbum: MediaScreenAlbumAddItemsButtonPressedEvent()
        default: nil
        }
        guard let event else { return }
        trackAnalyticsEvent(with: event)
    }
}
