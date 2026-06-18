import MEGASwift
@testable import Transfer

final class MockMonitorTransferTabPresenceUseCase: MonitorTransferTabPresenceUseCaseProtocol {
    let presenceUpdates: AnyAsyncSequence<TransferTabPresence>

    init(presenceUpdates: AnyAsyncSequence<TransferTabPresence>) {
        self.presenceUpdates = presenceUpdates
    }
}
