import MEGADomain
import MEGASdk

public protocol NodesUpdateProtocol {
    func shouldProcessOnNodeEntitiesUpdate(with nodeList: MEGANodeList, childNodes: [NodeEntity], parentNode: NodeEntity?) -> Bool
}

public extension NodesUpdateProtocol {
    func shouldProcessOnNodeEntitiesUpdate(with nodeList: MEGANodeList, childNodes: [NodeEntity], parentNode: NodeEntity?) -> Bool {
        guard let parentNode = parentNode else { return false }
        
        let nodesUpdatedArray = nodeList.toNodeEntities()
        
        return parentNode.shouldProcessOnNodeEntitiesUpdate(withChildNodes: childNodes, updatedNodes: nodesUpdatedArray)
    }
}
