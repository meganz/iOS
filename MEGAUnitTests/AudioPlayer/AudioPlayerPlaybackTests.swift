@testable import MEGA
import XCTest

final class AudioPlayerPlaybackTests: XCTestCase {
    
    var audioPlayer = AudioPlayer()
    var tracks: [AudioPlayerItem] = []
    
    override func setUpWithError() throws {
        let file1URL = try XCTUnwrap(Bundle.main.url(forResource: "audioClipSent", withExtension: "wav"))
        let file2URL = try XCTUnwrap(Bundle.main.url(forResource: "outgoingTone", withExtension: "wav"))
        
        let track1 = AudioPlayerItem(name: "file 1", url: file1URL, node: nil)
        let track2 = AudioPlayerItem(name: "file 2", url: file2URL, node: nil)
        
        tracks.append(contentsOf: [track1, track2])
    }
    
    override func tearDown() {
        super.tearDown()
        tracks.removeAll()
    }
    
    private func addTracks() {
        audioPlayer.add(tracks: tracks)
        audioPlayer.queuePlayer?.volume = 0.0
    }

    func testAudioPlayerSetup() throws {
        XCTAssertTrue(tracks.count > 0)
        addTracks()
        XCTAssertTrue(audioPlayer.tracks.count == tracks.count)
        XCTAssertTrue(audioPlayer.isPlaying)
    }
    
    func testAudioPlayerPlayNext() throws {
        let expect = expectation(description: "Play next item")
        
        XCTAssertTrue(tracks.count > 0)
        addTracks()
        XCTAssertNotNil(audioPlayer.currentIndex)
        XCTAssertTrue(audioPlayer.currentIndex == 0)
        
        let nextItem = audioPlayer.tracks[(audioPlayer.currentIndex ?? 0) + 1]
        
        audioPlayer.playNext {
            expect.fulfill()
        }
        
        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
            XCTAssertNotNil(self.audioPlayer.currentItem)
            XCTAssertTrue(nextItem == self.audioPlayer.currentItem())
        }
    }
    
    func testAudioPlayerPlayPrevious() throws {
        let expect = expectation(description: "Play previous item")
        
        XCTAssertTrue(tracks.count > 0)
        addTracks()
        XCTAssertNotNil(audioPlayer.currentIndex)
        XCTAssertTrue(audioPlayer.currentIndex == 0)
        
        let currentItem = try XCTUnwrap(audioPlayer.currentItem())
        let nextItem = audioPlayer.tracks[(audioPlayer.currentIndex ?? 0) + 1]
        
        audioPlayer.playNext {
            XCTAssertNotNil(self.audioPlayer.currentItem)
            XCTAssertTrue(nextItem == self.audioPlayer.currentItem())
            
            self.audioPlayer.playPrevious {
                XCTAssertNotNil(self.audioPlayer.currentItem)
                XCTAssertTrue(currentItem == self.audioPlayer.currentItem())
                expect.fulfill()
            }
        }
        
        waitForExpectations(timeout: 0.5) { error in
            XCTAssertNil(error)
        }
    }
    
    func testAudioPlayerRewindForward() throws {
        let expect = expectation(description: "Rewind forward")
        
        XCTAssertTrue(tracks.count > 0)
        addTracks()
        let queuePlayer = try XCTUnwrap(audioPlayer.queuePlayer)
        let currentTime = queuePlayer.currentTime()
        XCTAssertTrue(CMTIME_IS_VALID(currentTime))
        
        let observer = queuePlayer.observe(\.timeControlStatus, options: [.new, .old]) { (qPlayer, _) in
            switch qPlayer.timeControlStatus {
            case .playing:
                self.audioPlayer.rewindForward(duration: CMTime(seconds: self.audioPlayer.defaultRewindInterval, preferredTimescale: qPlayer.currentTime().timescale)) { _ in
                    XCTAssertTrue(currentTime.seconds < qPlayer.currentTime().seconds)
                    expect.fulfill()
                }
            default:
                break
            }
        }

        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
            observer.invalidate()
        }
    }
    
    func testAudioPlayerRewindBackward() throws {
        let expect = expectation(description: "Rewind backward")
        
        XCTAssertTrue(tracks.count > 0)
        addTracks()
        let queuePlayer = try XCTUnwrap(audioPlayer.queuePlayer)
        let currentTime = queuePlayer.currentTime()
        XCTAssertTrue(CMTIME_IS_VALID(currentTime))
        
        let observer = queuePlayer.observe(\.timeControlStatus, options: [.new, .old]) { (qPlayer, _) in
            switch qPlayer.timeControlStatus {
            case .playing:
                self.audioPlayer.rewindBackward { _ in
                    XCTAssertTrue(currentTime.seconds <= self.audioPlayer.defaultRewindInterval ?
                                    qPlayer.currentTime().seconds == 0 :
                                    currentTime.seconds > qPlayer.currentTime().seconds)
                    expect.fulfill()
                }
            default:
                break
            }
        }

        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
            observer.invalidate()
        }
    }
    
    func testAudioPlayerPause() {
        XCTAssertTrue(tracks.count > 0)
        addTracks()
        audioPlayer.togglePlay()
        XCTAssertTrue(audioPlayer.isPaused)
        audioPlayer.togglePlay()
        XCTAssertTrue(audioPlayer.isPlaying)
    }
    
    func testAudioPlayerDeleteItem() throws {
        XCTAssertTrue(tracks.count > 0)
        addTracks()
        XCTAssertTrue(audioPlayer.tracks.count == tracks.count)
        let lastTrack = try XCTUnwrap(tracks.last)
        audioPlayer.deletePlaylist(items: [lastTrack])
        XCTAssertTrue(audioPlayer.tracks.count == tracks.count - 1)
    }
    
    func testAudioPlayerInsertItemInPlaylist() throws {
        XCTAssertTrue(tracks.count > 0)
        let track = try XCTUnwrap(tracks.last)
        tracks.removeLast()
        addTracks()
        let tracksNumber = audioPlayer.tracks.count
        audioPlayer.insertInQueue(item: track, afterItem: nil)
        XCTAssertTrue(audioPlayer.tracks.count == tracksNumber + 1)
    }
    
    func testAudioPlayerMoveItems() throws {
        XCTAssertTrue(tracks.count > 0)
        addTracks()
        XCTAssertTrue(audioPlayer.tracks.count == tracks.count)
        let track = try XCTUnwrap(tracks.first)
        audioPlayer.move(of: track, to: IndexPath(row: audioPlayer.tracks.count - 1, section: 0), direction: .down)
        let queuePlayer = try XCTUnwrap(audioPlayer.queuePlayer)
        let playerTracks = try XCTUnwrap(queuePlayer.items() as? [AudioPlayerItem])
        XCTAssertFalse(tracks.elementsEqual(playerTracks))
    }
}
