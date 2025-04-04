import MEGADomain
import MEGASdk

public struct NodeActionsRepository: NodeActionsRepositoryProtocol {
    public static var newRepo: NodeActionsRepository {
        NodeActionsRepository(sdk: MEGASdk.sharedSdk, sharedFolderSdk: MEGASdk.sharedFolderLinkSdk)
    }
    private let sdk: MEGASdk
    private let sharedFolderSdk: MEGASdk

    public init(sdk: MEGASdk, sharedFolderSdk: MEGASdk) {
        self.sdk = sdk
        self.sharedFolderSdk = sharedFolderSdk
    }
    
    public func copyNodeIfExistsWithSameFingerprint(at path: String, parentHandle: HandleEntity, newName: String?) -> Bool {
        guard let fileFingerprint = sdk.fingerprint(forFilePath: path),
              let parentNode = sdk.node(forHandle: parentHandle),
              let node = sdk.node(forFingerprint: fileFingerprint) else {
            return false
        }
        
        if node.parentHandle != parentHandle {
            if let newName = newName {
                sdk.copy(node, newParent: parentNode, newName: newName)
            } else {
                sdk.copy(node, newParent: parentNode)
            }
        }
        
        return true
    }
    
    public func copyNode(handle: HandleEntity, in parentHandle: HandleEntity, newName: String?, isFolderLink: Bool) async throws -> HandleEntity {
        try await withCheckedThrowingContinuation { continuation in
            var megaNode: MEGANode
            guard let parentNode = sdk.node(forHandle: parentHandle) else {
                continuation.resume(throwing: CopyOrMoveErrorEntity.nodeNotFound)
                return
            }
            
            if isFolderLink {
                guard let linkNode = sharedFolderSdk.node(forHandle: handle), let authorizedNode = sharedFolderSdk.authorizeNode(linkNode) else {
                    continuation.resume(throwing: CopyOrMoveErrorEntity.nodeAuthorizeFailed)
                    return
                }
                megaNode = authorizedNode
            } else {
                guard let node = sdk.node(forHandle: handle) else {
                    continuation.resume(throwing: CopyOrMoveErrorEntity.nodeNotFound)
                    return
                }
                megaNode = node
            }
            
            let delegate = RequestDelegate { result in
                switch result {
                case .failure(let error):
                    continuation.resume(
                        throwing: error.type == .apiEOverQuota ? CopyOrMoveErrorEntity.overQuota
                        : CopyOrMoveErrorEntity.nodeCopyFailed
                    )
                case .success(let request):
                    continuation.resume(returning: request.nodeHandle)
                }
            }
            if let newName = newName {
                sdk.copy(megaNode, newParent: parentNode, newName: newName, delegate: delegate)
            } else {
                sdk.copy(megaNode, newParent: parentNode, delegate: delegate)
            }
        }
    }
    
    public func moveNode(handle: HandleEntity, in parentHandle: HandleEntity, newName: String?) async throws -> HandleEntity {
        try await withCheckedThrowingContinuation { continuation in
            guard let parentNode = sdk.node(forHandle: parentHandle),
                  let node = sdk.node(forHandle: handle) else {
                continuation.resume(throwing: CopyOrMoveErrorEntity.nodeNotFound)
                return
            }
            
            let delegate = RequestDelegate { result in
                switch result {
                case .failure(let error):
                    if error.type == .apiECircular {
                        continuation.resume(throwing: CopyOrMoveErrorEntity.nodeMoveFailedCircularLinkage)
                    } else {
                        continuation.resume(throwing: CopyOrMoveErrorEntity.nodeCopyFailed)
                    }
                case .success(let request):
                    continuation.resume(returning: request.nodeHandle)
                }
            }
            if let newName = newName {
                sdk.move(node, newParent: parentNode, newName: newName, delegate: delegate)
            } else {
                sdk.move(node, newParent: parentNode, delegate: delegate)
            }
        }
    }
}
