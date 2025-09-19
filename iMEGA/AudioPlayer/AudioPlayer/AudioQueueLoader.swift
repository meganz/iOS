@MainActor
protocol AudioQueueLoaderDelegate: AnyObject {
    /// Returns the number of items currently in the AVQueuePlayer.
    func currentQueueCount() -> Int

    /// Inserts a list of AudioPlayerItem objects at the end (or after the last item) of the player's queue.
    func insertBatchInQueue(_ items: [AudioPlayerItem])
}

/// A loader responsible for managing and batching audio tracks for the AVQueuePlayer.
/// The loader takes a list of tracks and delivers them in batches for playback.
/// When the player's queue drops to or below a defined threshold, the loader fetches and inserts the next batch.
/// It supports preloading of the next batch.
///
/// **Key Features:**
/// - **Batch Loading:**
///   Returns up to `batchSize` tracks for immediate playback via `addAllTracks(_:)` and refills the queue when the queue count falls to or below `queueThreshold`.
/// - **Staged Preloading:**
///   Prepares the next batch in advance using `prepareNextBatch()`, storing it in `pendingBatch` so it can be inserted quickly without waiting for load.
/// - **Customization:**
///   - `batchSize`: Number of tracks loaded per batch (default is 100).
///   - `queueThreshold`: Queue count threshold that triggers loading a new batch (default is 50).
@MainActor
final class AudioQueueLoader {
    weak var delegate: (any AudioQueueLoaderDelegate)?
    
    private var remainingTracks: [AudioPlayerItem] = []
    private var pendingBatch: [AudioPlayerItem] = []
    /// The size of each batch to be loaded from the `remainingTracks`.
    /// **How it works:**
    /// 1. On initialization via `addAllTracks(_:)`, the loader returns up to `batchSize` tracks for immediate playback.
    /// 2. When the player's queue count drops to or below `queueThreshold`, a new batch of `batchSize` tracks is fetched.
    private let batchSize: Int
    /// Queue count threshold that triggers loading a new batch.
    /// **How it works:**
    /// 1. When the player's queue count falls to or below this value, the loader either inserts a preloaded batch or immediately loads a new one.
    /// 2. This keeps the playback queue ahead of the player to reduce gaps.
    private let queueThreshold: Int
    
    /// Returns `true` if there are remaining tracks or a preloaded batch ready to insert.
    var hasPendingWork: Bool {
        remainingTracks.isNotEmpty || pendingBatch.isNotEmpty
    }
    
    /// Initializes the loader with a customizable batch size and queue threshold.
    /// - Parameters:
    ///   - batchSize: The number of tracks to load per batch (default is 100).
    ///   - queueThreshold: The queue count threshold that triggers loading a new batch (default is 50).
    init(
        batchSize: Int = 100,
        queueThreshold: Int = 50
    ) {
        self.batchSize = batchSize
        self.queueThreshold = queueThreshold
    }
    
    /// Sets all tracks into the loader and returns the first batch for immediate playback.
    /// - Parameter tracks: An array of `AudioPlayerItem` to load.
    /// - Returns: The first batch of tracks, containing up to `batchSize` items.
    func addAllTracks(_ tracks: [AudioPlayerItem]) -> [AudioPlayerItem] {
        remainingTracks = tracks
        return loadNextBatch()
    }
    
    /// Resets the loader by clearing all remaining tracks and any preloaded batch.
    func reset() {
        remainingTracks.removeAll()
        pendingBatch.removeAll()
    }
    
    /// Prepares the next batch and stores it in `pendingBatch`. If the player's queue is already below the threshold, the pending batch is inserted immediately.
    func prepareNextBatch() {
        guard pendingBatch.isEmpty, remainingTracks.isNotEmpty else { return }
        
        pendingBatch = loadNextBatch()
        
        if isQueueBelowThreshold() {
            insertPendingBatch()
        }
    }
    
    /// Inserts the preloaded batch via the delegate, clears it, then immediately stages the next batch if available.
    func insertPendingBatch() {
        guard pendingBatch.isNotEmpty else { return }
        
        let batch = pendingBatch
        pendingBatch.removeAll()
        
        delegate?.insertBatchInQueue(batch)
        
        /// Immediately prepare the next batch so it’s ready by the time the queue runs low again.
        prepareNextBatch()
    }
    
    /// If the queue is low, inserts a pending batch or loads one immediately, then stages the next preload.
    func refillQueueIfNeeded() {
        guard isQueueBelowThreshold() else { return }
        
        if pendingBatch.isNotEmpty {
            insertPendingBatch()
        } else {
            let immediateBatch = loadNextBatch()
            guard immediateBatch.isNotEmpty else { return }
            
            delegate?.insertBatchInQueue(immediateBatch)
            
            /// Immediately stage the next batch after direct insertion.
            prepareNextBatch()
        }
    }
    
    /// Shuffles the remaining tracks in the loader.
    /// If a preloaded batch exists, it is first appended to the remaining tracks and cleared. The remaining tracks are then randomized,
    /// and background preloading is started.
    func shuffleTracks() {
        if pendingBatch.isNotEmpty {
            remainingTracks.append(contentsOf: pendingBatch)
            pendingBatch.removeAll()
        }
        remainingTracks.shuffle()
        prepareNextBatch()
    }
    
    // MARK: - Private Methods
    
    /// Loads up to `batchSize` tracks from `remainingTracks` and removes them.
    private func loadNextBatch() -> [AudioPlayerItem] {
        guard remainingTracks.isNotEmpty else { return [] }
        
        let batchCount = min(batchSize, remainingTracks.count)
        let batch = Array(remainingTracks.prefix(batchCount))
        remainingTracks.removeFirst(batchCount)
        return batch
    }
    
    /// Returns true if the player's queue count is at or below `queueThreshold`.
    private func isQueueBelowThreshold() -> Bool {
        (delegate?.currentQueueCount() ?? 0) <= queueThreshold
    }
}
