@testable import MEGA
import MEGAAppSDKRepoMock
import MEGATest
import XCTest

final class AudioPlayerAllAudioAsPlaylistShiftStrategyTests: XCTestCase, AudioPlayerPlaylistShiftStrategyTestSpecs {
    
    func testShift_whenHasNoTracks_returnsEmptyTracks() {
        let startItem = AudioPlayerItem(name: "name-1", url: anyURL(), node: anyNode())
        let sut = AudioPlayerAllAudioAsPlaylistShiftStrategy()
        
        let result = sut.shift(tracks: [], startItem: startItem)
        
        XCTAssertEqual(result, [])
    }
    
    func testShift_whenHasSingleTrack_returnsStartItem() {
        let playerItem = AudioPlayerItem(name: "name-1", url: anyURL(), node: anyNode())
        let sut = AudioPlayerAllAudioAsPlaylistShiftStrategy()
        
        let result = sut.shift(tracks: [playerItem], startItem: playerItem)
        
        XCTAssertEqual(result, [playerItem])
    }
    
    func testShift_whenHasMoreThanOneTracks_returnsCorrectOrderTracks() {
        let playerItem1 = AudioPlayerItem(name: "name-1", url: anyURL(fileName: "name-1.mp3"), node: anyNode())
        let playerItem2 = AudioPlayerItem(name: "name-2", url: anyURL(fileName: "name-2.mp3"), node: anyNode())
        let playerItem3 = AudioPlayerItem(name: "name-3", url: anyURL(fileName: "name-3.mp3"), node: anyNode())
        let sut = AudioPlayerAllAudioAsPlaylistShiftStrategy()
        
        let result = sut.shift(tracks: [playerItem1, playerItem2, playerItem3], startItem: playerItem3)
        
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].name, playerItem3.name)
        XCTAssertEqual(result[1].name, playerItem1.name)
        XCTAssertEqual(result[2].name, playerItem2.name)
    }
    
    // MARK: - Helpers
    
    private func anyURL(fileName: String? = nil) -> URL {
        URL(string: "https://some-file-link.com/\(fileName ?? UUID().uuidString)")!
    }
    
    private func anyNode() -> MockNode {
        MockNode(handle: 1)
    }
    
}
