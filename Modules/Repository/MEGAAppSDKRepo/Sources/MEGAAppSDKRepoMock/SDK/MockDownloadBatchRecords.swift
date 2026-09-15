import MEGAAppSDKRepo
import MEGASdk

/// One item of a batch download, as the SDK received it.
///
/// The repository builds a `MEGADownloadItemList` out of what the Domain layer asked for, and what
/// it put in each slot is the only record of how a destination was spelled by the time it left the
/// app -- which is what decides where the file lands.
public struct MockDownloadBatchItem: Equatable, Sendable {
    /// `nil` for a mock node, which has no C++ node behind it for the list to keep a copy of.
    public let nodeHandle: UInt64?
    public let localPath: String?
    public let customName: String?
    public let appData: String?
    public let startFirst: Bool
    public let undelete: Bool
}

/// Everything `MockSdk` keeps about the batch downloads it has been handed.
///
/// A class of its own, and locked, because the repository starts a batch from a task of its own
/// while the test reads the record from another.
final class MockDownloadBatchRecords: @unchecked Sendable {
    private let lock = NSLock()
    private var batches: [[MockDownloadBatchItem]] = []
    private var cancelTokens: [MEGACancelToken] = []

    var startedBatches: [[MockDownloadBatchItem]] {
        lock.withLock { batches }
    }

    var startedCancelTokens: [MEGACancelToken] {
        lock.withLock { cancelTokens }
    }

    func record(_ items: MEGADownloadItemList, cancelToken: MEGACancelToken?) {
        let batch = (0..<items.size).map { index in
            MockDownloadBatchItem(
                nodeHandle: items.node(at: index)?.handle,
                localPath: items.localPath(at: index),
                customName: items.customName(at: index),
                appData: items.appData(at: index),
                startFirst: items.startFirst(at: index),
                undelete: items.undelete(at: index)
            )
        }
        lock.withLock {
            batches.append(batch)
            if let cancelToken {
                cancelTokens.append(cancelToken)
            }
        }
    }
}
