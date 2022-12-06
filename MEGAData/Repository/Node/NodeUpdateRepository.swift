import MEGADomain

struct NodeUpdateRepository: NodeUpdateRepositoryProtocol {
    static var newRepo: NodeUpdateRepository {
        NodeUpdateRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func shouldProcessOnNodesUpdate(parentNode: NodeEntity, childNodes: [NodeEntity],
                                    updatedNodes: [NodeEntity]) -> Bool {
        guard !updatedNodes.contains(where: { $0.parentHandle == parentNode.handle }) else { return true }
        
        let childNodesBase64Handles = Set(childNodes.compactMap({ $0.base64Handle }))
        
        for node in updatedNodes {
            let nodeHandle = node.base64Handle
            let parentOfNodeUpdatedBase64Handle = MEGASdk.base64Handle(forHandle: node.parentHandle) ?? ""
            let previousParentOfNodeUpdatedBase64Handle = MEGASdk.base64Handle(forHandle: node.restoreParentHandle) ?? ""
            
            guard !childNodesBase64Handles.contains(nodeHandle) &&
                    !childNodesBase64Handles.contains(parentOfNodeUpdatedBase64Handle) &&
                    !childNodesBase64Handles.contains(previousParentOfNodeUpdatedBase64Handle) else {
                return true
            }
        }
        
        return false
    }
}
