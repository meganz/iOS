@testable import MEGA
import MEGAAppSDKRepoMock
import MEGATest
import XCTest

final class AudioPlayerDefaultPlaylistShiftStrategyTests: XCTestCase, AudioPlayerPlaylistShiftStrategyTestSpecs {
    
    func testShift_whenHasNoTracks_returnsEmptyTracks() {
        let startItem = AudioPlayerItem(name: "name-1", url: anyURL(), node: anyNode())
        let sut = AudioPlayerDefaultPlaylistShiftStrategy()
        
        let result = sut.shift(tracks: [], startItem: startItem)
        
        XCTAssertEqual(result, [])
    }
    
    func testShift_whenHasSingleTrack_returnsStartItem() {
        let playerItem = AudioPlayerItem(name: "name-1", url: anyURL(), node: anyNode())
        let sut = AudioPlayerDefaultPlaylistShiftStrategy()
        
        let result = sut.shift(tracks: [playerItem], startItem: playerItem)
        
        XCTAssertEqual(result, [playerItem])
    }
    
    func testShift_whenHasMoreThanOneTracks_returnsCorrectOrderTracks() {
        let playerItem1 = AudioPlayerItem(name: "name-1", url: anyURL(), node: anyNode())
        let playerItem2 = AudioPlayerItem(name: "name-2", url: anyURL(), node: anyNode())
        let playerItem3 = AudioPlayerItem(name: "name-3", url: anyURL(), node: anyNode())
        let sut = AudioPlayerDefaultPlaylistShiftStrategy()
        
        let result = sut.shift(tracks: [playerItem1, playerItem2, playerItem3], startItem: playerItem3)
        
        XCTAssertEqual(result, [playerItem3, playerItem1, playerItem2])
    }
    
    // MARK: - Helpers
    
    private func anyURL() -> URL {
        URL(string: "https://some-file-link.com")!
    }
    
    private func anyNode() -> MockNode {
        MockNode(handle: 1)
    }

}
