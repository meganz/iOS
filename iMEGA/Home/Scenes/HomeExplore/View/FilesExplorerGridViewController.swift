import UIKit

class FilesExplorerGridViewController: FilesExplorerViewController {
    
    private lazy var layout: CHTCollectionViewWaterfallLayout = CHTCollectionViewWaterfallLayout()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        return collectionView
    }()
    
    private lazy var searchBarView = UIView()

    private var gridSource: FilesExplorerGridSource? {
        didSet {
            guard let gridSource = gridSource else { return }
            
            collectionView.dataSource = gridSource
            collectionView.delegate = self
            collectionView.emptyDataSetSource = self
            collectionView.reloadData()
            collectionView.reloadEmptyDataSet()
            dtCollectionManager = DynamicTypeCollectionManager(delegate: gridSource)
        }
    }
    
    private var dtCollectionManager: DynamicTypeCollectionManager?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        addCollectionView()
        configureLayout()
        collectionView.register(
            NodeCollectionViewCell.cellNib,
            forCellWithReuseIdentifier: NodeCollectionViewCell.reusableIdentifier
        )
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
        
        viewModel.dispatch(.onViewReady)
        delegate?.updateSearchResults()
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            dtCollectionManager?.resetCollectionItems()
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    override func toggleSelectAllNodes() {
        gridSource?.toggleSelectAllNodes()
        configureToolbarButtons()
        delegate?.didSelectNodes(withCount: gridSource?.selectedNodes?.count ?? 0)
    }

    override func selectNodes(_ nodes: [MEGANode]) {
        setEditingMode()
        delegate?.showSelectButton(true)
        gridSource?.selectNodes(nodes)
        configureToolbarButtons()
        delegate?.didSelectNodes(withCount: gridSource?.selectedNodes?.count ?? 0)
    }

    override func removeSearchController(_ searchController: UISearchController) {
        guard let searchBar = searchBarView.subviews.first,
              searchBar == searchController.searchBar else {
            return
        }
        
        searchController.searchBar.removeFromSuperview()
        searchBarView.removeFromSuperview()
        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    }
    
    override func setEditingMode() {
        setEditing(true, animated: true)
        audioPlayer(hidden: true)
    }
    
    override func endEditingMode() {
        super.endEditingMode()
        setEditing(false, animated: true)
        audioPlayer(hidden: false)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        collectionView.allowsMultipleSelection = editing
        
        collectionView.allowsMultipleSelectionDuringEditing = editing
        
        collectionView.alwaysBounceVertical = !editing
        gridSource?.allowsMultipleSelection = editing
        
        if editing {
            configureToolbarButtons()
            showToolbar()
        } else {
            hideToolbar()
            collectionView.clearSelectedItems()
        }
        
        super.setEditing(editing, animated: animated)
    }
    
    override func selectedNodes() -> [MEGANode]? {
        return gridSource?.selectedNodes
    }
        
    private func addCollectionView() {
        view.wrap(collectionView)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { (_) in
            self.layout.configThumbnailListColumnCount()
        }
    }

    private func configureLayout() {
        // Change individual layout attributes for the spacing between cells
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.minimumColumnSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.configThumbnailListColumnCount()
    }
    
    // MARK: - Execute command
    private func executeCommand(_ command: FilesExplorerViewModel.Command) {
        switch command {
        case .reloadNodes(let nodes, let searchText):
            configureView(withSearchText: searchText, nodes: nodes)
            gridSource = FilesExplorerGridSource(
                collectionView: collectionView,
                nodes: nodes,
                allowsMultipleSelection: gridSource?.allowsMultipleSelection ?? false,
                selectedNodes: gridSource?.selectedNodes,
                delegate: self)
        case .reloadData:
            delegate?.updateSearchResults()
        case .setViewConfiguration(let configuration):
            self.configuration = configuration
        case .updateContextMenu(let menu):
            delegate?.updateContextMenu(menu: menu)
        case .updateUploadAddMenu(let menu):
            delegate?.updateUploadAddMenu(menu: menu)
        case .sortTypeHasChanged:
            delegate?.updateSearchResults()
        case .editingModeStatusChanges:
            if collectionView.allowsMultipleSelection {
                endEditingMode()
            } else {
                setEditingMode()
                delegate?.showSelectButton(true)
            }
        case .viewTypeHasChanged:
            delegate?.changeCurrentViewType()
        case .didSelect(let action):
            delegate?.didSelect(action: action)
        case .onTransferCompleted(let node):
            gridSource?.onTransferCompleted(forNode: node)
        }
    }
}

extension FilesExplorerGridViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if gridSource?.allowsMultipleSelection ?? false {
            gridSource?.select(indexPath: indexPath)
            configureToolbarButtons()
            delegate?.didSelectNodes(withCount: gridSource?.selectedNodes?.count ?? 0)
        } else {
            if let nodes = gridSource?.nodes {
                viewModel.dispatch(.didSelectNode(nodes[indexPath.item], nodes))
            }
            
            collectionView.clearSelectedItems(animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if gridSource?.allowsMultipleSelection ?? false {
            gridSource?.deselect(indexPath: indexPath)
            configureToolbarButtons()
            delegate?.didSelectNodes(withCount: gridSource?.selectedNodes?.count ?? 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        gridSource?.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setEditingMode()
        delegate?.showSelectButton(true)
    }
    
    func collectionViewDidEndMultipleSelectionInteraction(_ collectionView: UICollectionView) {
        collectionView.alwaysBounceVertical = true
    }
}

// MARK: - Scrollview delegate
extension FilesExplorerGridViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.didScroll(scrollView: scrollView)
    }
}

// MARK: - CollectionView Waterfall Layout Delegate Methods (Required)
extension FilesExplorerGridViewController: CHTCollectionViewDelegateWaterfallLayout {
    // ** Size for the cells in the Waterfall Layout */
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // create a cell size from the image size, and return the size
        return dtCollectionManager?.currentItemSize(for: indexPath) ?? .zero
    }
}

// MARK: - FilesExplorerGridSourceDelegate
extension FilesExplorerGridViewController: FilesExplorerGridSourceDelegate {
    func showMoreNodeOptions(for node: MEGANode, sender: UIView) {
        showMoreOptions(forNode: node, sender: sender)
    }
}
