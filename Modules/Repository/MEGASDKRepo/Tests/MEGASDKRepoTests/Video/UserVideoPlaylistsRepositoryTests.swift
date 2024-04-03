@testable import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class UserVideoPlaylistsRepositoryTests: XCTestCase {
    
    // MARK: - init
    
    func testInit_whenCalled_doesNotGetSets() async {
        let (_, sdk) = makeSUT()
        
        XCTAssertEqual(sdk.megaSetsCallCount, 0)
    }
    
    // MARK: - VideoPlaylists
    
    func testVideoPlaylists_whenCalled_getSets() async {
        let (sut, sdk) = makeSUT()
        
        _ = await sut.videoPlaylists()
        
        XCTAssertEqual(sdk.megaSetsCallCount, 1)
    }
    
    func testVideoPlaylists_whenCalledTwice_getSetsTwice() async {
        let (sut, sdk) = makeSUT()
        
        _ = await sut.videoPlaylists()
        _ = await sut.videoPlaylists()
        
        XCTAssertEqual(sdk.megaSetsCallCount, 2)
    }
    
    func testVideoPlaylists_whenHasNoPlaylists_deliversEmptyItems() async {
        let (sut, _) = makeSUT()
        
        let videoPlaylists = await sut.videoPlaylists()
        
        XCTAssertEqual(videoPlaylists, [], "Expect to have empty items")
    }
    
    func testVideoPlaylists_whenHasSets_deliversOnlyVideoPlaylists() async {
        let sets = [
            MockMEGASet(handle: 1, type: .invalid),
            MockMEGASet(handle: 2, type: .album),
            MockMEGASet(handle: 3, type: .playlist)
        ]
        let (sut, _) = makeSUT(megaSets: sets)
        
        let videoPlaylists = await sut.videoPlaylists()
        
        XCTAssertTrue(videoPlaylists.allSatisfy { $0.setType == .playlist }, "Should only contains playlist type only")
    }
    
    func testVideoPlaylists_whenHasMoreThanOnePlaylists_deliversNonEmptyItems() async {
        let sets = [
            MockMEGASet(handle: 1, type: .playlist),
            MockMEGASet(handle: 2, type: .playlist),
            MockMEGASet(handle: 3, type: .playlist)
        ]
        let (sut, _) = makeSUT(megaSets: sets)
        
        let videoPlaylists = await sut.videoPlaylists()
        
        XCTAssertEqual(videoPlaylists.count, sets.count, "should deliver more than one playlist")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        megaSets: [MockMEGASet] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: UserVideoPlaylistsRepository,
        sdk: MockSdk
    ) {
        let sdk = MockSdk(megaSets: megaSets)
        let sut = UserVideoPlaylistsRepository(sdk: sdk)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, sdk)
    }
}
