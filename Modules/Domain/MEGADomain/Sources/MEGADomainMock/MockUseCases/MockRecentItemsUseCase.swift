import MEGADomain
import MEGASwift

public struct MockRecentItemsUseCase: RecentItemsUseCaseProtocol {
    
    public enum Events: Sendable, Equatable {
        case resetRecentItems([RecentItemEntity])
    }
        
    public var eventsStream: AnyAsyncSequence<Events> {
        stream.eraseToAnyAsyncSequence()
    }

    private let (stream, continuation) = AsyncStream.makeStream(of: Events.self, bufferingPolicy: .unbounded)
    
    public init() { }
    
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
