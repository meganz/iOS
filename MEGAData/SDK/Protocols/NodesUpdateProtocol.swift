import MEGADomain

protocol NodesUpdateProtocol {
    func shouldProcessOnNodeEntitiesUpdate(with nodeList: MEGANodeList, childNodes: [NodeEntity], parentNode: NodeEntity?) -> Bool
}

extension NodesUpdateProtocol {
    func shouldProcessOnNodeEntitiesUpdate(with nodeList: MEGANodeList, childNodes: [NodeEntity], parentNode: NodeEntity?) -> Bool {
        guard let parentNode = parentNode else { return false }
        
        let nodesUpdatedArray = nodeList.toNodeEntities()
        
        return parentNode.shouldProcessOnNodeEntitiesUpdate(withChildNodes: childNodes, updatedNodes: nodesUpdatedArray)
    }
}
