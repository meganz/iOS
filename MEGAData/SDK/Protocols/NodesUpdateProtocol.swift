import MEGADomain

protocol NodesUpdateProtocol {
    func shouldProcessOnNodesUpdate(with nodeList: MEGANodeList, childNodes: [MEGANode], parentNode: MEGANode?) -> Bool
    func shouldProcessOnNodeEntitiesUpdate(with nodeList: MEGANodeList, childNodes: [NodeEntity], parentNode: NodeEntity?) -> Bool
}

extension NodesUpdateProtocol {
    func shouldProcessOnNodesUpdate(with nodeList: MEGANodeList, childNodes: [MEGANode], parentNode: MEGANode?) -> Bool {
        guard let parentNode = parentNode else { return false }
        
        let nodesUpdatedArray = nodeList.toNodeArray()
        
        return parentNode.toNodeEntity().shouldProcessOnNodesUpdate(withChildNodes: childNodes, updatedNodes: nodesUpdatedArray)
    }
    
    func shouldProcessOnNodeEntitiesUpdate(with nodeList: MEGANodeList, childNodes: [NodeEntity], parentNode: NodeEntity?) -> Bool {
        guard let parentNode = parentNode else { return false }
        
        let nodesUpdatedArray = nodeList.toNodeEntities()
        
        return parentNode.shouldProcessOnNodeEntitiesUpdate(withChildNodes: childNodes, updatedNodes: nodesUpdatedArray)
    }
}
