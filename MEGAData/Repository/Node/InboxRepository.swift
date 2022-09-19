import MEGADomain

struct InboxRepository: InboxRepositoryProtocol {
    private let sdk: MEGASdk
    
    static var newRepo: InboxRepository {
        InboxRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func containsInboxRootNode(_ array: [NodeEntity]) -> Bool {
        array.contains(where: isInboxRootNode)
    }
    
    func isInboxRootNode(_ node: NodeEntity) -> Bool {
        node == inboxNode()
    }
    
    func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        guard node.deviceId != nil, let parentNode = sdk.node(forHandle: node.parentHandle) else { return false }
        return BackupRootNodeAccess.shared.isTargetNode(for: parentNode)
    }
    
    func backupRootNodeSize() async throws -> UInt64 {
        let node = try await backupRootNode()
        let nodeInfo = try await folderInfo(node: node)
        return UInt64(nodeInfo.currentSize)
    }
    
    func isBackupRootNodeEmpty() async -> Bool {
        do {
            let node = try await backupRootNode()
            return MEGASdkManager.sharedMEGASdk().children(forParent: node).size == 0
        } catch {
            return true
        }
    }
    
    func inboxNode() -> NodeEntity? {
        MEGASdkManager.sharedMEGASdk().inboxNode?.toNodeEntity()
    }
    
    private func folderInfo(node: MEGANode) async throws -> MEGAFolderInfo {
        try await withCheckedThrowingContinuation { continuation in
            sdk.getFolderInfo(for: node, delegate: RequestDelegate() { result in
                switch result {
                case .failure:
                    continuation.resume(throwing: FolderInfoErrorEntity.notFound)
                case .success(let request):
                    continuation.resume(with: .success(request.megaFolderInfo))
                }
            })
        }
    }
    
    private func backupRootNode() async throws -> MEGANode {
        try await withCheckedThrowingContinuation { continuation in
            BackupRootNodeAccess.shared.loadNode { node, error in
                guard let node = node else {
                    continuation.resume(throwing: BackupNodeErrorEntity.notFound)
                    return
                }
                
                continuation.resume(with: Result.success(node))
            }
        }
    }
}
