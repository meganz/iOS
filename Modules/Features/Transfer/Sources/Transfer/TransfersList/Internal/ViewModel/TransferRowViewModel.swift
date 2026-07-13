import Foundation
import MEGAAppSDKRepo
import MEGADomain

/// Per-row observable holding the UI state for one transfer. Lives in the
/// `TransferRegistry` keyed by transfer tag. Live updates mutate a single instance,
/// so SwiftUI re-renders only the observing row view, not the whole list.
@MainActor
public final class TransferRowViewModel: ObservableObject, Identifiable {
    /// The SDK transfer tag; stable for the row's lifetime, so it doubles as the
    /// list identity.
    public nonisolated let id: Int

    @Published public private(set) var state: TransferRowState

    private var transfer: TransferEntity
    private let controlUseCase: any TransferControlUseCaseProtocol
    private let rowRouter: any TransferRowRouting
    private let clearTransfersUseCase: any ClearTransfersUseCaseProtocol

    init(
        state: TransferRowState,
        transfer: TransferEntity,
        controlUseCase: some TransferControlUseCaseProtocol,
        rowRouter: some TransferRowRouting,
        clearTransfersUseCase: some ClearTransfersUseCaseProtocol
    ) {
        self.id = state.id
        self.state = state
        self.transfer = transfer
        self.controlUseCase = controlUseCase
        self.rowRouter = rowRouter
        self.clearTransfersUseCase = clearTransfersUseCase
    }

    func update(state: TransferRowState, transfer: TransferEntity) {
        self.state = state
        self.transfer = transfer
    }

    // MARK: - Context actions

    func presentActions() {
        let context = TransferRowActionContext(
            name: state.fileName,
            detail: state.subtitle,
            canViewInFolder: state.canViewInFolder
        )
        rowRouter.presentActions(for: transfer, context: context) { [weak self] in
            self?.clear()
        }
    }

    func openFile() {
        rowRouter.openFile(for: transfer)
    }

    /// Removes this terminal row's entry from the completed-transfers cache.
    /// Reached from the row action sheet and the swipe-to-clear gesture.
    func clear() {
        clearTransfersUseCase.clearTransfer(tag: transfer.tag)
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
