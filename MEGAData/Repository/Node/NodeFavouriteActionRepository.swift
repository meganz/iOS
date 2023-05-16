import Foundation
import MEGADomain
import MEGAData

struct NodeFavouriteActionRepository: NodeFavouriteActionRepositoryProtocol {

    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    func favourite(node: NodeEntity) async throws {
        guard let node = sdk.node(forHandle: node.handle) else {
            throw NodeFavouriteErrorEntity.nodeNotFound
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: NodeFavouriteErrorEntity.generic)
                return
            }
            sdk.setNodeFavourite(node, favourite: true, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: NodeFavouriteErrorEntity.generic)
                    return
                }
                if case .failure = result {
                    continuation.resume(throwing: NodeFavouriteErrorEntity.generic)
                    return
                }
                continuation.resume(with: .success(()))
            })
        }
    }

    func unFavourite(node: NodeEntity) async throws {
        guard let node = sdk.node(forHandle: node.handle) else {
            throw NodeFavouriteErrorEntity.nodeNotFound
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: NodeFavouriteErrorEntity.generic)
                return
            }
            sdk.setNodeFavourite(node, favourite: false, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: NodeFavouriteErrorEntity.generic)
                    return
                }
                if case .failure = result {
                    continuation.resume(throwing: NodeFavouriteErrorEntity.generic)
                    return
                }
                continuation.resume(with: .success(()))
            })
        }
    }
}
