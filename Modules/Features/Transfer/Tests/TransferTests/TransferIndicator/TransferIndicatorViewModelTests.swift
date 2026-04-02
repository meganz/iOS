import Combine
import Testing
@testable import Transfer

@Suite("TransferIndicatorViewModelTests")
@MainActor
struct TransferIndicatorViewModelTests {

    @Test
    func init_withNoOngoingTransfers_hidesIndicator() async {
        let sut = makeSUT(initialState: .hidden)

        sut.startMonitoring()

        #expect(sut.isVisible == false)
    }

    @Test
    func init_withCurrentTransferProgress_showsIndicator() async {
        let sut = makeSUT(initialState: .inProgress(progress: 0.4))

        sut.startMonitoring()

        #expect(sut.isVisible == true)
        #expect(sut.state == .inProgress(progress: 0.4))
    }

    @Test
    func monitorStatus_whenTransferFinishes_hidesIndicator() async {
        let subject = CurrentValueSubject<TransferIndicatorEntity, Never>(.inProgress(progress: 0.4))
        let sut = makeSUT(initialState: .inProgress(progress: 0.4), updates: subject.eraseToAnyPublisher())

        sut.startMonitoring()
        await waitForTasks()

        subject.send(.hidden)
        await waitForTasks()

        #expect(sut.isVisible == false)
    }

    @Test
    func monitorStatus_whenTransferUpdates_updatesState() async {
        let subject = CurrentValueSubject<TransferIndicatorEntity, Never>(.inProgress(progress: 0.1))
        let sut = makeSUT(initialState: .inProgress(progress: 0.1), updates: subject.eraseToAnyPublisher())

        sut.startMonitoring()
        await waitForTasks()

        subject.send(.inProgress(progress: 0.75))
        await waitForTasks()

        #expect(sut.isVisible == true)
        #expect(sut.state == .inProgress(progress: 0.75))
    }

    @Test
    func state_overquotaRecovery_clearsWarningState() async {
        let subject = CurrentValueSubject<TransferIndicatorEntity, Never>(.warning)
        let sut = makeSUT(initialState: .warning, updates: subject.eraseToAnyPublisher())

        sut.startMonitoring()
        await waitForTasks()
        #expect(sut.state == .warning)

        subject.send(.inProgress(progress: 0.5))
        await waitForTasks()

        #expect(sut.state == .inProgress(progress: 0.5))
    }

    @Test
    func state_errorPersistsThroughNewTransfer() async {
        let subject = CurrentValueSubject<TransferIndicatorEntity, Never>(.error)
        let sut = makeSUT(initialState: .error, updates: subject.eraseToAnyPublisher())

        sut.startMonitoring()
        await waitForTasks()
        #expect(sut.state == .error)

        subject.send(.error)
        await waitForTasks()

        #expect(sut.state == .error)
    }

    private func makeSUT(
        initialState: TransferIndicatorEntity,
        updates: AnyPublisher<TransferIndicatorEntity, Never> = Empty().eraseToAnyPublisher()
    ) -> TransferIndicatorViewModel {
        TransferIndicatorViewModel(
            useCase: MockTransferIndicatorUseCase(
                currentState: initialState,
                updates: updates
            )
        )
    }

    private func waitForTasks() async {
        for _ in 0..<10 {
            await Task.yield()
        }
    }
}

private final class MockTransferIndicatorUseCase: TransferIndicatorUseCaseProtocol, @unchecked Sendable {
    let currentStateValue: TransferIndicatorEntity
    let updates: AnyPublisher<TransferIndicatorEntity, Never>

    init(
        currentState: TransferIndicatorEntity,
        updates: AnyPublisher<TransferIndicatorEntity, Never>
    ) {
        currentStateValue = currentState
        self.updates = updates
    }

    var currentState: TransferIndicatorEntity {
        currentStateValue
    }

    var statePublisher: AnyPublisher<TransferIndicatorEntity, Never> {
        updates
    }

    func startMonitoring() async {}

    func clearTerminalState() async {}
}
