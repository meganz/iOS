struct NodeActionRepository: NodeActionRepositoryProtocol {
    private let sdk: MEGASdk
    private let nodeHandle: MEGAHandle?
    
    static var newRepo: NodeActionRepository {
        NodeActionRepository(sdk: MEGASdkManager.sharedMEGASdk(), nodeHandle: nil)
    }
    
    init(sdk: MEGASdk, nodeHandle: MEGAHandle?) {
        self.sdk = sdk
        self.nodeHandle = nodeHandle
    }
    
    func nodeAccessLevel() -> NodeAccessTypeEntity {
        guard let nodeHandle = nodeHandle, let node = sdk.node(forHandle: nodeHandle) else {
            return .unknown
        }
        return NodeAccessTypeEntity(shareAccess: sdk.accessLevel(for: node)) ?? .unknown
    }
    
    func labelString(label: NodeLabelTypeEntity) -> String {
        let nodeLabel = MEGANodeLabel(nodeLabelTypeEntity: label) ?? .unknown
        return MEGANode.string(for: nodeLabel) ?? "" + "Small"
    }
    
    func getFilesAndFolders() -> (childFileCount: Int, childFolderCount: Int) {
        guard let nodeHandle = nodeHandle, let node = sdk.node(forHandle: nodeHandle) else {
            return (0, 0)
        }
        
        let numberOfFiles = sdk.numberChildFiles(forParent: node)
        let numberOfFolders = sdk.numberChildFolders(forParent: node)
        
        return (numberOfFiles, numberOfFolders)
    }
    
    func hasVersions() -> Bool {
        guard let nodeHandle = nodeHandle, let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return sdk.hasVersions(for: node)
    }
    
    func isDownloaded() -> Bool {
        guard let nodeHandle = nodeHandle, let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return (MEGAStore.shareInstance().offlineNode(with: node) != nil)
    }
    
    func isInRubbishBin() -> Bool {
        guard let nodeHandle = nodeHandle, let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return sdk.isNode(inRubbish: node)
    }
    
    func images(for parentNode: NodeEntity) -> [NodeEntity] {
        guard let parent = parentNode.toMEGANode(in: sdk) else { return [] }
        
        return images(forParentNode: parent)
    }
    
    func images(for parentHandle: MEGAHandle) -> [NodeEntity] {
        guard let parent = sdk.node(forHandle: parentHandle) else { return [] }
        
        return images(forParentNode: parent)
    }
    
    // MARK: - Private
    
    private func images(forParentNode node: MEGANode) -> [NodeEntity] {
        let nodeList = sdk.children(forParent: node)
        let mediaNodes = (nodeList.mnz_mediaNodesMutableArrayFromNodeList() as? [MEGANode]) ?? []
        let imageNodes = mediaNodes.filter({ $0.name?.mnz_isImagePathExtension == true })
        
        return imageNodes.toNodeEntities()
    }
}
