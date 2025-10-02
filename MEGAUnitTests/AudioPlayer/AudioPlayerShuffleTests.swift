@testable @preconcurrency import MEGA
import Testing

@MainActor
struct AudioPlayerShuffleTests {
    private static func makeSUT(trackCount: Int = 10, currentIndex: Int = 0) -> AudioPlayer {
        let urls: [URL] = (1...trackCount).map { URL(string: "file://\($0).mp3")! }
        let items: [AudioPlayerItem] = urls.map { AudioPlayerItem(url: $0) }
        
        let queuePlayer = AVQueuePlayer()
        queuePlayer.replaceCurrentItem(with: items[currentIndex])
        if currentIndex + 1 < items.count {
            for index in (currentIndex + 1)..<items.count {
                queuePlayer.insert(items[index], after: queuePlayer.items().last)
            }
        }
        let sut = AudioPlayer(player: queuePlayer, debounceDelay: 0)
        sut.tracks = items
        
        sut.hasCompletedInitialConfiguration = true
        return sut
    }
    
    private static func urls(from items: [AudioPlayerItem]) -> [URL] { items.map(\.url) }
    
    /// Returns the first `count` URLs from `allURLs`.
    /// Used to assert that the prefix before the current index is preserved across shuffles.
    private static func prefixURLs(of allURLs: [URL], count: Int) -> [URL] {
        Array(allURLs.prefix(count))
    }
    
    /// Returns the URLs strictly after `index` (i.e., elements at indices `index+1...`).
    /// Used to compare the “tail” region affected by shuffle.
    private static func tailURLs(of allURLs: [URL], after index: Int) -> [URL] {
        index + 1 < allURLs.count ? Array(allURLs.dropFirst(index + 1)) : []
    }
    
    /// Returns the set of URLs in the tail after `index`. Used to assert “same elements; order doesn’t matter”.
    private static func tailURLSet(of allURLs: [URL], after index: Int) -> Set<URL> {
        index + 1 < allURLs.count ? Set(allURLs.dropFirst(index + 1)) : []
    }
    
    @MainActor
    @Suite("shuffleQueue() – ON")
    struct ShuffleON {
        
        @Test("Current at 0 keeps first fixed and shuffles only the tail")
        func keepsFirstAndShufflesTail() {
            let sut = makeSUT(trackCount: 8, currentIndex: 0)
            let originalURLs = urls(from: sut.tracks)
            
            sut.shuffle(true)
            
            let shuffledURLs = urls(from: sut.tracks)
            let shuffledFirst = shuffledURLs.first
            let shuffledTailSet = Set(shuffledURLs.dropFirst())
            let originalFirst = originalURLs.first
            let originalTailSet = Set(originalURLs.dropFirst())
            
            #expect(shuffledFirst == originalFirst, "Current item must remain at index 0 after enabling shuffle")
            #expect(shuffledTailSet == originalTailSet, "Tail must be a permutation of the original tail")
        }
        
        @Test("Current in middle preserves prefix, pins current, and permutes only the tail")
        func keepsPrefixCurrentAndShufflesOnlyTail() {
            let currentIndexUnderTest = 3
            let sut = makeSUT(trackCount: 10, currentIndex: currentIndexUnderTest)
            let originalURLs = urls(from: sut.tracks)
            
            sut.shuffle(true)
            
            let shuffledURLs = urls(from: sut.tracks)
            let shuffledPrefix = prefixURLs(of: shuffledURLs, count: currentIndexUnderTest)
            let shuffledCurrent = shuffledURLs[currentIndexUnderTest]
            let shuffledTailSet = tailURLSet(of: shuffledURLs, after: currentIndexUnderTest)
            
            let expectedPrefix = prefixURLs(of: originalURLs, count: currentIndexUnderTest)
            let expectedCurrent = originalURLs[currentIndexUnderTest]
            let expectedTailSet = tailURLSet(of: originalURLs, after: currentIndexUnderTest)
            
            #expect(shuffledPrefix == expectedPrefix, "Items before the current must be unchanged")
            #expect(shuffledCurrent == expectedCurrent, "Current item must remain at index \(currentIndexUnderTest)")
            #expect(shuffledTailSet == expectedTailSet, "Only the tail may change order, not content")
        }
        
        @Test("Empty tail (current is last) is a no-op")
        func handlesEmptyTail() {
            let sut = makeSUT(trackCount: 5, currentIndex: 4)
            let beforeURLs = urls(from: sut.tracks)
            
            sut.shuffle(true)
            
            let afterURLs = urls(from: sut.tracks)
            #expect(afterURLs == beforeURLs, "Shuffling with empty tail must not change the playlist")
        }
        
