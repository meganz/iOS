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
        let expect = expectation(description: "Play next item")
        XCTAssertNotNil(player.currentIndex)
        XCTAssertTrue(player.currentIndex == 0)
        let nextItem = tracks[(player.currentIndex ?? 0) + 1]
        player.playNext() {
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(self.player.currentItem)
            XCTAssertTrue(nextItem == self.player.currentItem())
        }
    }
    
    func testAudioPlayerPlayPrevious() {
        let expect = expectation(description: "Play previous item")
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
                expect.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }
    
    func testAudioPlayerRewindForward() throws {
        let expect = expectation(description: "Rewind forward")
        let audioPlayer = AudioPlayer()
        audioPlayer.add(tracks: [AudioPlayerItem(name: "Track 1",
                                                 url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!,
                                                 node: nil)])
        let queuePlayer = try XCTUnwrap(audioPlayer.queuePlayer)
        let currentTime = queuePlayer.currentTime()
        XCTAssertTrue(CMTIME_IS_VALID(currentTime))
        var observer: NSKeyValueObservation?
        
        audioPlayer.play()
        
        observer = queuePlayer.observe(\.timeControlStatus, options: [.new, .old]) { (qPlayer, _) in
            switch (qPlayer.timeControlStatus) {
            case .playing:
                audioPlayer.rewindForward(duration: CMTime(seconds: audioPlayer.defaultRewindInterval, preferredTimescale: qPlayer.currentTime().timescale)) { _ in
                    XCTAssertTrue(currentTime.seconds + audioPlayer.defaultRewindInterval == qPlayer.currentTime().seconds)
                    expect.fulfill()
                }
            default:
                break
            }
        }

        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
            observer?.invalidate()
        }
    }
    
    func testAudioPlayerRewindBackward() throws {
        let expect = expectation(description: "Rewind backward")
        let audioPlayer = AudioPlayer()
        audioPlayer.add(tracks: [AudioPlayerItem(name: "Track 1",
                                                 url: URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")!,
                                                 node: nil)])
        let queuePlayer = try XCTUnwrap(audioPlayer.queuePlayer)
        let currentTime = queuePlayer.currentTime()
        XCTAssertTrue(CMTIME_IS_VALID(currentTime))
        var observer: NSKeyValueObservation?
        
        audioPlayer.play()
            
        observer = queuePlayer.observe(\.timeControlStatus, options: [.new, .old]) { (qPlayer, _) in
            switch (qPlayer.timeControlStatus) {
            case .playing:
                audioPlayer.rewindBackward { _ in
                    XCTAssertTrue(currentTime.seconds <= audioPlayer.defaultRewindInterval ?
                                    qPlayer.currentTime().seconds == 0 :
                                    currentTime.seconds == qPlayer.currentTime().seconds + audioPlayer.defaultRewindInterval)
                    expect.fulfill()
                }
            default:
                break
            }
        }

        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
            observer?.invalidate()
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
    
    func testAudioPlayerMoveItems() {
        XCTAssertTrue(player.tracks.count == tracks.count)
        let firstTrack = player.tracks.first
        XCTAssertNotNil(firstTrack)
        let tracks = player.tracks
        player.move(of: firstTrack ?? AudioPlayerItem.mockItem, to: IndexPath(row: player.tracks.count - 1, section: 0), direction: .down)
        XCTAssertFalse(tracks.elementsEqual(player.tracks))
    }
}
