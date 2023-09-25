import MEGADomain
import MEGASdk

extension NodeEntity {
    public func shouldProcessOnNodesUpdate(withChildNodes childNodes: [MEGANode], updatedNodes: [MEGANode]) -> Bool {
        let updatedNodes = updatedNodes.toNodeEntities()
        guard !updatedNodes.contains(where: { $0.parentHandle == self.handle }) else { return true }
        
        let childNodes = Set(childNodes.compactMap({ $0.base64Handle }))
        
        for node in updatedNodes {
            let nodeHandle = node.base64Handle
            let parentOfNodeUpdatedBase64Handle = MEGASdk.base64Handle(forHandle: node.parentHandle) ?? ""
            let previousParentOfNodeUpdatedBase64Handle = MEGASdk.base64Handle(forHandle: node.restoreParentHandle) ?? ""
            
            guard !childNodes.contains(nodeHandle) &&
                    !childNodes.contains(parentOfNodeUpdatedBase64Handle) &&
                    !childNodes.contains(previousParentOfNodeUpdatedBase64Handle) else {
                return true
            }
        }
        
        return false
    }
    
    public func shouldProcessOnNodeEntitiesUpdate(withChildNodes childNodes: [NodeEntity], updatedNodes: [NodeEntity]) -> Bool {
        guard !updatedNodes.contains(where: { $0.parentHandle == self.handle }) else { return true }
        
        let childNodes = Set(childNodes.compactMap({ $0.base64Handle }))
        
        for node in updatedNodes {
            let nodeHandle = node.base64Handle
            let parentOfNodeUpdatedBase64Handle = MEGASdk.base64Handle(forHandle: node.parentHandle) ?? ""
            let previousParentOfNodeUpdatedBase64Handle = MEGASdk.base64Handle(forHandle: node.restoreParentHandle) ?? ""
            
            guard !childNodes.contains(nodeHandle) &&
                    !childNodes.contains(parentOfNodeUpdatedBase64Handle) &&
                    !childNodes.contains(previousParentOfNodeUpdatedBase64Handle) else {
                return true
            }
        }
        
        return false
    }
}
