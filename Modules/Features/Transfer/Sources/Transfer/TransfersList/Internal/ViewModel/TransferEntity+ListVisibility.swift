import MEGADomain

/// List-visibility rules for the Transfers screen, scoped to this feature.
///
/// These predicates encode UI semantics (which transfers render on each tab),
/// not intrinsic domain truths, so they live in the feature module rather than
/// alongside `TransferEntity` in `MEGADomain`.
extension TransferEntity {

    /// Folder and streaming transfers are excluded so the snapshot stays in sync
    /// with `TransferCounterUseCase`, which filters them out of its delegate streams.
    var isVisibleInList: Bool {
        !isFolderTransfer && !isStreamingTransfer
    }

    var isVisibleOnActiveTab: Bool {
        guard isVisibleInList else { return false }
        switch state {
        case .none, .queued, .active, .paused, .retrying, .completing: return true
        case .complete, .cancelled, .failed: return false
        }
    }

    /// Whether this transfer would render as a row on the Completed tab.
    var isVisibleOnCompletedTab: Bool {
        isVisibleInList && state == .complete
    }

    /// Whether this transfer would render as a row on the Failed tab. Includes
    /// both failed and cancelled transfers.
    var isVisibleOnFailedTab: Bool {
        isVisibleInList && (state == .failed || state == .cancelled)
    }
}
