@testable import MEGA
import Testing

@Suite("AudioQueueLoaderTestSuite")
struct AudioQueueLoaderTestSuite {
    static let defaultBatchSize = 150
    
    // MARK: - Helpers
    static func makeSUT(
        batchSize: Int = 100,
        queueThreshold: Int = 50
    ) -> (loader: AudioQueueLoader, delegate: MockAudioQueueLoaderDelegate) {
        let loader = AudioQueueLoader(batchSize: batchSize, queueThreshold: queueThreshold)
        let delegate = MockAudioQueueLoaderDelegate()
        loader.delegate = delegate
        return (loader, delegate)
    }
    
    // MARK: - Tests for addAllTracks
    @Suite("AddAllTracks")
    struct AddAllTracksTests {
        @Test("Returns first batch with correct size and contents")
        func returnsCorrectFirstBatch() {
            let sut = makeSUT()
            let totalTracks = AudioPlayerItem.mockArray(count: defaultBatchSize)
            
            let firstBatch = sut.loader.addAllTracks(totalTracks)
            
            #expect(firstBatch.count == 100)
            #expect(firstBatch.first?.name == "Track 1")
            #expect(firstBatch.last?.name == "Track 100")
            #expect(sut.loader.hasPendingWork)
        }
    }
    
    // MARK: - Tests for reset
    @Suite("Reset")
    struct ResetTests {
        @Test("Clears internal state and pending work")
        func clearsInternalState() {
            let sut = makeSUT()
            let totalTracks = AudioPlayerItem.mockArray(count: defaultBatchSize)
            _ = sut.loader.addAllTracks(totalTracks)
            
            sut.loader.reset()
            #expect(!sut.loader.hasPendingWork)
        }
    }
    
    // MARK: - Tests for refillQueueIfNeeded
    @Suite("RefillQueueIfNeeded")
    struct RefillQueueIfNeededTests {
        @Test("Inserts immediate batch if queue is below threshold and no pending batch exists")
        func insertsImmediateBatch() throws {
            let sut = makeSUT()
            
            sut.delegate.currentQueue = []
            
            _ = sut.loader.addAllTracks(AudioPlayerItem.mockArray(count: defaultBatchSize))
            sut.loader.refillQueueIfNeeded()
            
            #expect(sut.delegate.insertedBatches.count == 1)
            let batch = try #require(sut.delegate.insertedBatches.first, "Should retrieve the correct batch")
            #expect(batch.count == 50)
            #expect(batch.first?.name == "Track 101")
            #expect(batch.last?.name == "Track 150")
        }
    }
    
    // MARK: - Tests for prepareNextBatchInBackground
    @Suite("PrepareNextBatchInBackground")
    struct PrepareNextBatchInBackgroundTests {
        @Test("Asynchronously inserts pending batch when queue is below threshold")
        func insertsPendingBatch() async throws {
            let expectedBatchSize = 50
            let sut = makeSUT(batchSize: expectedBatchSize, queueThreshold: 10)
            sut.delegate.currentQueue = []
            
            _ = await sut.loader.addAllTracks(AudioPlayerItem.mockArray(count: 120))
            sut.delegate.currentQueue = []
            
            sut.loader.prepareNextBatchInBackground()
            
            try await Task.sleep(nanoseconds: 500_000_000)
            
            #expect(sut.delegate.insertedBatches.count >= 1)
            
            let batch = try #require(sut.delegate.insertedBatches.first, "Should retrieve the correct batch")
            #expect(batch.count == expectedBatchSize)
            await #expect(batch.first?.name == "Track 51")
            await #expect(batch.last?.name == "Track 100")
            
        }
    }
    
    // MARK: - Tests for hasPendingWork
    @Suite("HasPendingWork")
    struct HasPendingWorkTests {
        @Test("Reflects the internal state correctly")
        func pendingWorkState() {
            let sut = makeSUT()
            #expect(!sut.loader.hasPendingWork)
            
            _ = sut.loader.addAllTracks(AudioPlayerItem.mockArray(count: defaultBatchSize))
            #expect(sut.loader.hasPendingWork)
            
            sut.loader.reset()
            #expect(!sut.loader.hasPendingWork)
        }
    }
}
