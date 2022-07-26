import Foundation

enum MediaDiscoveryAction: ActionType {
    case onViewReady
    case onViewDidAppear
    case onViewWillDisAppear
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
    private var statsUseCase: MediaDiscoveryStatsUseCaseProtocol
    
    var invokeCommand: ((Command) -> Void)?
    
    lazy var pageStayTimeTracker = PageStayTimeTracker()
    
    // MARK: - Init
    
    init(parentNode: MEGANode, router: MediaDiscoveryRouter, statsUseCase: MediaDiscoveryStatsUseCaseProtocol) {
        self.parentNode = parentNode
        self.router = router
        self.statsUseCase = statsUseCase
        
        super.init()
    }
    
    // MARK: - Dispatch action
    
    func dispatch(_ action: MediaDiscoveryAction) {
        switch action {
        case .onViewReady:
            sendPageVisitedStats()
            loadNodes()
            invokeCommand?(.loadMedia(nodes: nodes))
        case .onNodesUpdate(let nodeList):
            debouncer.start { [weak self] in
                if self?.shouldReload(with: nodeList) == true {
                    self?.loadNodes()
                    self?.invokeCommand?(.loadMedia(nodes: self?.nodes ?? []))
                }
            }
        case .onViewDidAppear:
            startTracking()
            sendPageVisitedStats()
        case .onViewWillDisAppear:
            endTracking()
            sendPageStayStats()
        }
    }
    
    // MARK: Private
    
    private func isAnyNodeMovedToTrash(nodes: [MEGANode], updatedNodes: [MEGANode]) -> Bool {
        let nodesRemoved = updatedNodes.filter { node in
            if node.hasChangedType(.parent),
               nodes.contains(where: { $0 == node }),
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
        let nodelist = MEGASdkManager.sharedMEGASdk().children(forParent: parentNode, order: MEGASortOrderType.modificationDesc.rawValue)
        nodes = (nodelist.mnz_mediaNodesMutableArrayFromNodeList() as? [MEGANode]) ?? []
    }
    
    private func startTracking() {
        pageStayTimeTracker.start()
    }
    
    private func endTracking() {
        pageStayTimeTracker.end()
    }
    
    private func sendPageVisitedStats() {
        statsUseCase.sendPageVisitedStats()
    }
    
    private func sendPageStayStats() {
        let duration = Int(pageStayTimeTracker.duration)
        
        statsUseCase.sendPageStayStats(with: duration)
    }
}
