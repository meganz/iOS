import MEGAFoundation
import MEGASwift

/// Turns the transfer events of a batch into the states a cancellable transfer screen shows.
///
/// Both batch use cases, `CancellableUploadTransferUseCase` and
/// `CancellableDownloadTransferUseCase`, read their batch the same way, so they share the
/// mapping instead of each spelling it out.
public protocol CancellableTransferStateMapping: Sendable {
    /// Reads a batch's transfer events as the state of that batch.
    ///
    /// - Parameter events: Starts the batch and returns its events. A closure rather than a
    ///   sequence, so that the batch is handed over from inside the mapping, once, whatever the
    ///   caller then does with the states.
    /// - Returns: A sequence of the batch's progress ended by exactly one terminal state,
    ///   `.transferringFiles` or `.failed`, after which it finishes. It does not throw: an error
    ///   is a state of the batch like any other, and the screen reads it as one.
    func map(
        from events: @escaping @Sendable () -> AnyAsyncThrowingSequence<TransferEventEntity, any Error>
    ) -> AnyAsyncSequence<CancellableTransferStateEntity>
}

/// Reads a batch as a whole from the events of the single transfer it is reported as.
///
/// What it takes from those events:
/// - a folder update in the `scan` stage becomes `.scanning`: the batch is still being sized up;
/// - one in the `createTree` stage becomes `.creatingFolders`: its folder tree is being recreated;
/// - one in the `transferringFiles` stage becomes `.transferringFiles` and ends the mapping, since
///   every item of the batch has started and that is the last thing the screen waits for;
///
/// Running out of events without ever reaching the transferring stage means the same as reaching
/// it, so that ends on `.transferringFiles` too. An error ends the mapping on `.failed`.
public struct CancellableTransferStateMapper: CancellableTransferStateMapping {
    public enum Kind: Sendable, CustomStringConvertible {
        case upload, download

        public var description: String {
            switch self {
            case .upload:
                "Upload"
            case .download:
                "Download"
            }
        }
    }

    private let kind: Kind

    public init(kind: Kind) {
        self.kind = kind
    }

    public func map(
        from events: @escaping @Sendable () -> AnyAsyncThrowingSequence<TransferEventEntity, any Error>
    ) -> AnyAsyncSequence<CancellableTransferStateEntity> {
        AsyncStream { continuation in
            let task = Task {
                do {
                    mainLoop: for try await event in events() {
                        guard case let .folderUpdate(update) = event else { continue }
                        switch update.stage {
                        case .scan:
                            MEGALog.log(
                                level: .info,
                                message: "[CancellableTransfer] Batch transfer kind \(kind) scanning \(update.folderCount) folders, \(update.fileCount) files"
                            )
                            continuation.yield(
                                .scanning(
                                    name: update.transfer.fileName ?? "",
                                    folderCount: update.folderCount,
                                    fileCount: update.fileCount
                                )
                            )
                        case .createTree:
                            MEGALog.log(
                                level: .info,
                                message: "[CancellableTransfer] Batch transfer kind \(kind) creatingTree \(update.createdFolderCount)  / \(update.folderCount)"
                            )
                            continuation.yield(
                                .creatingFolders(
                                    created: update.createdFolderCount,
                                    total: update.folderCount
                                )
                            )
                        case .transferringFiles:
                            MEGALog.log(level: .info, message: "[CancellableTransfer] Batch transfer kind \(kind) reached its transferring stage")
                            break mainLoop
                        case .none:
                            break
                        }
                    }
                    // Reaching the transferring stage and running out of events mean the same
                    // thing: every item of the batch has started transferring
                    MEGALog.log(level: .info, message: "[CancellableTransfer] Batch transfer kind \(kind) stopped reading events")
                    continuation.yield(.transferringFiles)
                    continuation.finish()
                } catch {
                    MEGALog.log(level: .error, message: "[CancellableTransfer] Batch transfer kind \(kind) failed: \(error)")
                    continuation.yield(.failed)
                    continuation.finish()
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }.eraseToAnyAsyncSequence()
    }
}
