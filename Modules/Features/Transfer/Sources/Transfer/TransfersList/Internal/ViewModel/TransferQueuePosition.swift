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
