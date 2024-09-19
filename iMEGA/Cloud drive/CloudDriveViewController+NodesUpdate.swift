import MEGADomain
import MEGASDKRepo

extension CloudDriveViewController {
    
    @objc func shouldProcessOnNodesUpdate(
        with nodeList: MEGANodeList,
        childNodes: [MEGANode],
        parentNode: MEGANode?
    ) -> Bool {
        shouldProcessOnNodesUpdate(
            with: nodeList,
            childNodes: childNodes,
            parentNode: parentNode,
            sdk: MEGASdk.shared,
            nodeUpdateRepository: NodeUpdateRepository.newRepo
        )
    }
    
    func shouldProcessOnNodesUpdate(
        with nodeList: MEGANodeList,
        childNodes: [MEGANode],
        parentNode: MEGANode?,
        sdk: MEGASdk,
        nodeUpdateRepository: any NodeUpdateRepositoryProtocol
    ) -> Bool {
        let parentNodeEntity: NodeEntity? = {
            guard displayMode == .recents,
                  let parentHandle = recentActionBucket?.parentHandle else {
                return parentNode?.toNodeEntity()
            }
            
            return sdk.node(forHandle: parentHandle)?.toNodeEntity()
        }()
        
        guard let parentNodeEntity else { return false }
        return nodeUpdateRepository.shouldProcessOnNodesUpdate(parentNode: parentNodeEntity, childNodes: childNodes.toNodeEntities(), updatedNodes: nodeList.toNodeEntities())
    }
    
    /// To be called to update the recent bucket contents after receiving node updates from SDK
    @objc func reloadRecentActionBucketAfterNodeUpdates(using sdk: MEGASdk) async {
        guard displayMode == .recents else { return }
        
        let excludeSensitives = await viewModel.shouldExcludeSensitiveItems()
        
        // This follows the logic of `RecentsViegwController.getRecentActions`
        sdk.getRecentActionsAsync(sinceDays: 30, maxNodes: 500, excludeSensitives: excludeSensitives, delegate: RequestDelegate { [weak self] result in
            guard let self, let recentActionBucket else { return }
            var updatedBucket: MEGARecentActionBucket?
            if case let .success(request) = result {
                updatedBucket = request.recentActionsBuckets?.first { bucket in
                    guard bucket.parentHandle == recentActionBucket.parentHandle else { return false }
                    
                    // There can be different buckets with the same parentHandle.
                    // In order to correctly get the matching bucket, we need to check if the new bucket has
                    // common nodes with the current bucket
                    let bucketNodeHandles = Set((bucket.nodesList?.toNodeEntities() ?? []).map(\.handle))
                    let currentBucketNodeHandles = Set((recentActionBucket.nodesList?.toNodeEntities() ?? []).map(\.handle))
                    return !currentBucketNodeHandles.isDisjoint(with: bucketNodeHandles)
                }
            }
            
            if let updatedBucket {
                // If a matching bucket is found, we re-assign current bucket to that one and reload UI
                self.recentActionBucket = updatedBucket
                self.reloadUI(nil)
            } else {
                // There's no matching bucket (e.g: All the files in the current buckets are deleted).
                // Ideally we should display empty list, but there's no API to remove all the nodes of a `nodesList`
                // So I dismiss the screen as a temporary solution
                self.dismiss(animated: true)
            }
        })
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
