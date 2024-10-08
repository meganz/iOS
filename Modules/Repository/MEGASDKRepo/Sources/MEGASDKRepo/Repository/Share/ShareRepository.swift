import MEGADomain
import MEGASdk

public struct ShareRepository: ShareRepositoryProtocol {
    public static var newRepo: ShareRepository {
        ShareRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func user(sharing node: NodeEntity) -> UserEntity? {
        guard let megaNode = node.toMEGANode(in: sdk) else {
            return nil
        }
        
        return sdk.userFrom(inShare: megaNode)?.toUserEntity()
    }
    
    public func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity] {
        sdk.publicLinks(order.toMEGASortOrderType())
            .toNodeEntities()
    }
    
    public func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity] {
        sdk.outShares(order.toMEGASortOrderType()).toShareEntities()
    }

    public func areCredentialsVerifed(of user: UserEntity) -> Bool {
        guard let user = user.toMEGAUser() else { return false }
        return sdk.areCredentialsVerified(of: user)
    }
    
    public func createShareKey(forNode node: NodeEntity) async throws -> HandleEntity {
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
    
    public func isAnyCollectionShared() async -> Bool {
        sdk.megaSets().contains(where: { $0.isExported() })
    }
}
