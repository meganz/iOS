import Foundation
import MEGADomain
import MEGASwift

public struct MockFavouriteItemsUseCase: FavouriteItemsUseCaseProtocol {
    
    public enum Events: Sendable, Equatable {
        case createFavouriteItems([FavouriteItemEntity])
    }
        
    public var eventsStream: AnyAsyncSequence<Events> {
        stream.eraseToAnyAsyncSequence()
    }

    private let stream: AsyncStream<Events>
    private let continuation: AsyncStream<Events>.Continuation
    
    public init() {
        (stream, continuation) = AsyncStream.makeStream(of: Events.self, bufferingPolicy: .unbounded)
    }
    
    public func insertFavouriteItem(_ item: FavouriteItemEntity) {
        
    }

    public func deleteFavouriteItem(with base64Handle: Base64HandleEntity) {
        
    }

    public func createFavouriteItems(_ items: [FavouriteItemEntity]) async throws {
        continuation.yield(.createFavouriteItems(items))
    }

    public func batchInsertFavouriteItems(_ items: [FavouriteItemEntity], completion: @escaping (Result<Void, GetFavouriteNodesErrorEntity>) -> Void) {
    }

    public func fetchAllFavouriteItems() -> [FavouriteItemEntity] {
        []
    }

    public func fetchFavouriteItems(upTo count: Int) -> [FavouriteItemEntity] {
        []
    }
}
