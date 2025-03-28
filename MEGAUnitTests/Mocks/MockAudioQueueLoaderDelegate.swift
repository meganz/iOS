@testable import MEGA

final class MockAudioQueueLoaderDelegate: AudioQueueLoaderDelegate {
    var insertedBatches: [[AudioPlayerItem]] = []
    var currentQueue: [AudioPlayerItem] = []
    
    func currentQueueCount() -> Int {
        currentQueue.count
    }
    
    func insertBatchInQueue(_ items: [AudioPlayerItem]) {
        insertedBatches.append(items)
        currentQueue.append(contentsOf: items)
    }
}
