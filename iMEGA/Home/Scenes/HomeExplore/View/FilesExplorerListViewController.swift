

import UIKit

class FilesExplorerListViewController: FilesExplorerViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()
    
    var listSource: FilesExplorerListSourceProtocol? {
        didSet {
            tableView.dataSource = listSource
            tableView.delegate = listSource
            tableView.emptyDataSetSource = self
            tableView.reloadData()
            tableView.reloadEmptyDataSet()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addAndConfigureTableView()
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }

        viewModel.dispatch(.onViewReady)
        delegate?.updateSearchResults()
    }
    
    override func selectedNodes() -> [MEGANode]? {
        listSource?.selectedNodes
    }
    
    override func downloadStarted(forNode node: MEGANode) {
        guard let nodes = listSource?.nodes else { return }
        if let index = nodes.firstIndex(of: node) {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    //MARK: - Interface methods
    
    override func toggleSelectAllNodes() {
        listSource?.toggleSelectAllNodes()
        configureToolbarButtons()
        delegate?.didSelectNodes(withCount: listSource?.selectedNodes?.count ?? 0)
    }
    
    override func configureSearchController(_ searchController: UISearchController) {
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.barTintColor = .mnz_backgroundElevated(traitCollection)
    }
    
    override func removeSearchController(_ searchController: UISearchController) {
        guard tableView.tableHeaderView == searchController.searchBar else {
            return
        }
        
        tableView.tableHeaderView = nil
    }
    
    override func setEditingMode() {
        tableView.setEditing(true, animated: true)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.visibleCells.forEach {
            $0.setSelectedBackgroundView(withColor: .clear)
        }
        configureToolbarButtons()
        showToolbar()
        if listSource?.selectedNodes == nil {
            listSource?.setEditingMode()
        }
        
        audioPlayer(hidden: true)
    }
    
    override func endEditingMode() {
        super.endEditingMode()
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.setEditing(false, animated: true)
        hideToolbar()
        listSource?.endEditingMode()
        
        audioPlayer(hidden: false)
    }
    
    override func updateContentView(_ height: CGFloat) {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)
    }
    
    // MARK: - Execute command
    private func executeCommand(_ command: FilesExplorerViewModel.Command) {
        switch command {
        case .reloadNodes(let nodes, let searchText):
            configureView(withSearchText: searchText, nodes: nodes)
            listSource = configuration?.listSourceType.init(
                tableView: tableView,
                nodes: nodes,
                selectedNodes: listSource?.selectedNodes,
                delegate: self
            )
        case .onNodesUpdate(let updatedNodes):
            listSource?.updateCells(forNodes: updatedNodes)
        case .reloadData:
            delegate?.updateSearchResults()
        case .setViewConfiguration(let configuration):
            self.configuration = configuration
        case .onTransferCompleted(let node):
            listSource?.onTransferCompleted(forNode: node)
        }
    }
    
    private func addAndConfigureTableView() {
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
    }
}


// MARK: - FilesExplorerListSourceDelegate
extension FilesExplorerListViewController: FilesExplorerListSourceDelegate {
    func didSelect(node: MEGANode, atIndexPath indexPath: IndexPath, allNodes: [MEGANode]) {
        guard !tableView.isEditing else {
            configureToolbarButtons()
            delegate?.didSelectNodes(withCount: listSource?.selectedNodes?.count ?? 0)
            return
        }
        
        viewModel.dispatch(.didSelectNode(node, allNodes))
    }
    
    func didDeselect(node: MEGANode, atIndexPath indexPath: IndexPath, allNodes: [MEGANode]) {
        guard tableView.isEditing else {
            return
        }
        configureToolbarButtons()
        delegate?.didSelectNodes(withCount: listSource?.selectedNodes?.count ?? 0)
    }
    
    func shouldBeginMultipleSelectionInteraction() {
        delegate?.showSelectButton(true)
    }
    
    func didBeginMultipleSelectionInteraction() {
        setEditingMode()
        tableView.alwaysBounceVertical = false
    }
    
    func didEndMultipleSelectionInteraction() {
        tableView.alwaysBounceVertical = true
    }
}
