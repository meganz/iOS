import MEGADomain

/// One item's standing in a batch upload, as of the last transfer callback seen for it.
///
/// A snapshot of where the item is in its lifecycle, not a measure of how much of it has moved:
/// the batch reports no byte counts, only whether it has started transferring and whether it has
/// finished. Items report these to `BatchUploadAggregator`, which is the only thing that keeps a
/// running picture.
struct BatchUploadItemStatus: Sendable {
    enum Phase: Sendable {
        case none
        case transferring(TransferEventEntity)
        case failed(any Error)
    }
    
    let index: Int
    /// Whether the item is a file rather than a folder. Decides when it counts as started.
    let isFile: Bool
    let phase: Phase
    
    /// Whether the item has started transferring: past the point where the SDK might still not
    /// have queued it.
    ///
    /// - A file has started as soon as its transfer starts, so any event at all counts.
    /// - A folder has started only once its scan has ended and the SDK has moved on to the files
    ///   it found, which a `.folderUpdate` or an `.update` reports as the `.transferringFiles`
    ///   stage. A folder's own `.start` says only that the scan began.
    /// - An item that has ended, whether it succeeded or failed, counts as started too: there is
    ///   nothing left to wait for.
    var hasStartedTransferring: Bool {
        switch phase {
        case .none:
            return false
        case let .transferring(event):
            switch event {
            case .start:
                return isFile
            case let .folderUpdate(folderTransferUpdateEntity):
                return folderTransferUpdateEntity.stage >= .transferringFiles
            case let .update(transferEntity):
                return isFile || transferEntity.stage >= .transferringFiles
            case .finish:
                return true
            }
        case .failed:
            return true
        }
    }
    
    /// Whether the item has finished, by either route.
    ///
    /// - A transfer has finished when it reports `.finish`. For a folder that is the whole tree,
    ///   not the first file in it.
    /// - A failed item has finished too: nothing further is reported for it once its error
    ///   arrives.
    var hasFinishedTransferring: Bool {
        switch phase {
        case .none:
            return false
        case let .transferring(event):
            switch event {
            case .start, .folderUpdate, .update:
                return false
            case .finish:
                return true
            }
        case .failed:
            return true
        }
    }
    
    var error: (any Error)? {
        switch phase {
        case .none, .transferring:
            return nil
        case .failed(let error):
            return error
        }
    }
    
    init(index: Int, isFile: Bool, phase: Phase) {
        self.index = index
        self.isFile = isFile
        self.phase = phase
    }
}
