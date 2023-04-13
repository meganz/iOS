import MEGADomain

struct MyBackupsRepository: MyBackupsRepositoryProtocol {
    private let sdk: MEGASdk
    
    static var newRepo: MyBackupsRepository {
        MyBackupsRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private enum Constants {
        static let myBackupsNodePath = "//in/My backups"
    }
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func isBackupRootNodeEmpty() async -> Bool {
        do {
            guard let node = try await myBackupRootNode().toMEGANode(in: sdk) else { return false }
            return sdk.children(forParent: node).size == 0
        } catch {
            return true
        }
    }
    
    func isBackupNode(_ node: NodeEntity) -> Bool {
        guard let megaNode = node.toMEGANode(in: sdk),
              let path = sdk.nodePath(for: megaNode) else { return false }
        return path.hasPrefix(Constants.myBackupsNodePath)
    }
    
    func isMyBackupsRootNode(_ node: NodeEntity) -> Bool {
        guard let megaNode = node.toMEGANode(in: sdk),
              let path = sdk.nodePath(for: megaNode) else { return false }
        return path == Constants.myBackupsNodePath
    }
    
    func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        guard node.deviceId != nil, let parentNode = sdk.node(forHandle: node.parentHandle) else { return false }
        return BackupRootNodeAccess.shared.isTargetNode(for: parentNode)
    }
    
    func backupRootNodeSize() async throws -> UInt64 {
        guard let node = try await myBackupRootNode().toMEGANode(in: sdk) else { return 0 }
        let nodeInfo = try await folderInfo(node: node)
        return UInt64(nodeInfo.currentSize)
    }
    
    func myBackupRootNode() async throws -> NodeEntity {
        try await withCheckedThrowingContinuation { continuation in
            BackupRootNodeAccess.shared.loadNode { node, error in
                guard let node = node else {
                    continuation.resume(throwing: BackupNodeErrorEntity.notFound)
                    return
                }
                
                continuation.resume(with: Result.success(node.toNodeEntity()))
            }
        }
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
}
