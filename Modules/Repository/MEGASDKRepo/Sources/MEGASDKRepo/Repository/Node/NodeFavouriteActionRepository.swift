import Foundation
import MEGADomain
import MEGASdk

public struct NodeFavouriteActionRepository: NodeFavouriteActionRepositoryProtocol {
    public static var newRepo: NodeFavouriteActionRepository {
        NodeFavouriteActionRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func favourite(node: NodeEntity) async throws {
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

    public func unFavourite(node: NodeEntity) async throws {
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
