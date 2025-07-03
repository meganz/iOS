@testable @preconcurrency import MEGA
import XCTest

final class AudioPlayerPlaybackTests: XCTestCase {
    enum TestError: Error { case missingQueuePlayer }

    // MARK: - Helpers

    private func makePlayerAndTracks() async throws -> (AudioPlayer, [AudioPlayerItem]) {
        let player = AudioPlayer()
        let file1URL = try XCTUnwrap(Bundle.main.url(forResource: "audioClipSent", withExtension: "wav"))
        let file2URL = try XCTUnwrap(Bundle.main.url(forResource: "outgoingTone", withExtension: "wav"))
        let tracks = await [
            AudioPlayerItem(name: "file 1", url: file1URL, node: nil),
            AudioPlayerItem(name: "file 2", url: file2URL, node: nil)
        ]
        player.add(tracks: tracks)
        player.queuePlayer?.volume = 0.0
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        return (player, tracks)
    }

    private func requireQueuePlayer(_ player: AudioPlayer) async throws -> AVQueuePlayer {
        if let queue = player.queuePlayer { return queue }
        XCTFail("Expected queuePlayer")
        throw TestError.missingQueuePlayer
    }

    private func performAsync(_ action: @Sendable @escaping (@escaping () -> Void) -> Void) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            action {
                cont.resume()
            }
        }
    }
    
    private func waitUntil(timeout: TimeInterval, predicate: @Sendable @escaping () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if predicate() { return true }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return false
    }
    
    private func expectRate(_ value: Float, on queuePlayer: AVQueuePlayer, timeout: TimeInterval = 1.0) async {
        let exp = XCTKVOExpectation(
            keyPath: #keyPath(AVQueuePlayer.rate),
            object: queuePlayer,
            expectedValue: NSNumber(value: value)
        )
        await fulfillment(of: [exp], timeout: timeout)
    }
    
    private func toggleAndExpect(
        _ player: AudioPlayer,
        queuePlayer: AVQueuePlayer,
        expectedRate: Float,
        timeout: TimeInterval = 1.0
    ) async {
        player.togglePlay()
        await expectRate(expectedRate, on: queuePlayer, timeout: timeout)
    }
    
    // MARK: - Tests

    func testInitWithTracks_whenHavingTracks_shouldInitializeAndPlay() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        XCTAssertEqual(player.tracks.count, tracks.count)
        XCTAssertTrue(player.isPlaying)
    }

    func testPlayNext_whenAtStart_shouldGoToNextItem() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        XCTAssertEqual(player.currentIndex, 0)
        let nextItem = tracks[1]

        await performAsync { completion in
            player.playNext(completion)
        }
        XCTAssertEqual(player.currentItem(), nextItem)
    }

    func testPlayPrevious_afterNext_returnsToInitialItem() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        let initialItem = try XCTUnwrap(player.currentItem())
        let nextItem = tracks[1]

        await performAsync { completion in
            player.playNext(completion)
        }
        XCTAssertEqual(player.currentItem(), nextItem)

        await performAsync { completion in
            player.playPrevious(completion)
        }
        XCTAssertEqual(player.currentItem(), initialItem)
    }

    func testRewind_whenDirectionForward_shouldAdvanceTime() async throws {
        let (player, _) = try await makePlayerAndTracks()
        let queue = try await requireQueuePlayer(player)
        let before = queue.currentTime().seconds
        
        player.rewind(direction: .forward)
        let success = await waitUntil(timeout: 3) {
            queue.currentTime().seconds > before
        }
        XCTAssertTrue(success, "Expected playback time to advance after rewind forward")
    }

    func testRewind_whenDirectionBackward_shouldDecreaseTime() async throws {
        let (player, _) = try await makePlayerAndTracks()
        let queuePlayer = try await requireQueuePlayer(player)
        let forwardTime = CMTime(seconds: 10, preferredTimescale: queuePlayer.currentTime().timescale)
        await withCheckedContinuation { cont in
            queuePlayer.seek(to: forwardTime) { _ in cont.resume() }
        }
        
        player.rewind(direction: .backward)
        try? await Task.sleep(nanoseconds: 100_000_000)
        let newTime = queuePlayer.currentTime().seconds
        XCTAssertTrue(newTime < 10)
    }
    
    func testTogglePlay_whenToggled_shouldPauseAndResume() async throws {
        let (player, _) = try await makePlayerAndTracks()
        let queuePlayer = try await requireQueuePlayer(player)
        
        await expectRate(1.0, on: queuePlayer)
        
        await toggleAndExpect(
            player,
            queuePlayer: queuePlayer,
            expectedRate: 0.0
        )
        XCTAssertTrue(player.isPaused, "Expected player to be paused after first toggle")
        
        await toggleAndExpect(
            player,
            queuePlayer: queuePlayer,
            expectedRate: 1.0
        )
        XCTAssertTrue(player.isPlaying, "Expected player to be playing after second toggle")
    }
    
    func testDeletePlaylist_whenDeleting_shouldRemoveSpecifiedItem() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        let original = player.tracks.count
        let lastTrack = try XCTUnwrap(tracks.last)
        player.deletePlaylist(items: [lastTrack])
        XCTAssertEqual(player.tracks.count, original - 1)
    }

    func testInsertInQueue_whenInserting_shouldAddItemToPlaylist() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        let trackURL = try XCTUnwrap(Bundle.main.url(forResource: "audioClipSent", withExtension: "wav"))
        let track = await AudioPlayerItem(name: "file 1", url: trackURL, node: nil)
        player.insertInQueue(item: track, afterItem: nil)
        XCTAssertEqual(player.tracks.count, tracks.count + 1)
    }

    func testMove_whenMoving_shouldReorderPlaylistItems() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        let item = try XCTUnwrap(tracks.first)
        player.move(of: item, to: IndexPath(row: player.tracks.count - 1, section: 0), direction: .down)

        let queuePlayer = try await requireQueuePlayer(player)
        let playlist = queuePlayer.items().compactMap { $0 as? AudioPlayerItem }
        XCTAssertFalse(tracks.elementsEqual(playlist))
    }
}
