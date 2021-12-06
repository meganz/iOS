

enum PhotoExplorerAction {
    case onViewReady
    case didSelectNode(node: MEGANode)
    case updateTitle(nodeCount: Int)
    case updateTitleToDefault
}

class PhotoExplorerViewModel: NSObject {
    enum Command: Equatable {
        case reloadData(nodesByDay: [[MEGANode]])
        case modified(nodes: [MEGANode], indexPaths: [IndexPath])
        case setTitle(String)
    }
    
    private let router: PhotosExplorerRouter
    private var fileSearchUseCase: FilesSearchUseCaseProtocol
    private var nodeClipboardOperationUseCase: NodeClipboardOperationUseCase

    private var nodes: [MEGANode] = []
    private var sectionMarker: [Int] = []
    var invokeCommand: ((Command) -> Void)?
    
    // MARK: - Debouncer
    private static let REQUESTS_DELAY: TimeInterval = 0.35
    private let debouncer = Debouncer(delay: REQUESTS_DELAY)

    private var title: String {
        return Strings.Localizable.Home.Images.title
    }
    
    var emptyStateType: EmptyStateType {
        return .photos
    }
    
    init(router: PhotosExplorerRouter,
         fileSearchUseCase: FilesSearchUseCaseProtocol,
         nodeClipboardOperationUseCase: NodeClipboardOperationUseCase) {
        self.router = router
        self.fileSearchUseCase = fileSearchUseCase
        self.nodeClipboardOperationUseCase = nodeClipboardOperationUseCase
        super.init()
        
        populateMarkers()
        
        fileSearchUseCase.onNodesUpdate { [weak self] nodes in
            guard let self = self else { return }
            self.onNodesUpdate(updatedNodes: nodes)
        }
        
        nodeClipboardOperationUseCase.onNodeMove { [weak self] node in
            self?.onNodesUpdate(updatedNodes: [node])
        }
        
        nodeClipboardOperationUseCase.onNodeCopy { [weak self] _ in
            self?.loadAllPhotos()
        }
    }
    
    // MARK: - Dispatch action
    func dispatch(_ action: PhotoExplorerAction) {
        switch action {
        case .onViewReady:
            loadAllPhotos()
            invokeCommand?(.setTitle(title))
        case .didSelectNode(let node):
            didSelect(node: node)
        case .updateTitle(let nodeCount):
            updateTitle(withNodesCount: nodeCount)
        case .updateTitleToDefault:
            invokeCommand?(.setTitle(title))
        }
    }
    
    private func buildPhotosSections() -> [[MEGANode]] {
        var result = [[MEGANode]]()
        for (index, element) in sectionMarker.enumerated() {
            if (index + 1) < sectionMarker.count {
                result.append(Array(nodes[element..<sectionMarker[index+1]]))
            } else {
                result.append(Array(nodes[element..<nodes.count]))
            }
        }
        return result
    }
    
    private func indexPath(forNode node: MEGANode) -> IndexPath? {
        if let index = nodes.firstIndex(of: node) {
            if let nextSection = sectionMarker.firstIndex(where: { $0 >= index }) {
                if sectionMarker[nextSection] == index {
                    return IndexPath(item: 0, section: nextSection)
                } else if sectionMarker[nextSection] > index {
                    let itemIndex = index - sectionMarker[nextSection - 1]
                    return IndexPath(item: itemIndex, section: nextSection - 1)
                }
            } else {
                return IndexPath(item: index - sectionMarker[sectionMarker.count - 1],
                                 section: sectionMarker.count - 1)
            }
        }
        
        return nil
    }
    
    private func didSelect(node: MEGANode) {
        router.didSelect(node: node, allNodes: nodes)
    }
    
    @objc private func loadAllPhotos() {
        fileSearchUseCase.search(string: nil,
                       inNode: nil,
                       sortOrderType: .modificationDesc,
                       cancelPreviousSearchIfNeeded: true) { [weak self] nodes, isCancelled in
            DispatchQueue.main.async {
                guard let self = self, !isCancelled else { return }
                self.nodes = nodes ?? []
                self.populateMarkers()
                self.invokeReloadDataCommand()
            }
        }
    }
    
    private func populateMarkers() {
        sectionMarker = []
        for (index, element) in nodes.enumerated() {
            if index == 0 {
                sectionMarker.append(index)
            } else {
                if let previousModificationTime = nodes[index - 1].modificationTime,
                   let currentModificationTime = element.modificationTime,
                   !previousModificationTime.isSameDay(date: currentModificationTime) {
                    sectionMarker.append(index)
                }
            }
        }
    }
    
    private func invokeReloadDataCommand() {
        invokeCommand?(.reloadData(nodesByDay: buildPhotosSections()))
    }
    
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
    
    private func onNodesUpdate(updatedNodes: [MEGANode]) {
        if isAnyNodeMovedToTrash(nodes: nodes, updatedNodes: updatedNodes)
            || updatedNodes.containsNewNode() {
            debouncer.start { [weak self] in
                self?.loadAllPhotos()
            }
        } else {
            var resultNodes = [MEGANode]()
            var resultIndexPaths = [IndexPath]()

            updatedNodes.forEach { node in
                if let index = nodes.firstIndex(of: node) {
                    nodes[index] = node
                    if let indexPath = indexPath(forNode: node) {
                        resultNodes.append(node)
                        resultIndexPaths.append(indexPath)
                    }
                }
            }
            
            if resultNodes.count > 0 {
                invokeCommand?(.modified(nodes: resultNodes, indexPaths: resultIndexPaths))
            }

        }
    }
    
    func updateTitle(withNodesCount count: Int) {
        let title: String
        switch count {
        case 0:
            title = Strings.Localizable.selectTitle
        case 1:
            title = Strings.Localizable.oneItemSelected(count)
        default:
            title = Strings.Localizable.itemsSelected(count)
        }
        
        invokeCommand?(.setTitle(title))
    }
 }
