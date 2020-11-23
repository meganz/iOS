import Foundation

protocol NodeFavouriteActionUseCaseProtocol {

    func addNodeToFavourite(nodeHandle: MEGAHandle, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void)

    func removeNodeFromFavourite(nodeHandle: MEGAHandle, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void)

    func isNodeFavourite(nodeHandle: MEGAHandle) -> Result<Bool, NodeFavouriteDomainError>
}

final class NodeFavouriteActionUseCase: NodeFavouriteActionUseCaseProtocol {

    private let nodeFavouriteRepository: NodeFavouriteActionRepositoryProtocol

    init(nodeFavouriteRepository: NodeFavouriteActionRepositoryProtocol) {
        self.nodeFavouriteRepository = nodeFavouriteRepository
    }

    func addNodeToFavourite(nodeHandle: MEGAHandle, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void) {
        return nodeFavouriteRepository.markFavourite(of: nodeHandle, completion: completion)
    }

    func removeNodeFromFavourite(nodeHandle: MEGAHandle, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void) {
         nodeFavouriteRepository.unmarkFavourite(of: nodeHandle, completion: completion)
    }

    func isNodeFavourite(nodeHandle: MEGAHandle) -> Result<Bool, NodeFavouriteDomainError> {
        return nodeFavouriteRepository.isMarkedFavourte(of: nodeHandle)
    }
}

enum NodeFavouriteDomainError: Error {

    case nodeNotFound

    case sdkError(MEGASDKErrorType)
}
