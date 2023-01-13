import MEGADomain

public struct RubbishBinRepository: RubbishBinRepositoryProtocol {
    private let sdk: MEGASdk
    private let nodeValidationRepository: NodeValidationRepositoryProtocol
    
    public static var newRepo: RubbishBinRepository {
        RubbishBinRepository(sdk: MEGASdkManager.sharedMEGASdk(), nodeValidationRepository: NodeValidationRepository.newRepo)
    }
    
    private enum Constants {
        static let syncDebrisFolderName = "SyncDebris"
        static let syncDebrisNodePath = "//bin/SyncDebris"
    }
    
    public init(sdk: MEGASdk, nodeValidationRepository: NodeValidationRepositoryProtocol) {
        self.sdk = sdk
        self.nodeValidationRepository = nodeValidationRepository
    }
    
    public func isSyncDebrisNode(_ node: NodeEntity) async -> Bool {
        guard let syncDebrisNodes = await syncDebrisNodes(), syncDebrisNodes.isNotEmpty else { return false }
        
        return await isSyncDebrisChild(node)
    }
    
    private func isSyncDebrisChild(_ node: NodeEntity) async -> Bool {
        await Task.detached { () -> Bool in
            guard let megaNode = node.toMEGANode(in: sdk),
                  let path = sdk.nodePath(for: megaNode) else { return false }
            
            return path.hasPrefix(Constants.syncDebrisNodePath)
        }.value
    }
    
    private func syncDebrisNodes() async -> [NodeEntity]? {
        await Task.detached {
            guard let rubbishNode = sdk.rubbishNode else { return nil }
            
            return sdk.children(forParent: rubbishNode)
                .toNodeArray()
                .filter {
                    $0.name == Constants.syncDebrisFolderName && $0.isFolder()
                }.toNodeEntities()
        }.value
    }
}
