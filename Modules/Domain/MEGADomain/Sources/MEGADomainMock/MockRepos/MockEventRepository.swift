import MEGADomain
import MEGASwift

public struct MockEventRepository: EventRepositoryProtocol {
    private let stream: AsyncStream<EventEntity>
    private let continuation: AsyncStream<EventEntity>.Continuation
    private let folderLinkStream: AsyncStream<EventEntity>
    private let folderLinkContinuation: AsyncStream<EventEntity>.Continuation
    
    public static let newRepo = MockEventRepository()
    
    public init() {
        (stream, continuation) = AsyncStream.makeStream(of: EventEntity.self)
        (folderLinkStream, folderLinkContinuation) = AsyncStream.makeStream(of: EventEntity.self)
    }
    
    public var eventUpdates: AnyAsyncSequence<EventEntity> {
        stream.eraseToAnyAsyncSequence()
    }

    public var folderLinkEventUpdates: AnyAsyncSequence<EventEntity> {
        folderLinkStream.eraseToAnyAsyncSequence()
    }
    
    public func simulateEvent(_ event: EventEntity) {
        continuation.yield(event)
    }
    
    public func simulateEventCompletion() {
        continuation.finish()
    }

    public func simulateFolderLinkEvent(_ event: EventEntity) {
        folderLinkContinuation.yield(event)
    }

    public func simulateFolderLinkEventCompletion() {
        folderLinkContinuation.finish()
    }
}
