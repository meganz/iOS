import MEGADomain
import MEGASwift
@testable import Transfer

struct MockMonitorTransferTabItemsUseCase: MonitorTransferTabItemsUseCaseProtocol {
    private let snapshotEntities: [TransferEntity]
    private let eventSequence: AnyAsyncSequence<TransferTabEvent>

    init(
        snapshot: [TransferEntity] = [],
        events: AnyAsyncSequence<TransferTabEvent> = [TransferTabEvent]().async.eraseToAnyAsyncSequence()
    ) {
        snapshotEntities = snapshot
        eventSequence = events
    }

    func snapshot(for tab: TransfersTab) async -> [TransferEntity] {
        snapshotEntities
    }

    func events(for tab: TransfersTab) -> AnyAsyncSequence<TransferTabEvent> {
        eventSequence
    }
}
