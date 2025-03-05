import Combine
import MEGADomain
import MEGAPresentation
import SwiftUI

@MainActor
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
    private let overDiskQuotaChecker: any OverDiskQuotaChecking
    
    init(
        tracker: some AnalyticsTracking,
        overDiskQuotaChecker: some OverDiskQuotaChecking
    ) {
        self.tracker = tracker
        self.overDiskQuotaChecker = overDiskQuotaChecker
    }
    
    func didAppear() {
        tracker.trackAnalyticsEvent(with: DIContainer.photoScreenEvent)
    }
    
    func shareLinksTapped() {
        tracker.trackAnalyticsEvent(with: DIContainer.albumListShareLinkMenuItemEvent)
        guard !overDiskQuotaChecker.showOverDiskQuotaIfNeeded() else { return }
        showShareAlbumLinks = true
    }
    
    func removeLinksTapped() {
        guard !overDiskQuotaChecker.showOverDiskQuotaIfNeeded() else { return }
        showRemoveAlbumLinksAlert.toggle()
    }
    
    func deleteAlbumsTapped() {
        guard !overDiskQuotaChecker.showOverDiskQuotaIfNeeded() else { return }
        showDeleteAlbumAlert.toggle()
    }
}
