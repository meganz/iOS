import MEGAAppSDKRepo
import MEGADomain

extension BrowserViewController {
    private func browserControllers(for nodes: [NodeEntity], currentTargetNodeHandle: HandleEntity?) -> [BrowserViewController] {
        nodes.compactMap {
            guard let node = $0.toMEGANode(in: MEGASdk.shared) else { return nil }
            return self.browserController(for: node, isCurrentTargetNode: currentTargetNodeHandle == node.handle)
        }
    }
    
    @objc func navigateToCurrentTargetActionBrowser() {
        if parentNode == nil {
            switch browserAction {
            case .copy, .move:
                Task { @MainActor in
                    let nodeActionTargetUC = NodeActionTargetUseCase(nodeRepo: NodeRepository.newRepo, preferenceUseCase: PreferenceUseCase.default)
                    if let targetNodeTreeArray = await nodeActionTargetUC.lastTargetNodeTreeArray(for: browserAction == .copy ? .copy : .move), targetNodeTreeArray.isNotEmpty {
                        let currentTargetNodeHandle = nodeActionTargetUC.target(for: browserAction == .copy ? .copy : .move)
                        let targetNodeTreeControllers = self.browserControllers(for: targetNodeTreeArray, currentTargetNodeHandle: currentTargetNodeHandle)
                        
                        selectSegment(targetNodeTreeArray.contains(where: \.isInShare) ? .incoming: .cloud)
                        
                        self.navigationController?.viewControllers.append(contentsOf: targetNodeTreeControllers)
                    }
                }
                return
            default:
                break
            }
        }
    }
    
    @objc func browserController(for node: MEGANode, isCurrentTargetNode: Bool = false) -> BrowserViewController? {
        guard let browserVC = self.storyboard?.instantiateViewController(withIdentifier: "BrowserViewControllerID") as? BrowserViewController else { return nil }
        browserVC.browserAction = browserAction
        browserVC.isChildBrowser = true
        browserVC.isChildBrowserFromIncoming = incomingButton?.isSelected ?? false || isChildBrowserFromIncoming
        browserVC.localpath = localpath
        browserVC.parentNode = node
        browserVC.selectedNodesMutableDictionary = selectedNodesMutableDictionary
        browserVC.selectedNodesArray = selectedNodesArray
        browserVC.browserViewControllerDelegate = browserViewControllerDelegate
        return browserVC
    }
    
    @objc func updateActionTargetNode(_ node: MEGANode) {
        let nodeActionTargetUC = NodeActionTargetUseCase(nodeRepo: NodeRepository.newRepo, preferenceUseCase: PreferenceUseCase.default)
        if case .copy = browserAction {
            nodeActionTargetUC.record(target: node.toNodeEntity(), for: .copy)
        } else if case .move = browserAction {
            nodeActionTargetUC.record(target: node.toNodeEntity(), for: .move)
        }
    }
    
    private enum BrowserSegments {
        case cloud, incoming
    }
    
    private func selectSegment(_ segment: BrowserSegments) {
        switch segment {
        case .cloud:
            guard let cloudDriveButton else { return }
            cloudDriveTouchUp(inside: cloudDriveButton)
        case .incoming:
            guard let incomingButton else { return }
            incomingTouchUp(inside: incomingButton)
        }
    }
}
