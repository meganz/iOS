import MEGADomain

extension FolderLinkViewController {
    func shouldProcessOnNodesUpdate(with nodeEntities: [NodeEntity], childNodes: [MEGANode], parentNode: MEGANode?) -> Bool {
        guard let parentNode = parentNode else { return false }
        
        return parentNode.toNodeEntity().shouldProcessOnNodeEntitiesUpdate(withChildNodes: childNodes.map { $0.toNodeEntity() }, updatedNodes: nodeEntities)
    }
}
