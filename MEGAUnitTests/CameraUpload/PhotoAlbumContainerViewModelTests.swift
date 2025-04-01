@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGATest
import Testing

@Suite("PhotoAlbumContainerViewModel Tests")
struct PhotoAlbumContainerViewModelTests {
    @Suite
    @MainActor
    struct ViewAppear {
        @Test("on appear should track photo screen event")
        func trackPhotoScreenViewEvent() {
            let tracker = MockTracker()
            let sut = makeSUT(tracker: tracker)
            
            sut.didAppear()
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [PhotoScreenEvent()]
            )
        }
    }
    
    @Suite("Share link")
    @MainActor
    struct ShareLink {
        @Test("share links tapped analytics tracked and show share link")
        func showAlbumLinks() {
            let tracker = MockTracker()
            let sut = makeSUT(tracker: tracker)
            
            sut.shareLinksTapped()
            
            #expect(sut.showShareAlbumLinks)
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [AlbumListShareLinkMenuItemEvent()]
            )
        }
        
        @Test("when account is paywalled should show over disk quota")
        func paywalled() {
            let tracker = MockTracker()
            let overDiskQuotaChecker = MockOverDiskQuotaChecker(isPaywalled: true)
            let sut = makeSUT(
                tracker: tracker,
                overDiskQuotaChecker: overDiskQuotaChecker
            )
            
            sut.shareLinksTapped()
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [AlbumListShareLinkMenuItemEvent()]
            )
            #expect(sut.showShareAlbumLinks == false)
        }
    }
    
    @Suite("Remove Link")
    @MainActor
    struct RemoveLink {
        @Test(arguments: [true, false])
        func overDisQuota(isPaywalled: Bool) {
            let overDiskQuotaChecker = MockOverDiskQuotaChecker(isPaywalled: isPaywalled)
            let sut = makeSUT(
                overDiskQuotaChecker: overDiskQuotaChecker
            )
            
            sut.removeLinksTapped()
            
            #expect(sut.showRemoveAlbumLinksAlert == !isPaywalled)
        }
    }
    
    @Suite("Delete Albums")
    @MainActor
    struct DeleteAlbums {
        @Test("when paywalled remove albums action should be blocked",
            arguments: [true, false])
        func overDisQuota(isPaywalled: Bool) {
            let overDiskQuotaChecker = MockOverDiskQuotaChecker(isPaywalled: isPaywalled)
            let sut = makeSUT(
                overDiskQuotaChecker: overDiskQuotaChecker
            )
            
            sut.deleteAlbumsTapped()
            
            #expect(sut.showDeleteAlbumAlert == !isPaywalled)
        }
    }
    
    @Test
    @MainActor
    func testShowToolbar_onEditModeUpdate_shouldChange() {
        let sut = PhotoAlbumContainerViewModelTests.makeSUT()
        #expect(sut.showToolbar == false)
        
        sut.editMode = .active
        #expect(sut.showToolbar)
        
        sut.editMode = .inactive
        #expect(sut.showToolbar == false)
    }
    
    @MainActor
    private static func makeSUT(
        tracker: some AnalyticsTracking = MockTracker(),
        overDiskQuotaChecker: some OverDiskQuotaChecking = MockOverDiskQuotaChecker()
    ) -> PhotoAlbumContainerViewModel {
        .init(
            tracker: tracker,
            overDiskQuotaChecker: overDiskQuotaChecker)
    }
}
