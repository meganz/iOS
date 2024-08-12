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
    
    public func resetRecentItems(by items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        continuation.yield(.resetRecentItems(items))
        completion(.success(()))
    }
    
    public func insertRecentItem(_ item: RecentItemEntity) {
        
    }
    
    public func batchInsertRecentItems(_ items: [RecentItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
        
    }
    
    public func fetchRecentItems() -> [RecentItemEntity] {
        []
    }
}
