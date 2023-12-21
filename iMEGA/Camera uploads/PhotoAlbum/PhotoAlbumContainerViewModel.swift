import Combine
import MEGAPresentation
import SwiftUI

final class PhotoAlbumContainerViewModel: ObservableObject {
    @Published var editMode: EditMode = .inactive {
        willSet {
            showToolbar = newValue == .active
        }
    }
    @Published var shouldShowSelectBarButton = false
    @Published var isAlbumsSelected = false
    @Published var showDeleteAlbumAlert = false
    @Published var isExportedAlbumSelected: Bool = false
    @Published var isOnlyExportedAlbumsSelected = false 
    @Published var showShareAlbumLinks = false
    @Published var showRemoveAlbumLinksAlert = false
    @Published private(set) var showToolbar = false
    @Published var disableSelectBarButton = false
    
    private let tracker: any AnalyticsTracking
    
    init(tracker: some AnalyticsTracking) {
        self.tracker = tracker
    }
    
    func didAppear() {
        tracker.trackAnalyticsEvent(with: DIContainer.photoScreenEvent)
    }
    
    func shareLinksTapped() {
        showShareAlbumLinks = true
        tracker.trackAnalyticsEvent(with: DIContainer.albumListShareLinkMenuItemEvent)
    }
}
