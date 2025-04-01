import Combine
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAL10n

enum PhotoLibraryTab: CaseIterable {
    case timeline
    case album
    
    var index: Int {
        switch self {
        case.timeline: return 0
        case.album: return 1
        }
    }
    
    var eventIdentifier: any TabSelectedEventIdentifier {
        switch self {
        case .timeline: return DIContainer.timelineEvent
        case .album: return DIContainer.albumEvent
        }
    }
}

final class PagerTabViewModel: ObservableObject {
    @Published var tabOffset: CGFloat = 0
    @Published var selectedTab = PhotoLibraryTab.timeline {
        didSet {
            guard selectedTab != oldValue else { return }
            
            trackCurrentTab()
        }
    }
    @Published var isEditing = false
    
    var timeLineTitle = Strings.Localizable.CameraUploads.Timeline.title
    var albumsTitle = Strings.Localizable.CameraUploads.Albums.title
    
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking) {
        self.tracker = tracker
    }
    
    func didAppear() {
        trackCurrentTab()
    }
    
    private func trackCurrentTab() {
        tracker.trackAnalyticsEvent(with: selectedTab.eventIdentifier)
    }
}
