import MEGADomain
import MEGASwift

public final class MockRequestStatProgressUseCase: RequestStatProgressUseCaseProtocol, @unchecked Sendable {
    public var events: [EventEntity] = []

    public var requestStatsProgress: AnyAsyncSequence<EventEntity> {
        AsyncStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
    }
    
    public init(events: [EventEntity] = []) {
        self.events = events
    }
}
