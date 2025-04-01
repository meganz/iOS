import MEGADomain
import MEGASwift

public struct MockEventRepository: EventRepositoryProtocol {
    private let stream: AsyncStream<EventEntity>
    private let continuation: AsyncStream<EventEntity>.Continuation
    
    public static let newRepo = MockEventRepository()
    
    public init() {
        (stream, continuation) = AsyncStream.makeStream(of: EventEntity.self)
    }
    
    public var eventUpdates: AnyAsyncSequence<EventEntity> {
        stream.eraseToAnyAsyncSequence()
    }
    
    public func simulateEvent(_ event: EventEntity) {
        continuation.yield(event)
    }
    
    public func simulateEventCompletion() {
        continuation.finish()
    }
}
