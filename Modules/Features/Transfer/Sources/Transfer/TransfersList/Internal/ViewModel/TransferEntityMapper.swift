import Foundation
import MEGADomain

/// Maps `TransferEntity` from the Domain layer into `TransferRowState`, the UI
/// payload stored in the per-row VM inside `TransferRegistry`; it carries the
/// fields the row view actually renders. Carries raw values only — the subtitle
/// is composed lazily by `TransferRowState` at render time.
public enum TransferEntityMapper {

    /// - Parameter location: file system path for the Completed row's second line,
    ///   resolved by the Data adapter (upload destination cloud path or download
    ///   local folder). `nil` for tabs that don't render it.
    /// - Parameter finishDate: the wall-clock instant the transfer finished,
    ///   captured live by `SharedTransferFinishRecorder`. Do not derive it from
    ///   `TransferEntity.updateTime`; SDK transfer update time has no defined epoch.
    /// - Parameter canViewInFolder: whether the Completed row should offer
    ///   `View in folder`.
    /// - Parameter isRetryable: whether the row should offer Retry, decided by
    ///   `TransferRetryPolicy` at the call site. No default on purpose: every
    ///   caller must decide explicitly.
    public static func rowState(
        for entity: TransferEntity,
        location: String? = nil,
        finishDate: Date? = nil,
        canViewInFolder: Bool = true,
        isRetryable: Bool
    ) -> TransferRowState {
        let status = status(for: entity.state)
        let direction = direction(for: entity.type)
        var state = TransferRowState(
            id: entity.tag,
            fileName: entity.fileName ?? "Transfer #\(entity.tag)",
            direction: direction,
            status: status,
            progress: progress(for: entity),
            transferredBytes: Int64(entity.transferredBytes),
            totalBytes: Int64(entity.totalBytes),
            speed: Int64(entity.speed),
            finishDate: finishDate,
            errorDescription: entity.lastErrorExtended.map { String(describing: $0) },
            location: location,
            canViewInFolder: canViewInFolder
        )
        state.isRetryable = isRetryable
        return state
    }

    private static func direction(for type: TransferTypeEntity) -> TransferRowState.Direction {
        type == .upload ? .upload : .download
    }

    private static func status(for state: TransferStateEntity) -> TransferRowState.Status {
        switch state {
        case .none, .queued: .queued
        case .active, .retrying, .completing: .active
        case .paused: .paused
        case .complete: .completed
        case .failed: .failed
        case .cancelled: .cancelled
        }
    }

    private static func progress(for entity: TransferEntity) -> Double {
        guard entity.totalBytes > 0 else { return 0 }
        return min(1.0, Double(entity.transferredBytes) / Double(entity.totalBytes))
    }
}
