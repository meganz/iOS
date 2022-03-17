import Foundation

enum MediaDiscoveryAction: ActionType {
    case onViewReady
    case onNodesUpdate(nodeList: MEGANodeList)
}

@available(iOS 14.0, *)
final class MediaDiscoveryViewModel: NSObject, ViewModelType {
    enum Command: Equatable, CommandType {
        case loadMedia(nodes: [MEGANode])
    }
    
    // MARK: - Debouncer
    private static let REQUESTS_DELAY: TimeInterval = 0.35
    private let debouncer = Debouncer(delay: REQUESTS_DELAY)
    
    private let parentNode: MEGANode
    private var nodes: [MEGANode] = []
    private let router: MediaDiscoveryRouter
    
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Init
    
    @objc init(parentNode: MEGANode, router: MediaDiscoveryRouter) {
        self.parentNode = parentNode
        self.router = router
        
        super.init()
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: MediaDiscoveryAction) {
        switch action {
        case .onViewReady:
            loadNodes()
            invokeCommand?(.loadMedia(nodes: nodes))
        case .onNodesUpdate(let nodeList):
            debouncer.start { [weak self] in
                if self?.shouldReload(with: nodeList) == true {
                    self?.loadNodes()
                    self?.invokeCommand?(.loadMedia(nodes: self?.nodes ?? []))
                }
            }
        }
    }
    
    // MARK: Private
    
    private func isAnyNodeMovedToTrash(nodes: [MEGANode], updatedNodes: [MEGANode]) -> Bool {
        let nodesRemoved = updatedNodes.filter { node in
            if node.hasChangedType(.parent),
               nodes.first(where: { $0 == node }) != nil,
               MEGASdkManager.sharedMEGASdk().rubbishNode == node {
                return true
            }
            
            return false
        }
        
        return !nodesRemoved.isEmpty
    }
    
    private func shouldReload(with nodeList: MEGANodeList) -> Bool {
        guard nodeList.mnz_shouldProcessOnNodesUpdate(forParentNode: parentNode, childNodesArray: nodes) == true else { return false }
        
        let updatedNodes = nodeList.toNodeArray()
        
        return isAnyNodeMovedToTrash(nodes:nodes, updatedNodes:updatedNodes) ||
        updatedNodes.containsNewNode() ||
        updatedNodes.hasModifiedAttributes() ||
        updatedNodes.hasModifiedParent()
    }
    
    private func loadNodes() {
        let nodelist = MEGASdkManager.sharedMEGASdk().children(forParent: parentNode)
        nodes = (nodelist.mnz_mediaNodesMutableArrayFromNodeList() as? [MEGANode]) ?? []
    }
}
