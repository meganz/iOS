protocol AudioQueueLoaderDelegate: AnyObject {
    /// Returns the number of items currently in the AVQueuePlayer.
    func currentQueueCount() -> Int

    /// Inserts a list of AudioPlayerItem objects at the end (or after the last item) of the player's queue.
    func insertBatchInQueue(_ items: [AudioPlayerItem])
}

/// A loader responsible for managing and batching audio tracks for the AVQueuePlayer.
/// The loader takes a list of tracks and delivers them in batches for playback.
/// When the player's queue drops to or below a defined threshold, the loader fetches and inserts the next batch.
/// It supports asynchronous preloading of the next batch and allows the caller to shuffle the remaining tracks on demand.
///
/// **Key Features:**
/// - **Batch Loading:**
///   Returns up to `batchSize` tracks for immediate playback via `addAllTracks(_:)` and refills the queue
///   when the queue count falls to or below `queueThreshold`.
/// - **Asynchronous Preloading:**
///   Preloads the next batch in the background and stores it in `pendingBatch` for quick insertion.
/// - **On-Demand Shuffling:**
///   The caller can call `shuffleTracks()` to randomize the order of the remaining tracks before preloading.
/// - **Customization:**
///   - `batchSize`: Number of tracks loaded per batch (default is 100).
///   - `queueThreshold`: Queue count threshold that triggers loading a new batch (default is 50).
final class AudioQueueLoader {
    weak var delegate: (any AudioQueueLoaderDelegate)?
    
    private var remainingTracks: [AudioPlayerItem] = []
    private var pendingBatch: [AudioPlayerItem] = []
    
    /// The size of each batch to be loaded from the `remainingTracks`.
    /// **How it works:**
    /// 1. On initialization via `addAllTracks(_:)`, the loader returns up to `batchSize` tracks for immediate playback.
    /// 2. When the player's queue count drops to or below `queueThreshold`, a new batch of `batchSize` tracks is fetched.
    private let batchSize: Int
   
    /// The queue count threshold to trigger loading a new batch.
    /// **How it works:**
    /// 1. When the number of tracks awaiting playback falls to `queueThreshold` or below,
    ///    the loader fetches a new batch.
    /// 2. If a preloaded batch (`pendingBatch`) is available, it is inserted immediately.
    private let queueThreshold: Int
    
    /// Indicates whether a background preloading task is in progress.
    private var isPreloading = false
    
    /// Returns `true` if there is any pending work: either preloading is active,
    /// there are remaining tracks, or a preloaded batch is available.
    var hasPendingWork: Bool {
        isPreloading || remainingTracks.isNotEmpty || pendingBatch.isNotEmpty
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
        isPreloading = false
        remainingTracks.removeAll()
        pendingBatch.removeAll()
    }
    
    /// Starts a background task to preload the next batch of tracks. This method checks if preloading is not already in progress and
    /// if there are remaining tracks. It then loads the next batch synchronously and schedules a background task to store it in `pendingBatch`.
    /// If the player's queue is below the threshold when preloading completes, the pending batch is inserted immediately.
    func prepareNextBatchInBackground() {
        guard !isPreloading, remainingTracks.isNotEmpty else { return }
        
        isPreloading = true
        let batchToPreload = loadNextBatch()
        
        Task(priority: .background) { [weak self] in
            guard let self else { return }
            
            pendingBatch = batchToPreload
            isPreloading = false
            
            if isQueueBelowThreshold() {
                insertPendingBatch()
            }
        }
    }
    
    /// Inserts the preloaded batch (`pendingBatch`) into the player's queue via the delegate. After insertion, it clears `pendingBatch`
    /// and starts preloading the subsequent batch.
    func insertPendingBatch() {
        guard pendingBatch.isNotEmpty else { return }
        
        delegate?.insertBatchInQueue(pendingBatch)
        pendingBatch.removeAll()
        
        prepareNextBatchInBackground()
    }
    
    /// Checks if the player's queue is below the threshold and, if so, either inserts the preloaded batch or loads a new batch immediately.
    /// After insertion, it initiates background preloading for the next batch.
    func refillQueueIfNeeded() {
        guard isQueueBelowThreshold() else { return }
        
        if pendingBatch.isNotEmpty {
            insertPendingBatch()
        } else {
            let immediateBatch = loadNextBatch()
            guard immediateBatch.isNotEmpty else { return }
            delegate?.insertBatchInQueue(immediateBatch)
            prepareNextBatchInBackground()
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
        prepareNextBatchInBackground()
    }
    
    // MARK: - Private Methods
    
    /// Loads the next `batchSize` tracks from `remainingTracks`. The tracks are selected in the current order of the `remainingTracks` list.
    /// - Returns: An array of `AudioPlayerItem` containing the next batch.
    private func loadNextBatch() -> [AudioPlayerItem] {
        guard remainingTracks.isNotEmpty else { return [] }
        
        let batch = Array(remainingTracks.prefix(batchSize))
        remainingTracks.removeFirst(batch.count)
        return batch
    }
    
    /// Checks if the current number of items in the player's queue is at or below `queueThreshold`.
    /// - Returns: `true` if the queue count is at or below `queueThreshold`; otherwise, `false`.
    private func isQueueBelowThreshold() -> Bool {
        let currentCount = delegate?.currentQueueCount() ?? 0
        return currentCount <= queueThreshold
    }
}
