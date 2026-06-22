import Foundation
import MEGADomain
import Search

/// Side-channel store of per-row view models keyed by `ResultId`.
///
/// `SearchResult` is a value type with no slot for transfer state, and
/// `SearchResultRowViewModel.result` is not `@Published`. The registry is the
/// load-bearing piece that makes per-row live updates O(1): `rowBuilder` resolves
/// the per-row VM by id, and mutations to that VM trigger a re-render of only
/// the observing row.
@MainActor
final class TransferRegistry {
    private var rowViewModelsById: [ResultId: TransferRowViewModel] = [:]
    private let controlUseCase: any TransferControlUseCaseProtocol

    init(controlUseCase: some TransferControlUseCaseProtocol) {
        self.controlUseCase = controlUseCase
    }

    func rowViewModel(for id: ResultId) -> TransferRowViewModel? {
        rowViewModelsById[id]
    }

    func upsert(_ state: TransferRowState, transfer: TransferEntity) {
        if let existing = rowViewModelsById[state.id] {
            existing.update(state: state, transfer: transfer)
        } else {
            rowViewModelsById[state.id] = TransferRowViewModel(
                state: state,
                transfer: transfer,
                controlUseCase: controlUseCase
            )
        }
    }

    @discardableResult
    func remove(id: ResultId) -> TransferRowViewModel? {
        rowViewModelsById.removeValue(forKey: id)
    }

    func clear() {
        rowViewModelsById.removeAll()
    }

    var ids: [ResultId] {
        Array(rowViewModelsById.keys)
    }
}
