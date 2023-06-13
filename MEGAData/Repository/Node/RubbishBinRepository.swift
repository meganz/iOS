import MEGADomain

public struct RubbishBinRepository: RubbishBinRepositoryProtocol {
    private let sdk: MEGASdk
    private let nodeValidationRepository: any NodeValidationRepositoryProtocol
    
    public static var newRepo: RubbishBinRepository {
        RubbishBinRepository(sdk: MEGASdkManager.sharedMEGASdk(), nodeValidationRepository: NodeValidationRepository.newRepo)
    }
    
    private enum Constants {
        static let syncDebrisFolderName = "SyncDebris"
        static let syncDebrisNodePath = "//bin/SyncDebris"
    }
    
    public init(sdk: MEGASdk, nodeValidationRepository: any NodeValidationRepositoryProtocol) {
        self.sdk = sdk
        self.nodeValidationRepository = nodeValidationRepository
    }
    
    public func isSyncDebrisNode(_ node: NodeEntity) -> Bool {
        guard let syncDebrisNodes = syncDebrisNodes(), syncDebrisNodes.isNotEmpty else { return false }
        
        return isSyncDebrisChild(node)
    }
    
    private func isSyncDebrisChild(_ node: NodeEntity) -> Bool {
        guard let megaNode = node.toMEGANode(in: sdk),
              let path = sdk.nodePath(for: megaNode) else { return false }
        
        return path.hasPrefix(Constants.syncDebrisNodePath)
    }
    
    private func syncDebrisNodes() -> [NodeEntity]? {
        guard let rubbishNode = sdk.rubbishNode else { return nil }
        
        return sdk.children(forParent: rubbishNode)
            .toNodeArray()
            .filter {
                $0.name == Constants.syncDebrisFolderName && $0.isFolder()
            }.toNodeEntities()
    }
}
