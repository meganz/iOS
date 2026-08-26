import Foundation
import MEGAAppSDKRepo
import MEGADomain
import UIKit

/// Per-row observable holding the UI state for one transfer. Lives in the
/// `TransferRegistry` keyed by transfer tag. Live updates mutate a single instance,
/// so SwiftUI re-renders only the observing row view, not the whole list.
@MainActor
public final class TransferRowViewModel: ObservableObject, Identifiable {
    /// The SDK transfer tag; stable for the row's lifetime, so it doubles as the
    /// list identity.
    public nonisolated let id: Int

    @Published public private(set) var state: TransferRowState
    @Published public private(set) var thumbnail: UIImage?
    @Published private(set) var thumbnailRetryTrigger = 0

    private var transfer: TransferEntity
    private let controlUseCase: any TransferControlUseCaseProtocol
    private let rowRouter: any TransferRowRouting
    private let clearTransfersUseCase: any ClearTransfersUseCaseProtocol
    private let thumbnailLoader: TransferThumbnailLoader
    
    private var hasResolvedThumbnail = false

    init(
        state: TransferRowState,
        transfer: TransferEntity,
        controlUseCase: some TransferControlUseCaseProtocol,
        rowRouter: some TransferRowRouting,
        clearTransfersUseCase: some ClearTransfersUseCaseProtocol,
        thumbnailLoader: TransferThumbnailLoader
    ) {
        self.id = state.id
        self.state = state
        self.transfer = transfer
        self.controlUseCase = controlUseCase
        self.rowRouter = rowRouter
        self.clearTransfersUseCase = clearTransfersUseCase
        self.thumbnailLoader = thumbnailLoader
    }

    func update(state: TransferRowState, transfer: TransferEntity) {
        let wasInFlight = !isTerminal(self.state.status)
        self.state = state
        self.transfer = transfer
        // Completed only: the staged file is deleted on success, so the entry is
        // re-keyed to the created node's handle. Failed/cancelled uploads keep
        // theirs — the staged file typically still exists and a retry can re-hit.
        if wasInFlight, state.status == .completed, transfer.type == .upload, let path = transfer.path {
            thumbnailLoader.migrateUploadThumbnail(fromPath: path, toNodeHandle: transfer.nodeHandle)
            // Completion creates the node, so a miss while in-flight (e.g. QuickLook
            // couldn't represent the file) is no longer definitive: allow one retry
            // against the node's thumbnail and restart the row's load task.
            if thumbnail == nil {
                hasResolvedThumbnail = false
                thumbnailRetryTrigger += 1
            }
        }
    }

    // MARK: - Thumbnail

    func loadThumbnail() async {
        guard !hasResolvedThumbnail else { return }
        do {
            let image = try await thumbnailLoader.image(for: transfer)
            guard !Task.isCancelled else { return }
            hasResolvedThumbnail = true
            thumbnail = image
        } catch is CancellationError {
            return
        } catch {
            // Transient failure (e.g. fetch while offline): stay unresolved so the
            // next row appearance retries. Definitive misses return nil above and
            // they never re-fetch.
            MEGALogWarning("[Transfer] thumbnail load failed for tag \(transfer.tag), will retry on next appearance: \(error)")
        }
    }

    private func isTerminal(_ status: TransferRowState.Status) -> Bool {
        switch status {
        case .completed, .failed, .cancelled: true
        case .queued, .active, .paused: false
        }
    }

    // MARK: - Context actions

    /// Presents the per-row action sheet. `onRetried` is invoked after the sheet's
    /// Retry action lands in the engine, so the screen can show the retry snackbar.
    ///
    /// - Parameter isOffline: strips the sheet's mutating entries. Retry needs a
    ///   connection, and Clear is withheld to match the select-mode Clear button, so the
    ///   sheet can't be used to do what the bulk action for the same thing refuses.
    ///   Non-mutating entries (View in folder, Open with, Share link) are left alone.
    func presentActions(isOffline: Bool, onRetried: @MainActor @escaping () -> Void) {
        let context = TransferRowActionContext(
            name: state.fileName,
            detail: state.subtitle,
            canViewInFolder: state.canViewInFolder,
            canRetry: state.isRetryable && !isOffline,
            canClear: !isOffline
        )
        rowRouter.presentActions(
            for: transfer,
            context: context,
            onRetry: { [weak self] in
                // A deallocated VM means the row is gone; don't retry on its behalf.
                guard let self else { return }
                Task {
                    guard await self.retry() else { return }
                    onRetried()
                }
            },
            onClear: { [weak self] in
                self?.clear()
            }
        )
    }

    func openFile() {
        rowRouter.openFile(for: transfer)
    }

    /// Removes this terminal row's entry from the completed-transfers cache.
    /// Reached from the row action sheet and the swipe-to-clear gesture.
    func clear() {
        clearTransfersUseCase.clearTransfer(tag: transfer.tag)
    }

    /// Re-queues this failed/cancelled transfer, then clears its Failed-tab entry —
    /// in that order, because retry resolves the transfer from the completed-transfers
    /// cache. Returns whether the retry landed, so the caller can show the snackbar;
    /// on failure nothing is cleared and the row stays.
    func retry() async -> Bool {
        do {
            try await controlUseCase.retryTransfer(transfer)
            clearTransfersUseCase.clearTransfer(tag: transfer.tag)
            return true
        } catch {
            MEGALogError("[Transfer] retry failed for tag \(transfer.tag): \(error)")
            return false
        }
    }

    /// Cancels this in-flight transfer. Returns the entity for undo orchestration,
    /// or `nil` when the engine rejected the cancel (the row stays as is).
    func cancel() async -> TransferEntity? {
        do {
            try await controlUseCase.cancelTransfer(transfer)
            return transfer
        } catch {
            MEGALogError("[Transfer] cancel failed for tag \(transfer.tag): \(error)")
            return nil
        }
    }

    // MARK: - Pause / resume

    func togglePauseResume() async {
        do {
            switch state.status {
            case .active, .queued:
                try await controlUseCase.pauseTransfer(transfer)
                state.status = .paused
            case .paused:
                try await controlUseCase.resumeTransfer(transfer)
                state.status = .active
            case .completed, .failed, .cancelled:
                break
            }
        } catch {
            let action = state.status == .paused ? "resume" : "pause"
            MEGALogError("[Transfer] \(action) failed for tag \(transfer.tag): \(error)")
        }
    }
}
