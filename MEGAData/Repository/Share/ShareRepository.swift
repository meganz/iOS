import Foundation
import MEGADomain

struct ShareRepository: ShareRepositoryProtocol {
    
    static var newRepo: ShareRepository {
        ShareRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func user(sharing node: NodeEntity) -> UserEntity? {
        guard let megaNode = node.toMEGANode(in: sdk) else {
            return nil
        }
        
        return sdk.userFrom(inShare: megaNode)?.toUserEntity()
    }
    
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        sdk.publicLinks(order.toMEGASortOrderType())
            .toNodeEntities()
    }

    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        sdk.outShares(order.toMEGASortOrderType()).toShareEntities()
    }
    
    func createShareKey(forNode node: NodeEntity) async throws -> HandleEntity {
        guard let sharedNode = node.toMEGANode(in: sdk) else { throw ShareErrorEntity.nodeNotFound }
        
        return try await withCheckedThrowingContinuation { continuation in
            guard Task.isCancelled == false else {
                continuation.resume(throwing: CancellationError())
                return
            }
            
            sdk.openShareDialog(sharedNode, delegate: RequestDelegate(completion: { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.nodeHandle)
                case .failure:
                    continuation.resume(throwing: ShareErrorEntity.generic)
                }
            }))
        }
    }
}
