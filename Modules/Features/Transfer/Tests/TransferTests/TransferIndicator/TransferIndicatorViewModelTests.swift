import Combine
import Testing
@testable import Transfer

@Suite("TransferIndicatorViewModelTests")
@MainActor
struct TransferIndicatorViewModelTests {

    @Test
    func init_withNoOngoingTransfers_hidesIndicator() {
        let sut = makeSUT(initialState: .hidden)

        sut.startMonitoring()

        #expect(sut.isVisible == false)
    }

    @Test
    func init_withCurrentTransferProgress_showsIndicator() {
        let sut = makeSUT(initialState: .inProgress(progress: 0.4))

        sut.startMonitoring()

        #expect(sut.isVisible == true)
        #expect(sut.state == .inProgress(progress: 0.4))
    }

    @Test
    func monitorStatus_whenTransferFinishes_hidesIndicator() {
        let subject = CurrentValueSubject<TransferIndicatorEntity, Never>(.inProgress(progress: 0.4))
        let sut = makeSUT(initialState: .inProgress(progress: 0.4), updates: subject.eraseToAnyPublisher())

        sut.startMonitoring()
        subject.send(.hidden)

        #expect(sut.isVisible == false)
    }

    @Test
    func monitorStatus_whenTransferUpdates_updatesState() {
        let subject = CurrentValueSubject<TransferIndicatorEntity, Never>(.inProgress(progress: 0.1))
        let sut = makeSUT(initialState: .inProgress(progress: 0.1), updates: subject.eraseToAnyPublisher())

        sut.startMonitoring()
        subject.send(.inProgress(progress: 0.75))

        #expect(sut.isVisible == true)
        #expect(sut.state == .inProgress(progress: 0.75))
    }

    @Test
    func state_overquotaRecovery_clearsWarningState() {
        let subject = CurrentValueSubject<TransferIndicatorEntity, Never>(.warning)
        let sut = makeSUT(initialState: .warning, updates: subject.eraseToAnyPublisher())

        sut.startMonitoring()
        #expect(sut.state == .warning)

        subject.send(.inProgress(progress: 0.5))

        #expect(sut.state == .inProgress(progress: 0.5))
    }

    @Test
    func state_errorPersistsThroughNewTransfer() {
        let subject = CurrentValueSubject<TransferIndicatorEntity, Never>(.error)
        let sut = makeSUT(initialState: .error, updates: subject.eraseToAnyPublisher())

        sut.startMonitoring()
        #expect(sut.state == .error)

        subject.send(.error)

        #expect(sut.state == .error)
    }

    /// A transfer in progress delivers a new progress up to ten times a second. Re-publishing
    /// visibility alongside each of those made the UIKit navigation bar item rebuild itself just as
    /// often, which read as a flashing button.
    @Test
    func monitorStatus_whenOnlyProgressChanges_doesNotRepublishVisibility() {
        let subject = CurrentValueSubject<TransferIndicatorEntity, Never>(.inProgress(progress: 0.1))
        let sut = makeSUT(initialState: .inProgress(progress: 0.1), updates: subject.eraseToAnyPublisher())
        let recorder = Recorder()
        let cancellable = sut.isVisiblePublisher.sink { [recorder] in recorder.record($0) }

        sut.startMonitoring()
        subject.send(.inProgress(progress: 0.2))
        subject.send(.inProgress(progress: 0.3))
        subject.send(.inProgress(progress: 0.4))
        cancellable.cancel()

        #expect(recorder.values == [false, true], "the initial value, then becoming visible once")
    }

    private func makeSUT(
        initialState: TransferIndicatorEntity,
        updates: AnyPublisher<TransferIndicatorEntity, Never> = Empty().eraseToAnyPublisher()
    ) -> TransferIndicatorViewModel {
        TransferIndicatorViewModel(
            useCase: MockTransferIndicatorUseCase(
                currentState: initialState,
                updates: updates
            ),
            throttle: { $0 }
        )
    }
}

/// Collects the published visibility so the closure can stay free of the test's actor isolation.
private final class Recorder: @unchecked Sendable {
    private(set) var values: [Bool] = []

    func record(_ value: Bool) {
        values.append(value)
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

    var snapshotPublisher: AnyPublisher<TransferStatusSnapshot?, Never> {
        Empty().eraseToAnyPublisher()
    }

    func startMonitoring() async {}

    func clearTerminalState() async {}
}
