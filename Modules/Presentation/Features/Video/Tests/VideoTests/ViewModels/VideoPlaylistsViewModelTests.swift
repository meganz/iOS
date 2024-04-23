import Combine
import MEGATest
@testable import Video
import XCTest

final class VideoPlaylistsViewModelTests: XCTestCase {
    
    func testInit_inInitialState() {
        let (sut, _) = makeSUT()
        
        XCTAssertFalse(sut.shouldShowAddNewPlaylistAlert)
        XCTAssertEqual(sut.playlistName, "")
    }
    
    func testInit_whenShouldShowAddNewPlaylistAlertChanged_shouldReflectChanges() {
        let (sut, syncModel) = makeSUT()
        
        XCTAssertFalse(sut.shouldShowAddNewPlaylistAlert)
        
        syncModel.shouldShowAddNewPlaylistAlert = true
        
        XCTAssertTrue(sut.shouldShowAddNewPlaylistAlert)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: VideoPlaylistsViewModel, syncModel: VideoRevampSyncModel) {
        let syncModel = VideoRevampSyncModel()
        let sut = VideoPlaylistsViewModel(syncModel: syncModel)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, syncModel)
    }
    
}
