protocol AudioQueueLoaderDelegate: AnyObject {
    /// The delegate returns how many items are currently in the AVQueuePlayer.
    func currentQueueCount() -> Int
    
    /// Insert a list of items at the end (or after the last item).
    func insertBatchInQueue(_ items: [AudioPlayerItem])
    
    /// Called if we want to fully replace the queue with a fresh batch.
    func setupPlayerQueue(with items: [AudioPlayerItem])
}

final class AudioQueueLoader {
    weak var delegate: (any AudioQueueLoaderDelegate)?
    
    private var remainingTracks: [AudioPlayerItem] = []
    private var pendingBatch: [AudioPlayerItem] = []
    
    /// The size of each batch to be loaded from the `remainingTracks`.
    ///
    /// **How it works:**
    /// 1. When the audio player is first initialized (via `addAllTracks`), the loader will fetch up to `batchSize` tracks for immediate playback.
    /// 2. Afterwards, if the number of tracks in the audio player's queue (i.e., tracks awaiting playback) drops below `queueThreshold`,
    ///    the loader automatically fetches the next `batchSize` tracks and prepares them for insertion.
    ///
    /// **Default behavior:**
    /// - By default, `batchSize` is set to 100 (but can be customized).
    /// - If the queue size falls to `queueThreshold` or lower, the loader requests a new batch of tracks.
    private let batchSize: Int
   
    /// The threshold for the audio player's queue count.
    ///
    /// **How it works:**
    /// 1. Once the audio player’s queue size (the number of tracks awaiting playback) falls to `queueThreshold` or below,
    ///    the loader attempts to fetch a new batch of tracks (see `batchSize`).
    /// 2. If a batch is already preloaded (`pendingBatch`), that batch is inserted immediately; otherwise, a new batch is fetched.
    ///
    /// **Default behavior:**
    /// - By default, `queueThreshold` is set to 50 (but can be customized).
    /// - Whenever the queue size drops to `queueThreshold` or lower, the loader acts to refill the queue.
    private let queueThreshold: Int
    
    private var isPreloading = false
    
    var hasPendingWork: Bool {
        isPreloading || remainingTracks.isNotEmpty || pendingBatch.isNotEmpty
    }
    
    init(
        batchSize: Int = 100,
        queueThreshold: Int = 50
    ) {
        self.batchSize = batchSize
        self.queueThreshold = queueThreshold
    }
    
    /// Adds all tracks to the loader and returns the first batch
    /// so the player can set up its queue immediately.
    func addAllTracks(_ tracks: [AudioPlayerItem]) -> [AudioPlayerItem] {
        remainingTracks = tracks
        return loadNextBatch()
    }
    
    /// Resets the loader to a clean state, clearing remaining tracks and pending batch.
    func reset() {
        isPreloading = false
        remainingTracks.removeAll()
        pendingBatch.removeAll()
    }
    
    /// Starts a background task to preload the next batch into `pendingBatch`.
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
    
    /// Inserts the `pendingBatch` into the delegate's queue and
    /// then prepares another batch if any tracks remain.
    func insertPendingBatch() {
        guard pendingBatch.isNotEmpty else { return }
        
        delegate?.insertBatchInQueue(pendingBatch)
        pendingBatch.removeAll()
        
        prepareNextBatchInBackground()
    }
    
    /// Checks if the queue is below threshold, and if so, inserts a new batch.
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
    
    // MARK: - Private Methods
    
    /// Loads the next `batchSize` items from `remainingTracks`.
    private func loadNextBatch() -> [AudioPlayerItem] {
        guard remainingTracks.isNotEmpty else { return [] }
        
        let batch = Array(remainingTracks.prefix(batchSize))
        remainingTracks.removeFirst(batch.count)
        return batch
    }
    
    private func isQueueBelowThreshold() -> Bool {
        let currentCount = delegate?.currentQueueCount() ?? 0
        return currentCount <= queueThreshold
    }
}
