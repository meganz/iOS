import MEGAAnalyticsiOS
import MEGAAppPresentation

extension AnalyticsTracking {
    func trackTabSelectedEvent(for tab: MediaTab) {
        let event: any EventIdentifier = switch tab {
        case .timeline: MediaScreenTimelineTabEvent()
        case .album: MediaScreenAlbumsTabEvent()
        case .video: MediaScreenVideosTabEvent()
        case .playlist: MediaScreenPlaylistsTabEvent()
        }
        trackAnalyticsEvent(with: event)
    }
}
