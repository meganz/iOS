import MEGADomain
import MEGASwift

public struct MockNodeFavouriteActionUseCase: NodeFavouriteActionUseCaseProtocol {
    @Atomic public var favoriteCalledCount = 0
    @Atomic public var unFavoriteCalledCount = 0
    
    public init() {}
    
    public func favourite(node: NodeEntity) async throws {
        $favoriteCalledCount.mutate { $0 += 1 }
    }
    
    public func unFavourite(node: NodeEntity) async throws {
        $unFavoriteCalledCount.mutate { $0 += 1 }
    }
}
