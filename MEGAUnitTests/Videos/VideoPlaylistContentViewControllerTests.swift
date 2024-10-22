@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGATest
import Video
import XCTest

final class VideoPlaylistContentViewControllerTests: XCTestCase {
    
    // MARK: - quickActionsMenu
    
    func testQuickAction_whenCalled_setActionInSharedUIState() {
        let (sut, _) = makeSUT()
        
        sut.quickActionsMenu(didSelect: .rename, needToRefreshMenu: .random())
        
        XCTAssertEqual(sut.sharedUIState.selectedQuickActionEntity, .rename)
    }
    
    // MARK: - videoPlaylistMenuDelegate
    
    func testVideoPlaylistMenuDelegate_whenCalled_setActionInSharedUIState() {
        let (sut, _) = makeSUT()
        
        sut.videoPlaylistMenu(didSelect: .delete)
        
        XCTAssertEqual(sut.sharedUIState.selectedVideoPlaylistActionEntity, .delete)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: VideoPlaylistContentViewController, sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase) {
        let sortOrderPreferenceUseCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .defaultAsc)
        let videoSelection = VideoSelection()
        let sut = VideoPlaylistContentViewController(
            videoConfig: .live(),
            videoPlaylistEntity: anyVideoPlaylist(),
            videoPlaylistContentsUseCase: MockVideoPlaylistContentUseCase(),
            thumbnailUseCase: MockThumbnailUseCase(),
            videoPlaylistUseCase: MockVideoPlaylistUseCase(),
            videoPlaylistModificationUseCase: MockVideoPlaylistModificationUseCase(),
            nodeUseCase: MockNodeUseCase(),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            router: MockVideoRevampRouter(),
            presentationConfig: VideoPlaylistContentSnackBarPresentationConfig(shouldShowSnackBar: false, text: nil),
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            nodeIconUseCase: MockNodeIconUsecase(stubbedIconData: "any-data".data(using: .utf8)!),
            videoSelection: videoSelection,
            selectionAdapter: VideoPlaylistContentViewModelSelectionAdapter(selection: videoSelection),
            syncModel: VideoRevampSyncModel()
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, sortOrderPreferenceUseCase)
    }
    
    private func anyVideoPlaylist() -> VideoPlaylistEntity {
        VideoPlaylistEntity(setIdentifier: SetIdentifier(handle: 1), name: "Preview", count: 0, type: .user, creationTime: Date(), modificationTime: Date())
    }
    
}
