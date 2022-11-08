import MEGADomain

struct NodeValidationRepository: NodeValidationRepositoryProtocol {
    static var newRepo: NodeValidationRepository {
        NodeValidationRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func hasVersions(nodeHandle: HandleEntity) -> Bool {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return sdk.hasVersions(for: node)
    }
    
    func isDownloaded(nodeHandle: HandleEntity) -> Bool {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return (MEGAStore.shareInstance().offlineNode(with: node) != nil)
    }
    
    func isInRubbishBin(nodeHandle: HandleEntity) -> Bool {
        guard let node = sdk.node(forHandle: nodeHandle) else {
            return false
        }
        
        return sdk.isNode(inRubbish: node)
    }
    
    func isFileNode(handle: HandleEntity) -> Bool {
        guard let node = sdk.node(forHandle: handle) else {
            return false
        }
        
        return node.isFile()
    }
    
    func isNode(_ node: NodeEntity, descendantOf ancestor: NodeEntity) async -> Bool {
        let isDescendantNodeTask = Task.detached { () -> Bool in
            guard let parent = ancestor.toMEGANode(in: sdk) else {
                return false
            }
            
            var megaNode = node.toMEGANode(in: sdk)
            while let node = megaNode {
                if node == parent {
                    return true
                }
                megaNode = sdk.parentNode(for: node)
            }
            return false
        }
        return await isDescendantNodeTask.value
    }
}
