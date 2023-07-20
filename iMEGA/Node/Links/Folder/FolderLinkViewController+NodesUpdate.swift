extension FolderLinkViewController {
    @objc func shouldProcessOnNodesUpdate(with nodeList: MEGANodeList, childNodes: [MEGANode], parentNode: MEGANode?) -> Bool {
        guard let parentNode = parentNode else { return false }
        
        let nodesUpdatedArray = nodeList.toNodeArray()
        
        return parentNode.toNodeEntity().shouldProcessOnNodesUpdate(withChildNodes: childNodes, updatedNodes: nodesUpdatedArray)
    }
}
