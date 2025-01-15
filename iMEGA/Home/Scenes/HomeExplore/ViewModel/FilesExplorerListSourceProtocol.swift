import MEGADomain

protocol FilesExplorerListSourceDelegate: UIViewController {
    func showMoreOptions(forNode node: MEGANode, sender: UIView)
    func didSelect(node: MEGANode, atIndexPath indexPath: IndexPath, allNodes: [MEGANode])
    func didDeselect(node: MEGANode, atIndexPath indexPath: IndexPath, allNodes: [MEGANode])
    func shouldBeginMultipleSelectionInteraction()
    func didBeginMultipleSelectionInteraction()
    func didEndMultipleSelectionInteraction()
    func download(node: MEGANode)
}

protocol FilesExplorerListSourceProtocol: UITableViewDataSource, UITableViewDelegate {
    var nodes: [MEGANode]? { get set }
    var selectedNodes: [MEGANode]? { get set }
    var tableView: UITableView { get set }
    var delegate: (any FilesExplorerListSourceDelegate)? { get set }
    var explorerType: ExplorerTypeEntity { get set }
    init(tableView: UITableView,
         nodes: [MEGANode]?,
         searchText: String?,
         selectedNodes: [MEGANode]?,
         explorerType: ExplorerTypeEntity,
         delegate: (any FilesExplorerListSourceDelegate)?)
    func reloadCell(withNode node: MEGANode)
    func onTransferCompleted(forNode node: MEGANode)
    func toggleSelection(at indexPath: IndexPath)
    func setEditingMode()
    func endEditingMode()
    func toggleSelectAllNodes()
    func select(indexPath: IndexPath)
    func deselect(indexPath: IndexPath)
}

extension FilesExplorerListSourceProtocol {
    func cell(forNode node: MEGANode) -> UITableViewCell? {
        return tableView
            .visibleCells
            .filter({ ($0 as? NodeTableViewCell)?.node == node })
            .first
    }
    
    func reloadCell(withNode node: MEGANode) {
        if let cell = cell(forNode: node), let indexPath = tableView.indexPath(for: cell) {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func onTransferCompleted(forNode node: MEGANode) {}
    
    func toggleSelection(at indexPath: IndexPath) {
        guard let nodes = nodes else { return }
        let node = nodes[indexPath.row]
        if tableView.isEditing {
            if let selectedNodes = selectedNodes {
                if selectedNodes.contains(node) {
                    self.selectedNodes?.removeAll { $0 == node }
                    delegate?.didDeselect(node: node, atIndexPath: indexPath, allNodes: nodes)
                } else {
                    self.selectedNodes?.append(node)
                    delegate?.didSelect(node: node, atIndexPath: indexPath, allNodes: nodes)
                }
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            delegate?.didSelect(node: node, atIndexPath: indexPath, allNodes: nodes)
        }
    }
    
    func select(indexPath: IndexPath) {
        guard let nodes = nodes else { return }
        let node = nodes[indexPath.row]
        if tableView.isEditing {
            if !(selectedNodes?.contains(node) ?? false) {
                selectedNodes?.append(node)
                delegate?.didSelect(node: node, atIndexPath: indexPath, allNodes: nodes)
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            
            guard explorerType == .favourites,
                  node.name?.fileExtensionGroup.isVisualMedia == true else {
                delegate?.didSelect(node: node, atIndexPath: indexPath, allNodes: nodes)
                return
            }
            delegate?.didSelect(node: node, atIndexPath: indexPath, allNodes: nodes.multiMediaNodeList())
        }
    }
    
    func deselect(indexPath: IndexPath) {
        guard let nodes = nodes else { return }
        let node = nodes[indexPath.row]
        if tableView.isEditing {
            if selectedNodes?.contains(node) ?? false {
                selectedNodes?.removeAll(where: { $0 == node })
                delegate?.didDeselect(node: node, atIndexPath: indexPath, allNodes: nodes)
            }
        }
    }
    
    func setEditingMode() {
        selectedNodes = []
    }
    
    func endEditingMode() {
        selectedNodes = nil
    }
    
    func toggleSelectAllNodes() {
        let selectedSet = Set(selectedNodes ?? [])
        let nodeSet = Set(nodes ?? [])
        selectedNodes = selectedSet == nodeSet ? [] : nodes
        tableView.reloadData()
    }
}
