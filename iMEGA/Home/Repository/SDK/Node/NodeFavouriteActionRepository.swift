import Foundation

protocol NodeFavouriteActionRepositoryProtocol {

    func isMarkedFavourte(of nodeHandle: HandleEntity) -> Result<Bool, NodeFavouriteDomainError>

    func markFavourite(of nodeHandle: HandleEntity, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void)

    func unmarkFavourite(of nodeHandle: HandleEntity, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void)
}

final class NodeFavouriteActionRepository: NodeFavouriteActionRepositoryProtocol {

    private let sdk: MEGASdk

    init(sdk: MEGASdk = MEGASdkManager.sharedMEGASdk()) {
        self.sdk = sdk
    }

    func isMarkedFavourte(of nodeHandle: HandleEntity) -> Result<Bool, NodeFavouriteDomainError> {
        guard let node = sdk.node(forHandle: nodeHandle) else { return .failure(.nodeNotFound) }
        return .success(node.isFavourite)
    }

    func markFavourite(of nodeHandle: HandleEntity, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            completion(.failure(.nodeNotFound))
            return
        }

        let requestDelegate = MEGAGenericRequestDelegate { (request, error) in
            if let errorType = error.sdkError {
                completion(.failure(.sdkError(errorType)))
                return
            }
            completion(.success(()))
        }
        sdk.setNodeFavourite(node, favourite: true, delegate: requestDelegate)
    }

    func unmarkFavourite(of nodeHandle: HandleEntity, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            completion(.failure(.nodeNotFound))
            return
        }

        let requestDelegate = MEGAGenericRequestDelegate { (request, error) in
            if let sdkError = error.sdkError {
                completion(.failure(.sdkError(sdkError)))
                return
            }
            completion(.success(()))
        }
        sdk.setNodeFavourite(node, favourite: false, delegate: requestDelegate)
    }
}
