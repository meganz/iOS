import MEGAAppPresentation
import MEGADesignToken
import UIKit

class FilesExplorerListViewController: FilesExplorerViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()
    
    var listSource: (any FilesExplorerListSourceProtocol)? {
        didSet {
            tableView.dataSource = listSource
            tableView.delegate = listSource
            tableView.emptyDataSetSource = self
            tableView.emptyDataSetDelegate = self
            tableView.reloadData()
            tableView.reloadEmptyDataSet()
        }
    }

    private var isCloudDriveRevampEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addAndConfigureTableView()
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }

        viewModel.dispatch(.onViewReady)
        delegate?.updateSearchResults()
        addLongPressGesture()
    }
    
    override func selectedNodes() -> [MEGANode]? {
        listSource?.selectedNodes
    }
    
    // MARK: - Interface methods
    
    override func toggleSelectAllNodes() {
        listSource?.toggleSelectAllNodes()
        configureExplorerToolbarButtons()
        delegate?.didSelectNodes(withCount: listSource?.selectedNodes?.count ?? 0)
    }

    override func selectNodes(_ nodes: [MEGANode]) {
        setEditingMode()
        delegate?.showSelectButton(true)
        listSource?.selectNodes(nodes)
        configureExplorerToolbarButtons()
        delegate?.didSelectNodes(withCount: listSource?.selectedNodes?.count ?? 0)
    }

    override func setEditingMode() {
        tableView.setEditing(true, animated: true)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.visibleCells.forEach {
            $0.setSelectedBackgroundView(withColor: .clear)
        }
        configureExplorerToolbarButtons()
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
        
    private func configureExplorerToolbarButtons() {
        switch viewModel.getExplorerType() {
        case .favourites: configureFavouriteToolbarButtons()
        default: configureToolbarButtons()
        }
    }
    
    // MARK: - Execute command
    private func executeCommand(_ command: FilesExplorerViewModel.Command) {
        switch command {
        case .reloadNodes(let nodes, let searchText):
            configureView(withSearchText: searchText, nodes: nodes)
            listSource = configuration?.listSourceType.init(
                tableView: tableView,
                nodes: nodes,
                searchText: searchText,
                selectedNodes: listSource?.selectedNodes,
                explorerType: viewModel.getExplorerType(),
                delegate: self
            )
        case .reloadData:
            delegate?.updateSearchResults()
        case .setViewConfiguration(let configuration):
            self.configuration = configuration
        case .onTransferCompleted(let node):
            listSource?.onTransferCompleted(forNode: node)
        case .updateContextMenu(let menu):
            delegate?.updateContextMenu(menu: menu)
        case .updateUploadAddMenu(let menu):
            delegate?.updateUploadAddMenu(menu: menu)
        case .sortTypeHasChanged:
            delegate?.updateSearchResults()
        case .editingModeStatusChanges:
            if tableView.isEditing {
                endEditingMode()
            } else {
                setEditingMode()
                delegate?.showSelectButton(true)
            }
        case .viewTypeHasChanged:
            delegate?.changeCurrentViewType()
        case .didSelect(let action):
            delegate?.didSelect(action: action)
        }
    }
    
    private func addAndConfigureTableView() {
        view.wrap(tableView)
        setHeaderIfNeeded()
    }

    private func setHeaderIfNeeded() {
        guard isCloudDriveRevampEnabled else { return }
        tableView.tableHeaderView = headerView()
    }

    private func removeHeader() {
        tableView.tableHeaderView = nil
    }
}

// MARK: - FilesExplorerListSourceDelegate
extension FilesExplorerListViewController: FilesExplorerListSourceDelegate {
    func didSelect(node: MEGANode, atIndexPath indexPath: IndexPath, allNodes: [MEGANode]) {
        guard !tableView.isEditing else {
            configureFavouriteToolbarButtons()
            delegate?.didSelectNodes(withCount: listSource?.selectedNodes?.count ?? 0)
            return
        }
        
        viewModel.dispatch(.didSelectNode(node, allNodes))
    }
    
    func didDeselect(node: MEGANode, atIndexPath indexPath: IndexPath, allNodes: [MEGANode]) {
        guard tableView.isEditing else {
            return
        }
        configureFavouriteToolbarButtons()
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
    
    func download(node: MEGANode) {
        viewModel.dispatch(.downloadNode(node))
    }
}

extension FilesExplorerListViewController: @MainActor DZNEmptyDataSetDelegate {
    func emptyDataSetWillAppear(_ scrollView: UIScrollView) {
        removeHeader()
    }

    func emptyDataSetWillDisappear(_ scrollView: UIScrollView) {
        setHeaderIfNeeded()
    }
}

extension FilesExplorerListViewController {
    private func addLongPressGesture() {
        guard isCloudDriveRevampEnabled else { return }
        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(longPressGestureRecognized(sender:))
        )
        tableView.addGestureRecognizer(longPressGesture)
    }

    @objc private func longPressGestureRecognized(sender: UITapGestureRecognizer) {
        guard case let location = sender.location(in: tableView),
              let indexPath = tableView.indexPathForRow(at: location),
              let nodes = listSource?.nodes,
              let node = nodes[safe: indexPath.row] else {
            return
        }

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()

        selectNodes([node])
    }
}
