import XCTest
@testable import MEGA

final class AudioPlayerPlaybackTests: XCTestCase {
    
    let player = AudioPlayer()
    let tracks = AudioPlayerItem.mockArray

    override func setUp() {
        super.setUp()
        player.add(tracks: tracks)
    }

    func testAudioPlayerSetup() throws {
        XCTAssertTrue(player.tracks.count == tracks.count)
        XCTAssertTrue(player.isPlaying)
    }
    
    func testAudioPlayerPlayNext() {
        let expectaction = expectation(description: "Play next item")
        XCTAssertNotNil(player.currentIndex)
        XCTAssertTrue(player.currentIndex == 0)
        let nextItem = tracks[(player.currentIndex ?? 0) + 1]
        player.playNext() {
            expectaction.fulfill()
        }
        
        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(self.player.currentItem)
            XCTAssertTrue(nextItem == self.player.currentItem())
        }
    }
    
    func testAudioPlayerPlayPrevious() {
        let expectaction = expectation(description: "Play previous item")
        let currentItem = tracks[(player.currentIndex ?? 0)]
        XCTAssertNotNil(player.currentIndex)
        XCTAssertTrue(player.currentIndex == 0)
        let nextItem = tracks[(player.currentIndex ?? 0) + 1]
        player.playNext() {
            XCTAssertNotNil(self.player.currentItem)
            XCTAssertTrue(nextItem == self.player.currentItem())
            
            self.player.playPrevious() {
                XCTAssertNotNil(self.player.currentItem)
                XCTAssertTrue(currentItem == self.player.currentItem())
                expectaction.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }
    
    func testAudioPlayerPause() {
        player.togglePlay()
        XCTAssertTrue(player.isPaused)
        player.togglePlay()
        XCTAssertTrue(player.isPlaying)
    }
    
    func testAudioPlayerDeleteItem() throws {
        XCTAssertTrue(player.tracks.count == tracks.count)
        let lastTrack = try XCTUnwrap(tracks.last)
        player.deletePlaylist(items: [lastTrack])
        XCTAssertTrue(player.tracks.count == tracks.count - 1)
    }
    
    func testAudioPlayerInsertItemInPlaylist() {
        let tracksNumber = player.tracks.count
        let track = AudioPlayerItem.mockItem
        player.insertInQueue(item: track, afterItem: nil)
        XCTAssertTrue(player.tracks.count == tracksNumber + 1)
    }
    
    func testAudioPlayerShufflePlaylist() throws {
        let tracks = try XCTUnwrap(player.queuePlayer?.items())
        player.shuffle(true)
        player.shuffle(true)
        let reorderTracks = try XCTUnwrap(player.queuePlayer?.items())
        XCTAssertFalse(tracks.elementsEqual(reorderTracks))
    }
    
    func testAudioPlayerMoveItems() {
        XCTAssertTrue(player.tracks.count == tracks.count)
        let firstTrack = player.tracks.first
        XCTAssertNotNil(firstTrack)
        let tracks = player.tracks
        player.move(of: firstTrack ?? AudioPlayerItem.mockItem, to: IndexPath(row: player.tracks.count - 1, section: 0), direction: .down)
        XCTAssertFalse(tracks.elementsEqual(player.tracks))
    }
}
