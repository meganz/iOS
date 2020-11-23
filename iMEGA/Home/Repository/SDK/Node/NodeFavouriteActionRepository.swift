import Foundation

protocol NodeFavouriteActionRepositoryProtocol {

    func isMarkedFavourte(of nodeHandle: MEGAHandle) -> Result<Bool, NodeFavouriteDomainError>

    func markFavourite(of nodeHandle: MEGAHandle, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void)

    func unmarkFavourite(of nodeHandle: MEGAHandle, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void)
}

final class NodeFavouriteActionRepository: NodeFavouriteActionRepositoryProtocol {

    private let sdk: MEGASdk

    init(sdk: MEGASdk = MEGASdkManager.sharedMEGASdk()) {
        self.sdk = sdk
    }

    func isMarkedFavourte(of nodeHandle: MEGAHandle) -> Result<Bool, NodeFavouriteDomainError> {
        guard let node = sdk.node(forHandle: nodeHandle) else { return .failure(.nodeNotFound) }
        return .success(node.isFavourite)
    }

    func markFavourite(of nodeHandle: MEGAHandle, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            completion(.failure(.nodeNotFound))
            return
        }

        let requestDelegate = MEGAGenericRequestDelegate { (request, error) in
            if let error = error.sdkError {
                completion(.failure(.sdkError(error)))
                return
            }
            completion(.success(()))
        }
        sdk.setNodeFavourite(node, favourite: true, delegate: requestDelegate)
    }

    func unmarkFavourite(of nodeHandle: MEGAHandle, completion: @escaping (Result<Void, NodeFavouriteDomainError>) -> Void) {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            completion(.failure(.nodeNotFound))
            return
        }

        let requestDelegate = MEGAGenericRequestDelegate { (request, error) in
            if let error = error.sdkError {
                completion(.failure(.sdkError(error)))
                return
            }
            completion(.success(()))
        }
        sdk.setNodeFavourite(node, favourite: false, delegate: requestDelegate)
    }
}
