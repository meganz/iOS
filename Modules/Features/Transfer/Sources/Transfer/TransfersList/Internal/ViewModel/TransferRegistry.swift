import Foundation
import MEGADomain

/// Store of per-row view models keyed by transfer tag, shared across the three
/// tab list view models.
///
/// The registry is the load-bearing piece that makes per-row live updates O(1):
/// the tab's list view model resolves the per-row VM by tag, and mutations to
/// that VM trigger a re-render of only the observing row.
@MainActor
final class TransferRegistry {
    private var rowViewModelsById: [Int: TransferRowViewModel] = [:]
    private let controlUseCase: any TransferControlUseCaseProtocol
    private let rowRouter: any TransferRowRouting
    private let clearTransfersUseCase: any ClearTransfersUseCaseProtocol
    private let thumbnailLoader: TransferThumbnailLoader

    init(
        controlUseCase: some TransferControlUseCaseProtocol,
        rowRouter: some TransferRowRouting,
        clearTransfersUseCase: some ClearTransfersUseCaseProtocol,
        thumbnailLoader: TransferThumbnailLoader
    ) {
        self.controlUseCase = controlUseCase
        self.rowRouter = rowRouter
        self.clearTransfersUseCase = clearTransfersUseCase
        self.thumbnailLoader = thumbnailLoader
    }

    func rowViewModel(for id: Int) -> TransferRowViewModel? {
        rowViewModelsById[id]
    }

    func upsert(_ state: TransferRowState, transfer: TransferEntity) {
        if let existing = rowViewModelsById[state.id] {
            existing.update(state: state, transfer: transfer)
        } else {
            rowViewModelsById[state.id] = TransferRowViewModel(
                state: state,
                transfer: transfer,
                controlUseCase: controlUseCase,
                rowRouter: rowRouter,
                clearTransfersUseCase: clearTransfersUseCase,
                thumbnailLoader: thumbnailLoader
            )
        }
    }

    @discardableResult
    func remove(id: Int) -> TransferRowViewModel? {
        rowViewModelsById.removeValue(forKey: id)
    }

    func clear() {
        rowViewModelsById.removeAll()
    }

    var ids: [Int] {
        Array(rowViewModelsById.keys)
    }
}
