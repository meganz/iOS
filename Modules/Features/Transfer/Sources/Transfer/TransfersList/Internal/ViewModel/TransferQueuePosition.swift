import MEGADomain

/// Where an in-flight transfer sits on the Active tab.
struct TransferQueuePosition: Comparable, Sendable {
    let isUpload: Bool
    let priority: UInt64
    /// Breaks ties: several transfers of the same file share one queue slot.
    let tag: Int

    init(isUpload: Bool, priority: UInt64, tag: Int) {
        self.isUpload = isUpload
        self.priority = priority
        self.tag = tag
    }

    init(_ transfer: TransferEntity) {
        self.init(isUpload: transfer.type == .upload, priority: transfer.priority, tag: transfer.tag)
    }

    static func < (lhs: TransferQueuePosition, rhs: TransferQueuePosition) -> Bool {
        (lhs.isUpload ? 1 : 0, lhs.priority, lhs.tag) < (rhs.isUpload ? 1 : 0, rhs.priority, rhs.tag)
    }
}

/// The Active tab's two transfer queues. Each is listed and reordered on its own.
enum TransferQueue: Sendable {
    case downloads
    case uploads
}

/// A drag-reorder already applied to the Active tab, waiting to be sent to the SDK.
struct TransferReorder: Sendable {
    let transfer: TransferEntity
    /// The transfer it now runs just before, from the same queue; `nil` when it moved
    /// to the end of its queue.
    let nextTransfer: TransferEntity?
    /// Restored if the SDK rejects the move.
    let previousPosition: TransferQueuePosition
    /// Where the drag put it until the SDK reports the priority it actually assigned.
    let provisionalPosition: TransferQueuePosition
}
