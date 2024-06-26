import MEGADomain
import MEGASDKRepo
import MEGASwift

struct BackupsRepository: BackupsRepositoryProtocol {
    private let sdk: MEGASdk
    
    static var newRepo: BackupsRepository {
        BackupsRepository(sdk: MEGASdk.sharedSdk)
    }
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func isBackupRootNodeEmpty() async -> Bool {
        do {
            guard let node = try await backupRootNode().toMEGANode(in: sdk) else { return false }
            return sdk.children(forParent: node).size == 0
        } catch {
            return true
        }
    }
    
    func isBackupNode(_ node: NodeEntity) -> Bool {
        guard let megaNode = node.toMEGANode(in: sdk),
              let path = sdk.nodePath(for: megaNode),
              let backupRootNodePath = BackupRootNodeAccess.shared.nodePath else { return false }
        return path.hasPrefix(backupRootNodePath)
    }
    
    func isBackupsRootNode(_ node: NodeEntity) -> Bool {
        guard let megaNode = node.toMEGANode(in: sdk),
              let path = sdk.nodePath(for: megaNode),
              let backupRootNodePath = BackupRootNodeAccess.shared.nodePath else { return false }
        return path == backupRootNodePath
    }
    
    func isBackupDeviceFolder(_ node: NodeEntity) -> Bool {
        guard node.deviceId != nil, let parentNode = sdk.node(forHandle: node.parentHandle) else { return false }
        return BackupRootNodeAccess.shared.isTargetNode(for: parentNode)
    }
    
    func backupRootNode() async throws -> NodeEntity {
        try await withAsyncThrowingValue(in: { completion in
            BackupRootNodeAccess.shared.loadNode { node, _ in
                guard let node = node else {
                    completion(.failure(FolderInfoErrorEntity.notFound))
                    return
                }
                
                completion(.success(node.toNodeEntity()))
            }
        })
    }
    
    private func folderInfo(node: MEGANode) async throws -> FolderInfoEntity {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getFolderInfo(for: node, delegate: RequestDelegate { result in
                switch result {
                case .failure:
                    completion(.failure(FolderInfoErrorEntity.notFound))
                case .success(let request):
                    guard let megaFolderInfo = request.megaFolderInfo else {
                        completion(.failure(FolderInfoErrorEntity.notFound))
                        return
                    }
                    completion(.success(megaFolderInfo.toFolderInfoEntity()))
                }
            })
        })
    }
}
