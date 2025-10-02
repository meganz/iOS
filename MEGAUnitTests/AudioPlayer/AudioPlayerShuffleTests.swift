@testable @preconcurrency import MEGA
import Testing

@MainActor
struct AudioPlayerShuffleTests {
    private static func makeSUT() -> AudioPlayer {
        let urls = (1...4).map { URL(string: "file://\($0).mp3")! }
        let items = urls.map { AudioPlayerItem(url: $0) }
        let sut = AudioPlayer(player: AVQueuePlayer(items: items))
        sut.tracks = items
        return sut
    }
    
    @MainActor
    @Suite("shuffleQueue()")
    struct Shuffle {
        @Test("shuffleQueue() keeps the first item fixed and preserves the same multiset of the remaining items")
        func preservesFirstAndMultiset() {
            let sut = makeSUT()
            let originalFirstURL = sut.tracks[0].url
            let originalRest = Set(sut.tracks.dropFirst().map { $0.url })
            
            sut.shuffleQueue()
            
            let result = sut.tracks
            
            #expect(result[0].url == originalFirstURL)
            #expect(Set(result.dropFirst().map { $0.url }) == originalRest)
        }
        
        @Test("shuffleQueue() preserves invariants across multiple calls")
        func preservesAcrossMultipleShuffles() {
            let sut = makeSUT()
            let originalRest = Set(sut.tracks.dropFirst().map { $0.url })
            
            sut.shuffleQueue()
            let firstPass = Set(sut.tracks.dropFirst().map { $0.url })
            
            sut.shuffleQueue()
            let secondPass = Set(sut.tracks.dropFirst().map { $0.url })
            
            // Each shuffle preserves the multiset of the tail
            #expect(firstPass == originalRest)
            #expect(secondPass == originalRest)
        }
    }
}
