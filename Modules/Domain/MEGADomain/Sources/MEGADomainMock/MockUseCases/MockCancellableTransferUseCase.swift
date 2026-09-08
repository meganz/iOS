import MEGADomain
import MEGASwift

public final class MockCancellableTransferUseCase: CancellableTransferUseCaseProtocol, @unchecked Sendable {
    private let states: [CancellableTransferStateEntity]

    /// Every list of transfers `start(transfers:)` was called with, in call order.
    @Atomic public var startedTransfers = [[CancellableTransferEntity]]()
    @Atomic public var cancel_calledTimes = 0

    /// - Parameter states: The states `start(transfers:)` emits, in order, before finishing.
    public init(states: [CancellableTransferStateEntity] = []) {
        self.states = states
    }

    public func start(transfers: [CancellableTransferEntity]) -> AnyAsyncSequence<CancellableTransferStateEntity> {
        $startedTransfers.mutate { $0.append(transfers) }
        let states = states
        return AsyncStream<CancellableTransferStateEntity> { continuation in
            states.forEach { continuation.yield($0) }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
    }

    public func cancel() {
        $cancel_calledTimes.mutate { $0 += 1 }
    }
}
