import MEGADomain
import MEGASdk

public protocol NodesUpdateProtocol {
    func shouldProcessOnNodeEntitiesUpdate(with nodes: [NodeEntity], childNodes: [NodeEntity], parentNode: NodeEntity?) -> Bool
}

public extension NodesUpdateProtocol {
    func shouldProcessOnNodeEntitiesUpdate(with nodes: [NodeEntity], childNodes: [NodeEntity], parentNode: NodeEntity?) -> Bool {
        guard let parentNode = parentNode else { return false }
        
        return parentNode.shouldProcessOnNodeEntitiesUpdate(withChildNodes: childNodes, updatedNodes: nodes)
    }
}
