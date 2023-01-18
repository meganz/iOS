extension CloudDriveViewController {
    @objc func shouldProcessOnNodesUpdate(with nodeList: MEGANodeList, childNodes: [MEGANode], parentNode: MEGANode?) -> Bool {
        guard let parentNode = parentNode else { return false }
        
        let nodesUpdatedArray = nodeList.toNodeArray()
        
        return parentNode.toNodeEntity().shouldProcessOnNodesUpdate(withChildNodes: childNodes, updatedNodes: nodesUpdatedArray)
    }
    
    @objc func updateControllersStackIfNeeded(_ nodeList: MEGANodeList) {
        let nodes = nodeList.toNodeArray()
        let removedNodes = nodes.removedChangeTypeNodes()
        if removedNodes.toNodeEntities().isNotEmpty {
            guard let navControllers = navigationController?.viewControllers else { return }
            var removedNodeInStack: MEGANode?
            self.navigationController?.viewControllers = navControllers
                .compactMap {
                    guard let vc = $0 as? CloudDriveViewController else { return $0 }
                    guard removedNodeInStack == nil else { return nil }
                    
                    removedNodeInStack = removedNodes.first(where: {
                        vc.parentNode?.handle == $0.handle
                    })
                    
                    return removedNodeInStack == nil ? $0 : nil
                }
        }
    }
}
