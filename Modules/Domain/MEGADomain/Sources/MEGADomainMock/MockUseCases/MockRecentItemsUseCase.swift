import MEGADomain
import MEGASwift

public struct MockRecentItemsUseCase: RecentItemsUseCaseProtocol {
    
    public enum Events: Sendable, Equatable {
        case resetRecentItems([RecentItemEntity])
    }
        
    public var eventsStream: AnyAsyncSequence<Events> {
        stream.eraseToAnyAsyncSequence()
    }

    private let stream: AsyncStream<Events>
    private let continuation: AsyncStream<Events>.Continuation
    
    public init() {
        (stream, continuation) = AsyncStream.makeStream(of: Events.self, bufferingPolicy: .unbounded)
    }
    
    public func resetRecentItems(by items: [RecentItemEntity]) async throws {
        continuation.yield(.resetRecentItems(items))
    }
    
    public func insertRecentItem(_ item: RecentItemEntity) {
        
    }
    
    public func batchInsertRecentItems(_ items: [RecentItemEntity]) async throws {
        
    }
    
    public func fetchRecentItems() -> [RecentItemEntity] {
        []
    }
}
