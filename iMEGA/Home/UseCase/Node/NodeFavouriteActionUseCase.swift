import Foundation

protocol NodeFavouriteActionUseCaseProtocol {

    func addNodeToFavourite(nodeHandle: HandleEntity, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void)

    func removeNodeFromFavourite(nodeHandle: HandleEntity, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void)

    func isNodeFavourite(nodeHandle: HandleEntity) -> Result<Bool, NodeFavouriteDomainError>
}

final class NodeFavouriteActionUseCase: NodeFavouriteActionUseCaseProtocol {

    private let nodeFavouriteRepository: NodeFavouriteActionRepositoryProtocol

    init(nodeFavouriteRepository: NodeFavouriteActionRepositoryProtocol) {
        self.nodeFavouriteRepository = nodeFavouriteRepository
    }

    func addNodeToFavourite(nodeHandle: HandleEntity, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void) {
        return nodeFavouriteRepository.markFavourite(of: nodeHandle, completion: completion)
    }

    func removeNodeFromFavourite(nodeHandle: HandleEntity, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void) {
         nodeFavouriteRepository.unmarkFavourite(of: nodeHandle, completion: completion)
    }

    func isNodeFavourite(nodeHandle: HandleEntity) -> Result<Bool, NodeFavouriteDomainError> {
        return nodeFavouriteRepository.isMarkedFavourte(of: nodeHandle)
    }
}

enum NodeFavouriteDomainError: Error {

    case nodeNotFound

    case sdkError(MEGASDKErrorType)
}
