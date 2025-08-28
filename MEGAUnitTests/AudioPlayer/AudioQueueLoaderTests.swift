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
        
        @Test("Returns fewer than batchSize when total tracks are smaller")
        func returnsSmallerFirstBatchWhenNotEnoughTracks() {
            let sut = makeSUT(batchSize: 100)
            let totalTracks = AudioPlayerItem.mockArray(count: 60)
            
            let firstBatch = sut.loader.addAllTracks(totalTracks)
            
            #expect(firstBatch.count == 60)
            #expect(firstBatch.first?.name == "Track 1")
            #expect(firstBatch.last?.name == "Track 60")
            #expect(!sut.loader.hasPendingWork) // no remaining, no pending
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
        @Test("Inserts immediate batch if queue is below threshold")
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
        
        @Test("Shuffles immediate batch when shuffleTracks is called before refilling")
        @MainActor func shufflesImmediateBatch() async throws {
            let sut = makeSUT()
            
            sut.delegate.currentQueue = []
            
            let totalTracks = AudioPlayerItem.mockArray(count: defaultBatchSize)
            _ = sut.loader.addAllTracks(totalTracks)
            sut.loader.shuffleTracks()
           
            try await Task.sleep(nanoseconds: 100_000_000)
            
            sut.loader.refillQueueIfNeeded()
            
            let batch = try #require(sut.delegate.insertedBatches.first, "Should retrieve the correct batch")
            let expectedBatch = Array(totalTracks[100..<150])
            let isShuffled = batch.enumerated().contains { index, item in
                item.name != expectedBatch[index].name
            }
            
            #expect(isShuffled)
        }
        
        @Test("Handles multiple refillQueueIfNeeded calls gracefully")
        func multipleRefillCalls() {
            let sut = makeSUT()
            sut.delegate.currentQueue = []
            _ = sut.loader.addAllTracks(AudioPlayerItem.mockArray(count: defaultBatchSize))
            sut.loader.refillQueueIfNeeded()
            sut.loader.refillQueueIfNeeded() // Second call should not insert duplicate batches.
            #expect(sut.delegate.insertedBatches.count == 1)
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
    
    // MARK: - Tests for prepareNextBatch
    @Suite("PrepareNextBatch")
    struct PrepareNextBatchTests {
        @Test("Stages and inserts pending batch when queue is below threshold (synchronous)")
        func stagesAndInsertsPendingBatchWhenBelowThreshold() throws {
            let sut = makeSUT(batchSize: 100, queueThreshold: 50)
            sut.delegate.currentQueue = [] // trigger immediate insert
            
            _ = sut.loader.addAllTracks(AudioPlayerItem.mockArray(count: defaultBatchSize))
            
            sut.loader.prepareNextBatch()
            
            #expect(sut.delegate.insertedBatches.count == 1)
            let batch = try #require(sut.delegate.insertedBatches.first, "Should have inserted the pending batch")
            #expect(batch.count == 50)
        }
        
        @Test("Does nothing if a pending batch already exists and queue is not below threshold")
        func doesNothingIfPendingBatchExists() {
            let sut = makeSUT(batchSize: 100, queueThreshold: 50)
            sut.delegate.currentQueue = Array(AudioPlayerItem.mockArray(count: 60))
            
            _ = sut.loader.addAllTracks(AudioPlayerItem.mockArray(count: defaultBatchSize))
            sut.loader.prepareNextBatch()
            sut.loader.prepareNextBatch()
            
            #expect(sut.delegate.insertedBatches.isEmpty)
            #expect(sut.loader.hasPendingWork)
        }
    }
    
    // MARK: - Tests for InsertPendingBatch behavior
    @Suite("InsertPendingBatch")
    struct InsertPendingBatchTests {
        @Test("insertPendingBatch clears pending and does not double-insert")
        func insertClearsPendingAndIsIdempotent() {
            let sut = makeSUT(batchSize: 100, queueThreshold: 50)
            sut.delegate.currentQueue = Array(AudioPlayerItem.mockArray(count: 60))
            
            _ = sut.loader.addAllTracks(AudioPlayerItem.mockArray(count: defaultBatchSize))
            sut.loader.prepareNextBatch()
            
            #expect(sut.delegate.insertedBatches.isEmpty)
            
            sut.loader.insertPendingBatch()
            #expect(sut.delegate.insertedBatches.count == 1)
            
            sut.loader.insertPendingBatch()
            #expect(sut.delegate.insertedBatches.count == 1)
        }
        
        @Test("Refill does not duplicate insertion when called twice back-to-back")
        func refillIsIdempotent() {
            let sut = makeSUT(batchSize: 100, queueThreshold: 50)
            sut.delegate.currentQueue = []
            
            _ = sut.loader.addAllTracks(AudioPlayerItem.mockArray(count: defaultBatchSize))
            
            sut.loader.refillQueueIfNeeded()
            sut.loader.refillQueueIfNeeded()
            
            #expect(sut.delegate.insertedBatches.count == 1)
        }
    }
    
    // MARK: - Tests for Reset Behavior
    @Suite("ResetBehavior")
    struct ResetBehaviorTests {
        @Test("Reset clears staged batch and remaining tracks")
        func resetClearsAllWork() {
            let sut = makeSUT()
            _ = sut.loader.addAllTracks(AudioPlayerItem.mockArray(count: defaultBatchSize))
            sut.loader.prepareNextBatch()
            sut.loader.reset()
            #expect(!sut.loader.hasPendingWork)
        }
    }
}
