import AsyncAlgorithms
import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing
@testable import Transfer

@Suite("MonitorTransferTabPresenceUseCase")
struct MonitorTransferTabPresenceUseCaseTests {

    @Test func emitsSeedPresenceFromInventory() async {
        let sut = makeSUT(
            inventory: MockTransferInventoryUseCase(
                completedTransfers: [.init(type: .download, tag: 1, state: .complete)]
            )
        )

        let values = await collect(sut)

        #expect(values == [TransferTabPresence(hasActive: false, hasCompleted: true, hasFailed: false)])
    }

    @Test func dedupesWhenPresenceUnchanged() async {
        // Empty inventory: start/finish events fire, but presence never changes.
        let sut = makeSUT(
            inventory: MockTransferInventoryUseCase(),
            startUpdates: [.init(type: .upload, tag: 1, state: .active)],
            finishUpdates: [.init(type: .download, tag: 2, state: .failed)]
        )

        let values = await collect(sut)

        #expect(values == [.none]) // seed only; no further emissions
    }

    @Test func ignoresProgressAndTemporaryErrorEvents() async {
        let sut = makeSUT(
            inventory: MockTransferInventoryUseCase(transfers: [.init(type: .upload, tag: 1, state: .active)]),
            progressUpdates: [.init(type: .upload, tag: 1, state: .active)],
            temporaryErrors: [.init(type: .upload, tag: 1, state: .retrying)]
        )

        let values = await collect(sut)

        // Seed reflects the active transfer; progress/temporary-error cause no re-derive.
        #expect(values == [TransferTabPresence(hasActive: true, hasCompleted: false, hasFailed: false)])
    }

    @Test func reEmitsWhenPresenceChangesAfterFinish() async {
        // Active before the finish event, failed after it (inventory changes per snapshot).
        let inventory = SequencedInventory(
            transfersByCall: [[.init(type: .download, tag: 1, state: .active)], []],
            completedByCall: [[], [.init(type: .download, tag: 1, state: .failed)]]
        )
        let sut = makeSUT(inventory: inventory, finishUpdates: [.init(type: .download, tag: 1, state: .failed)])

        let values = await collect(sut)

        #expect(values == [
            TransferTabPresence(hasActive: true, hasCompleted: false, hasFailed: false),
            TransferTabPresence(hasActive: false, hasCompleted: false, hasFailed: true)
        ])
    }

    // MARK: - Helpers

    private func makeSUT(
        inventory: some TransferInventoryUseCaseProtocol,
        startUpdates: [TransferEntity] = [],
        finishUpdates: [TransferEntity] = [],
        progressUpdates: [TransferEntity] = [],
        temporaryErrors: [TransferEntity] = []
    ) -> MonitorTransferTabPresenceUseCase {
        MonitorTransferTabPresenceUseCase(
            inventoryUseCase: inventory,
            counterUseCase: MockTransferCounterUseCase(
                transferStartUpdates: startUpdates.async.eraseToAnyAsyncSequence(),
                transferUpdates: progressUpdates.async.eraseToAnyAsyncSequence(),
                transferTemporaryErrorUpdates: responses(temporaryErrors),
                transferFinishUpdates: responses(finishUpdates)
            ),
            clearTransfersUseCase: MockClearTransfersUseCase(),
            filteringUserTransfers: true
        )
    }

    private func collect(_ sut: MonitorTransferTabPresenceUseCase) async -> [TransferTabPresence] {
        var values: [TransferTabPresence] = []
        for await value in sut.presenceUpdates {
            values.append(value)
        }
        return values
    }

    private func responses(_ entities: [TransferEntity]) -> AnyAsyncSequence<TransferResponseEntity> {
        entities
            .map { TransferResponseEntity(transferEntity: $0, error: ErrorEntity(type: .ok)) }
            .async
            .eraseToAnyAsyncSequence()
    }
}

/// Returns a different inventory snapshot on each call, to model a transfer moving
/// between states across re-derives.
private final class SequencedInventory: TransferInventoryUseCaseProtocol, @unchecked Sendable {
    private let transfersByCall: [[TransferEntity]]
    private let completedByCall: [[TransferEntity]]
    private var transfersCall = 0
    private var completedCall = 0

    init(transfersByCall: [[TransferEntity]], completedByCall: [[TransferEntity]]) {
        self.transfersByCall = transfersByCall
        self.completedByCall = completedByCall
    }

    func transfers(filteringUserTransfers: Bool) -> [TransferEntity] { next(&transfersCall, transfersByCall) }
    func transfers(filteringUserTransfers: Bool) async -> [TransferEntity] { next(&transfersCall, transfersByCall) }
    func downloadTransfers(filteringUserTransfers: Bool) -> [TransferEntity] { [] }
    func uploadTransfers(filteringUserTransfers: Bool) -> [TransferEntity] { [] }
    func completedTransfers(filteringUserTransfers: Bool) -> [TransferEntity] { next(&completedCall, completedByCall) }
    func documentsDirectory() -> URL { URL(fileURLWithPath: "/tmp") }
    func areThereAnyTransferWithAppData(matching filter: @escaping (String) -> Bool) -> Bool { false }

    private func next(_ call: inout Int, _ values: [[TransferEntity]]) -> [TransferEntity] {
        let index = min(call, values.count - 1)
        call += 1
        return values[index]
    }
}