        @Test("Single-item playlist is a no-op")
        func singleItem() {
            let sut = makeSUT(trackCount: 1, currentIndex: 0)
            let beforeURLs = urls(from: sut.tracks)
            
            sut.shuffle(true)
            
            let afterURLs = urls(from: sut.tracks)
            #expect(afterURLs == beforeURLs, "Shuffling a single item must not change the playlist")
        }
        
        @Test("Large list preserves prefix + current and tail multiset")
        func largePlaylistMultiset() {
            let currentIndexUnderTest = 120
            let sut = makeSUT(trackCount: 240, currentIndex: currentIndexUnderTest)
            let originalURLs = urls(from: sut.tracks)
            
            sut.shuffle(true)
            
            let afterURLs = urls(from: sut.tracks)
            let shuffledPrefix = prefixURLs(of: afterURLs, count: currentIndexUnderTest)
            let shuffledCurrent = afterURLs[currentIndexUnderTest]
            let shuffledTailSet = tailURLSet(of: afterURLs, after: currentIndexUnderTest)
            
            let expectedPrefix = prefixURLs(of: originalURLs, count: currentIndexUnderTest)
            let expectedCurrent = originalURLs[currentIndexUnderTest]
            let expectedTailSet = tailURLSet(of: originalURLs, after: currentIndexUnderTest)
            
            #expect(shuffledPrefix == expectedPrefix, "Large-list prefix must be preserved")
            #expect(shuffledCurrent == expectedCurrent, "Large-list current must remain pinned")
            #expect(shuffledTailSet == expectedTailSet, "Large-list tail must be the same multiset")
        }
        
        @Test("Multiple ON calls keep invariants for the same current index")
        func multipleOnCalls() {
            let currentIndexUnderTest = 4
            let sut = makeSUT(trackCount: 20, currentIndex: currentIndexUnderTest)
            let originalURLs = urls(from: sut.tracks)
            
            let expectedPrefix = prefixURLs(of: originalURLs, count: currentIndexUnderTest)
            let expectedCurrent = originalURLs[currentIndexUnderTest]
            let expectedTailSet = tailURLSet(of: originalURLs, after: currentIndexUnderTest)
            
            for shuffleAttemptIndex in 0..<4 {
                _ = shuffleAttemptIndex
                sut.shuffle(true)
                
                let shuffledURLs = urls(from: sut.tracks)
                let shuffledPrefix = prefixURLs(of: shuffledURLs, count: currentIndexUnderTest)
                let shuffledCurrent = shuffledURLs[currentIndexUnderTest]
                let shuffledTailSet = tailURLSet(of: shuffledURLs, after: currentIndexUnderTest)
                
                #expect(shuffledPrefix == expectedPrefix, "Prefix must remain unchanged across shuffles")
                #expect(shuffledCurrent == expectedCurrent, "Current item must remain at index \(currentIndexUnderTest) across shuffles")
                #expect(shuffledTailSet == expectedTailSet, "Tail content must remain identical across shuffles")
            }
        }
    }
    
    @MainActor
    @Suite("shuffleQueue() – OFF")
    struct ShuffleOFF {
        
        @Test("Restores original order captured when turning shuffle ON")
        func restoresOriginalOrder() {
            let sut = makeSUT(trackCount: 10, currentIndex: 0)
            let originalURLs = urls(from: sut.tracks)
            
            sut.shuffle(true)
            sut.shuffle(false)
            
            let restoredURLs = urls(from: sut.tracks)
            #expect(restoredURLs == originalURLs, "Disabling shuffle must restore the original playlist order")
        }
        
        @Test("Restores original order with mid-current and keeps current playing")
        func restoresWithMidCurrent() {
            let currentIndexUnderTest = 5
            let sut = makeSUT(trackCount: 12, currentIndex: currentIndexUnderTest)
            let originalURLs = urls(from: sut.tracks)
            let currentURLBefore = (sut.queuePlayer.currentItem as? AudioPlayerItem)!.url
            
            sut.shuffle(true)
            sut.shuffle(false)
            
            let restoredURLs = urls(from: sut.tracks)
            let currentURLAfter = (sut.queuePlayer.currentItem as? AudioPlayerItem)!.url
            
            #expect(restoredURLs == originalURLs, "Disabling shuffle must restore the original order even if current is in the middle")
            #expect(currentURLAfter == currentURLBefore, "Current item must continue playing after restoring")
        }
        
        @Test("Uses defaultTracksOrder as base and clears it afterwards")
        func restoresFromSnapshotAndClearsIt() {
            let currentIndex = 2
            let sut = makeSUT(trackCount: 5, currentIndex: currentIndex)
            let original = urls(from: sut.tracks)
            
            seedShuffleOn(sut)
            
            sut.shuffle(false)
            
            let restored = urls(from: sut.tracks)
            #expect(restored == original)
            #expect(sut.defaultTracksOrder == nil)
        }
        
