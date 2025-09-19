@testable @preconcurrency import MEGA
import XCTest

@MainActor
final class AudioPlayerPlaybackTests: XCTestCase {
    enum TestError: Error { case missingQueuePlayer }

    // MARK: - Helpers

    private func loadURL(_ name: String, ext: String) throws -> URL {
        try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: ext), "Missing resource \(name).\(ext)")
    }

    private func makePlayerAndTracks() async throws -> (AudioPlayer, [AudioPlayerItem]) {
        let player = AudioPlayer()
        let file1URL = try loadURL("audioClipSent", ext: "wav")
        let file2URL = try loadURL("outgoingTone", ext: "wav")
        let tracks = [
            AudioPlayerItem(name: "file 1", url: file1URL, node: nil),
            AudioPlayerItem(name: "file 2", url: file2URL, node: nil)
        ]

        player.add(tracks: tracks)
        player.queuePlayer?.volume = 0.0
        
        let ready = await waitUntil(timeout: 3.0) { player.hasCompletedInitialConfiguration }
        XCTAssertTrue(ready, "Player did not complete initial configuration in time")

        return (player, tracks)
    }

    private func requireQueuePlayer(_ player: AudioPlayer) throws -> AVQueuePlayer {
        try XCTUnwrap(player.queuePlayer, "Expected an AVQueuePlayer")
    }
    
    private func performAsync(_ action: @escaping (@escaping () -> Void) -> Void) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            action { cont.resume() }
        }
    }
    
    private func waitUntil(timeout: TimeInterval, poll: UInt64 = 100_000_000, predicate: @MainActor @Sendable @escaping () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if predicate() { return true }
            try? await Task.sleep(nanoseconds: poll)
        }
        return false
    }

    private func expectRate(_ value: Float, on queuePlayer: AVQueuePlayer, timeout: TimeInterval = 1.5) async {
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
        timeout: TimeInterval = 1.5
    ) async {
        player.togglePlay()
        await expectRate(expectedRate, on: queuePlayer, timeout: timeout)
    }

    private func waitForCurrentItem(toEqual expected: AudioPlayerItem?, in player: AudioPlayer, timeout: TimeInterval = 2.0) async {
        let ok = await waitUntil(timeout: timeout) { player.currentItem() == expected }
        XCTAssertTrue(ok, "Expected current item to be \(String(describing: expected?.name))")
    }

    // MARK: - Tests

    func testAddTracks_whenProvided_initializesAndStartsPlaying() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        XCTAssertEqual(player.tracks.count, tracks.count)
        XCTAssertTrue(player.isPlaying)
    }

    func testPlayNext_fromFirst_movesToSecondItem() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        XCTAssertEqual(player.currentIndex, 0)
        let nextItem = tracks[1]

        await performAsync { completion in
            player.playNext(completion)
        }
        await waitForCurrentItem(toEqual: nextItem, in: player)
    }

    func testPlayPrevious_afterNext_returnsToInitialItem() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        let initialItem = try XCTUnwrap(player.currentItem())
        let nextItem = tracks[1]

        await performAsync { completion in
            player.playNext(completion)
        }
        await waitForCurrentItem(toEqual: nextItem, in: player)

        await performAsync { completion in
            player.playPrevious(completion)
        }
        await waitForCurrentItem(toEqual: initialItem, in: player)
    }

    func testRewind_forward_advancesPlaybackTime() async throws {
        let (player, _) = try await makePlayerAndTracks()
        let queue = try requireQueuePlayer(player)
        let before = queue.currentTime().seconds

        player.rewind(direction: .forward) // uses default interval and seeks on the main actor :contentReference[oaicite:1]{index=1}
        let advanced = await waitUntil(timeout: 3.0) { queue.currentTime().seconds > before }
        XCTAssertTrue(advanced, "Expected playback time to advance after forward rewind")
    }

    func testRewind_backward_decreasesPlaybackTime() async throws {
        let (player, _) = try await makePlayerAndTracks()
        let queue = try requireQueuePlayer(player)

        // Seek forward to create room to move backward
        let forwardTime = CMTime(seconds: 10, preferredTimescale: queue.currentTime().timescale)
        await withCheckedContinuation { cont in
            queue.seek(to: forwardTime) { _ in cont.resume() }
        }

        player.rewind(direction: .backward) // will clamp at zero if needed :contentReference[oaicite:2]{index=2}
        let movedBack = await waitUntil(timeout: 3.0) { queue.currentTime().seconds < 10 }
        XCTAssertTrue(movedBack, "Expected playback time to move backward after rewind")
    }

    func testTogglePlay_togglesPauseAndResume() async throws {
        let (player, _) = try await makePlayerAndTracks()
        let queue = try requireQueuePlayer(player)

        await expectRate(1.0, on: queue)

        await toggleAndExpect(player, queuePlayer: queue, expectedRate: 0.0)
        XCTAssertTrue(player.isPaused, "Expected player to be paused after first toggle")

        await toggleAndExpect(player, queuePlayer: queue, expectedRate: 1.0)
        // Give the player a tick to propagate flags
        let resumed = await waitUntil(timeout: 1.0) { player.isPlaying }
        XCTAssertTrue(resumed, "Expected player to be playing after second toggle")
    }

    func testDeletePlaylist_whenRemovingLastItem_reducesCountByOne() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        let original = player.tracks.count
        let lastTrack = try XCTUnwrap(tracks.last)

        await player.deletePlaylist(items: [lastTrack])
        XCTAssertEqual(player.tracks.count, original - 1)
    }

    func testInsertInQueue_whenAppending_increasesPlaylistSize() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        let trackURL = try loadURL("audioClipSent", ext: "wav")
        let track = AudioPlayerItem(name: "file 1", url: trackURL, node: nil)

        player.insertInQueue(item: track, afterItem: nil)
        XCTAssertEqual(player.tracks.count, tracks.count + 1)
    }

    func testMove_whenMovingFirstItemDown_reordersPlaylist() async throws {
        let (player, tracks) = try await makePlayerAndTracks()
        let item = try XCTUnwrap(tracks.first)
        player.move(of: item, to: IndexPath(row: player.tracks.count - 1, section: 0), direction: .down)

        let queue = try requireQueuePlayer(player)
        let playlist = queue.items().compactMap { $0 as? AudioPlayerItem }
        let newIndex = try XCTUnwrap(playlist.firstIndex(of: item), "Moved item not found in queue")
        
        XCTAssertEqual(newIndex, playlist.count - 1, "Expected moved item to be last in the queue")
    }
}
