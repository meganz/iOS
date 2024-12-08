import MEGADomain

public struct MockRubbishBinRepository: RubbishBinRepositoryProtocol {
    private let syncDebrisNode: NodeEntity?
    private let syncDebrisChildNodes: [NodeEntity]?
    
    public init(syncDebrisNode: NodeEntity? = nil,
                syncDebrisChildNodes: [NodeEntity]? = nil) {
        self.syncDebrisNode = syncDebrisNode
        self.syncDebrisChildNodes = syncDebrisChildNodes
    }
    
    private func isSyncDebrisRootNode(_ node: NodeEntity) -> Bool {
        syncDebrisNode == node
    }
    
    public func isSyncDebrisChild(_ node: NodeEntity) -> Bool {
        syncDebrisChildNodes?.contains(node) ?? false
    }
    
    public func isSyncDebrisNode(_ node: MEGADomain.NodeEntity) -> Bool {
        if isSyncDebrisRootNode(node) {
            return true
        } else {
            return isSyncDebrisChild(node)
        }
    }
    
    public func cleanRubbishBin() {}
}
