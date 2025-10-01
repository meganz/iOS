@testable @preconcurrency import MEGA
import Testing

@Suite("Audio Player Playback")
@MainActor
struct AudioPlayerPlaybackTests {
    static func makePlayer(with tracks: [(name: String, resource: String, ext: String)]) async throws -> (AudioPlayer, [AudioPlayerItem]) {
        let player = AudioPlayer(debounceDelay: 0)
        let items: [AudioPlayerItem] = try tracks.map { info in
            let url = try #require(
                Bundle.main.url(forResource: info.resource, withExtension: info.ext)
            )
            return AudioPlayerItem(name: info.name, url: url, node: nil)
        }
        player.add(tracks: items)
        player.queuePlayer?.volume = 0.0
        
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        player.hasCompletedInitialConfiguration = true
        
        return (player, items)
    }
    
    static func makePlayerAndTracks(items: Int = 3) async throws -> (AudioPlayer, [AudioPlayerItem]) {
        let pool: [(resource: String, ext: String)] = [
            ("audioClipSent", "wav"),
            ("outgoingTone", "wav"),
            ("waitingRoomEvent", "wav")
        ]
        
        let requested: [(name: String, resource: String, ext: String)] =
        (1...items).map { i in
            let p = pool[(i - 1) % pool.count]
            return (name: "file \(i)", resource: p.resource, ext: p.ext)
        }
        
        return try await makePlayer(with: requested)
    }
    
    static func requireQueuePlayer(_ player: AudioPlayer) async throws -> AVQueuePlayer {
        try #require(player.queuePlayer)
    }
    
    static func performAsync(_ action: @MainActor @Sendable @escaping (@escaping () -> Void) -> Void) async {
        await withCheckedContinuation { cont in
            action { cont.resume() }
        }
    }
    
    static func waitUntil(
        timeout: TimeInterval,
        predicate: @MainActor @Sendable @escaping () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if predicate() { return true }
        }
        return false
    }
    
    static func toggleAndExpect(
        _ player: AudioPlayer,
        queuePlayer: AVQueuePlayer,
        expectedRate: Float,
        timeout: TimeInterval = 1.0
    ) async {
        player.togglePlay()
        await expectRate(expectedRate, on: queuePlayer, timeout: timeout)
    }
    
    static func expectRate(
        _ value: Float,
        on queuePlayer: AVQueuePlayer,
        timeout: TimeInterval = 1.0,
        interval: TimeInterval = 0.02
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        var matched = false

        while Date() < deadline {
            if abs(queuePlayer.rate - value) < 0.0001 {
                matched = true
                break
            }
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }

        #expect(matched, "Expected rate \(value) within \(timeout)s, last rate \(queuePlayer.rate)")
    }
    
    @Suite("Initialization & Playback")
    @MainActor
    struct Initialization {
        @Test("Initialization starts playback with provided tracks")
        func initializationStartsPlayback() async throws {
            let (player, tracks) = try await makePlayerAndTracks()
            
            #expect(player.tracks.count == tracks.count)
            #expect(player.isPlaying)
        }
    }
    
    @Suite("Navigation")
    @MainActor
    struct Navigation {
        @Test("playNext advances to next track")
        func playNextAdvancesToNextTrack() async throws {
            let (player, tracks) = try await makePlayerAndTracks()
            #expect(player.currentIndex == 0)
            let expected = tracks[1]
            
            await performAsync { done in
                player.playNext(done)
            }
            #expect(player.currentItem() == expected)
        }
        
        @Test("playPrevious returns to previous track")
        func playPreviousReturnsToPreviousTrack() async throws {
            let (player, tracks) = try await makePlayerAndTracks()
            let first = try #require(player.currentItem())
            let next  = tracks[1]
            
            await performAsync { done in
                player.playNext(done)
            }
            #expect(player.currentItem() == next)
            
            await performAsync { done in
                player.playPrevious(done)
            }
            #expect(player.currentItem() == first)
        }
    }
    
    enum TimeChange { case increased, decreased, unchanged }
    
    @Suite("Rewind/Forward")
    @MainActor
    struct RewindForwardSuite {
        private let timescale: CMTimeScale = 600
        private let initialSeekSeconds: Double = 10.0
        
        func testRewind_forward_advancesPlaybackTime() async throws {
            let (player, _) = try await makePlayerAndTracks()
            let queue = try await requireQueuePlayer(player)
            let before = queue.currentTime().seconds

            player.rewind(direction: .forward)
            
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            let advanced = queue.currentTime().seconds > before
            #expect(advanced, "Expected playback time to advance after forward rewind")
        }

        func testRewind_backward_decreasesPlaybackTime() async throws {
            let (player, _) = try await makePlayerAndTracks()
            let queue = try await requireQueuePlayer(player)
            
            let forwardTime = CMTime(seconds: initialSeekSeconds, preferredTimescale: timescale)
            await withCheckedContinuation { cont in
                queue.seek(to: forwardTime) { _ in cont.resume() }
            }

            player.rewind(direction: .backward)
            
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            let movedBack = queue.currentTime().seconds < initialSeekSeconds
            
            #expect(movedBack, "Expected playback time to move backward after rewind")
        }
    }
    
    @Suite("Queue Management")
    @MainActor
    struct Queue {
        @Test("deletePlaylist removes the specified track")
        func deletePlaylistRemovesTrack() async throws {
            let (player, tracks) = try await makePlayerAndTracks()
            let beforeCount      = player.tracks.count
            let last             = try #require(tracks.last)
            await player.deletePlaylist(items: [last])
            #expect(player.tracks.count == beforeCount - 1)
        }
        
        @Test("insertInQueue adds a track to the end")
        func insertInQueueAddsTrack() async throws {
            let (player, tracks) = try await makePlayerAndTracks()
            let url = try #require(
                Bundle.main.url(forResource: "audioClipSent", withExtension: "wav")
            )
            let item = AudioPlayerItem(name: "file 1", url: url, node: nil)
            player.insertInQueue(item: item, afterItem: nil)
            #expect(player.tracks.count == tracks.count + 1)
        }
        
        @Test("move reorders playlist items")
        func moveReordersPlaylistItems() async throws {
            let (player, tracks) = try await makePlayerAndTracks()
            let first = try #require(tracks.first)
            player.move(
                of: first,
                to: IndexPath(row: player.tracks.count - 1, section: 0),
                direction: .down
            )
            
            let queuePlayer = try await requireQueuePlayer(player)
            let items = queuePlayer.items().compactMap { $0 as? AudioPlayerItem }
            #expect(!tracks.elementsEqual(items))
        }
    }
    
    @Suite("Shuffle")
    @MainActor
    struct Shuffle {
        @Test("shuffleQueue preserves current and items for multiple tracks")
        func shuffleMultiplePreservesCurrentAndItems() async throws {
            let (player, _) = try await makePlayerAndTracks(items: 40)
            let original = player.tracks
            let current = try #require(player.currentItem())
            
            player.shuffleQueue()
            let shuffled = player.tracks
            
            #expect(shuffled.first == current)
            #expect(Set(shuffled) == Set(original))
            
            if shuffled == original {
                player.shuffleQueue()
                #expect(player.tracks != original)
            }
        }
        
        @Test("shuffleQueue is a no-op for single track")
        func shuffleSingleNoOp() async throws {
            let player = AudioPlayer()
            let url = try #require(
                Bundle.main.url(forResource: "audioClipSent", withExtension: "wav")
            )
            let solo   = AudioPlayerItem(name: "solo", url: url, node: nil)
            player.add(tracks: [solo])
            player.queuePlayer?.volume = 0.0
            try? await Task.sleep(nanoseconds: 200_000_000)
            player.hasCompletedInitialConfiguration = true
            
            let before = player.tracks
            player.shuffleQueue()
            #expect(player.tracks == before)
        }
        
        @Test("shuffleQueue while playing preserves order and current")
        func shuffleWhilePlayingPreservesOrderAndCurrent() async throws {
            let (player, _) = try await makePlayerAndTracks()
            let queuePlayer = try await requireQueuePlayer(player)
            #expect(player.isPlaying)
            
            let current = try #require(player.currentItem())
            let beforeItems = queuePlayer.items().compactMap { $0 as? AudioPlayerItem }
            
            player.shuffleQueue()
            let afterItems = queuePlayer.items().compactMap { $0 as? AudioPlayerItem }
            
            #expect(afterItems.first == current)
            #expect(Set(afterItems) == Set(beforeItems))
        }
    }
}
