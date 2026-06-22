import Foundation
import MEGAAppSDKRepo
import MEGADomain
import Search

/// Per-row observable holding the UI state for one transfer. Lives in the
/// `TransferRegistry` keyed by `ResultId`. Live updates mutate a single instance,
/// so SwiftUI re-renders only the observing row view, not the whole list.
@MainActor
public final class TransferRowViewModel: ObservableObject {
    @Published public private(set) var state: TransferRowState

    private var transfer: TransferEntity
    private let controlUseCase: any TransferControlUseCaseProtocol

    init(
        state: TransferRowState,
        transfer: TransferEntity,
        controlUseCase: some TransferControlUseCaseProtocol
    ) {
        self.state = state
        self.transfer = transfer
        self.controlUseCase = controlUseCase
    }

    func update(state: TransferRowState, transfer: TransferEntity) {
        self.state = state
        self.transfer = transfer
    }
    
    func togglePauseResume() async {
        do {
            switch state.status {
            case .active, .queued:
                try await controlUseCase.pauseTransfer(transfer)
                state = TransferEntityMapper.rowState(state, status: .paused)
            case .paused:
                try await controlUseCase.resumeTransfer(transfer)
                state = TransferEntityMapper.rowState(state, status: .active)
            case .completed, .failed, .cancelled:
                break
            }
        } catch {
            let action = state.status == .paused ? "resume" : "pause"
            MEGALogError("[Transfer] \(action) failed for tag \(transfer.tag): \(error)")
        }
    }
}