        @Test("OFF without prior ON keeps order and current playing")
        func offWithoutPriorOnNoOpButRebuilds() {
            let currentIndex = 2
            let sut = makeSUT(trackCount: 7, currentIndex: currentIndex)
            let before = urls(from: sut.tracks)
            let currentBefore = (sut.queuePlayer.currentItem as? AudioPlayerItem)?.url
            
            sut.shuffle(false)
            
            let after = urls(from: sut.tracks)
            let currentAfter = (sut.queuePlayer.currentItem as? AudioPlayerItem)?.url
            #expect(after == before, "No shuffle snapshot -> restoring from current tracks should be a no-op")
            #expect(currentAfter == currentBefore, "Current item must remain the same")
        }
        
        @Test("Missing current in base snapshot notifies and does nothing harmful")
        func missingCurrentInBaseSnapshotGracefulEarlyExit() {
            let currentIndex = 1
            let sut = makeSUT(trackCount: 5, currentIndex: currentIndex)
            
            seedShuffleOn(sut)
            
            let currentURL = (sut.queuePlayer.currentItem as? AudioPlayerItem)!.url
            sut.defaultTracksOrder = sut.defaultTracksOrder?.filter { $0.url != currentURL }
            
            sut.shuffle(false)
            
            #expect(sut.tracks.contains { $0.url == currentURL })
        }
        
        @Test("Restores linear tail order after current")
        func restoresLinearTailAfterCurrent() {
            let currentIndex = 4
            let sut = makeSUT(trackCount: 12, currentIndex: currentIndex)
            let original = urls(from: sut.tracks)
            
            sut.shuffle(true)
            sut.shuffle(false)
            
            let restored = urls(from: sut.tracks)
            let expectedTail = Array(original[(currentIndex + 1)...])
            let restoredTail = Array(restored[(currentIndex + 1)...])
            #expect(restoredTail == expectedTail, "Tail order after current must be the original linear order")
        }
        
        private func seedShuffleOn(_ sut: AudioPlayer) {
            sut.audioPlayerConfig[.shuffle] = true
            sut.defaultTracksOrder = sut.tracks
        }
    }
    
    @MainActor
    @Suite("Stability")
    struct Stability {
        
        @Test("ON → OFF → ON restores and reshuffles correctly")
        func onOffOnCycle() {
            let currentIndexUnderTest = 3
            let sut = makeSUT(trackCount: 16, currentIndex: currentIndexUnderTest)
            let originalURLs = urls(from: sut.tracks)
            
            let expectedPrefix = prefixURLs(of: originalURLs, count: currentIndexUnderTest)
            let expectedCurrent = originalURLs[currentIndexUnderTest]
            let expectedTailSet = tailURLSet(of: originalURLs, after: currentIndexUnderTest)
            
            sut.shuffle(true)
            let firstShuffleURLs = urls(from: sut.tracks)
            
            sut.shuffle(false)
            let restoredURLs = urls(from: sut.tracks)
            #expect(restoredURLs == originalURLs, "After turning shuffle OFF, order must match the original captured before shuffle")
            
            sut.shuffle(true)
            let secondShuffleURLs = urls(from: sut.tracks)
            
            for shuffledURLs in [firstShuffleURLs, secondShuffleURLs] {
                let shuffledPrefix = prefixURLs(of: shuffledURLs, count: currentIndexUnderTest)
                let shuffledCurrent = shuffledURLs[currentIndexUnderTest]
                let shuffledTailSet = tailURLSet(of: shuffledURLs, after: currentIndexUnderTest)
                
                #expect(shuffledPrefix == expectedPrefix, "Prefix before current must match original in each shuffle")
                #expect(shuffledCurrent == expectedCurrent, "Current must remain pinned at index \(currentIndexUnderTest) in each shuffle")
                #expect(shuffledTailSet == expectedTailSet, "Tail multiset must match original tail in each shuffle")
            }
        }
        
        @Test("OFF (no snapshot) → ON uses fresh base and shuffles tail")
        func offNoSnapshotThenOnReshufflesFromFreshBase() {
            let currentIndex = 2
            let sut = makeSUT(trackCount: 9, currentIndex: currentIndex)
            let base = urls(from: sut.tracks)
            
            sut.shuffle(false)
            sut.shuffle(true)
            
            let shuffled = Array(sut.tracks[(currentIndex + 1)...]).map(\.url)
            let expectedSet = Set(base[(currentIndex + 1)...])
            #expect(Set(shuffled) == expectedSet, "Tail elements must match base tail (permutation)")
            #expect(sut.tracks[currentIndex].url == base[currentIndex], "Current remains pinned after ON")
        }
    }
}
