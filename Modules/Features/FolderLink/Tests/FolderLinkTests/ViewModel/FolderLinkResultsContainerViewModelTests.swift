import MEGADomain
import FolderLink
import Search
import XCTest

@MainActor
final class FolderLinkResultsContainerViewModelTests: XCTestCase {
    private func makeSUT(
        handle: HandleEntity = 0,
        viewModeUseCase: MockFolderLinkViewModeUseCase = MockFolderLinkViewModeUseCase(),
        trackingUseCase: MockFolderLinkTrackingUseCase = MockFolderLinkTrackingUseCase(),
        ) -> FolderLinkResultsContainerViewModel {
        let dependency = FolderLinkResultsContainerViewModel.Dependency(
            handle: handle,
            viewModeUseCase: viewModeUseCase,
            trackingUseCase: trackingUseCase
        )
        return FolderLinkResultsContainerViewModel(dependency:dependency)
    }
    
    func testInitialViewMode() {
        // Given
        let viewMode: SearchResultsViewMode = .list
        let viewModeUseCase = MockFolderLinkViewModeUseCase(viewMode: viewMode)
        let handle: HandleEntity = 1
        
        // When
        let sut = makeSUT(handle: handle, viewModeUseCase: viewModeUseCase)
        
        // Then
        XCTAssertEqual(sut.viewMode, viewMode)
        XCTAssertEqual(viewModeUseCase.viewModeForOpeningFolderArgs, handle)
    }
    
    func testShowMediaDiscoveryUpdatesWhenViewModeChange() {
        func assertShouldShowMediaDiscovery(_ shouldShowMediaDiscovery: Bool, whenUpdate viewMode: SearchResultsViewMode) {
            // Given
            let viewModeUseCase = MockFolderLinkViewModeUseCase(viewMode: .list)
            let sut = makeSUT(viewModeUseCase: viewModeUseCase)
            
            // When
            sut.viewMode = viewMode
            
            // Then
            XCTAssertEqual(sut.showMediaDiscovery, shouldShowMediaDiscovery)
        }
        
        let testcases = [
            (false, SearchResultsViewMode.list),
            (false, SearchResultsViewMode.grid),
            (true, SearchResultsViewMode.mediaDiscovery)
        ]
        
        for (showMediaDiscovery, viewMode) in testcases {
            assertShouldShowMediaDiscovery(showMediaDiscovery, whenUpdate: viewMode)
        }
    }
    
    func testTrackViewModeChanged() {
        func assertTrackedViewMode(_ viewMode: SearchResultsViewMode) {
            // Given
            let trackingUseCase = MockFolderLinkTrackingUseCase()
            let sut = makeSUT(trackingUseCase: trackingUseCase)
            
            // When
            sut.viewMode = viewMode
            
            // Then
            XCTAssertEqual(trackingUseCase.trackedViewMode, viewMode)
        }
        
        for viewMode in [SearchResultsViewMode.list, .grid, .mediaDiscovery] {
            assertTrackedViewMode(viewMode)
        }
    }
}
