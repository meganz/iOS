import UIKit

final class FavouritesExplorerGridViewController: FilesExplorerViewController {
    private lazy var layout: CHTCollectionViewWaterfallLayout = CHTCollectionViewWaterfallLayout()
    private var dtCollectionManager: DynamicTypeCollectionManager?
    private lazy var searchBarView = UIView()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        return collectionView
    }()
    
    private var gridSource: FavouritesExplorerGridSource? {
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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        addCollectionView()
        configureLayout()
        
        collectionView.register(
            UINib(nibName: "FileNodeCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "NodeCollectionFileID"
        )

        collectionView.register(
            UINib(nibName: "FolderNodeCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "NodeCollectionFolderID"
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
        configureFavouriteToolbarButtons()
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
            configureFavouriteToolbarButtons()
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
            gridSource = FavouritesExplorerGridSource(
                collectionView: collectionView,
                nodes: nodes,
                allowsMultipleSelection: gridSource?.allowsMultipleSelection ?? false,
                selectedNodes: gridSource?.selectedNodes,
                delegate: self)
        case .onNodesUpdate(let updatedNodes):
            gridSource?.updateCells(forNodes: updatedNodes)
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
        default:
            break
        }
    }
}

// MARK: - UICollectionViewDelegate
extension FavouritesExplorerGridViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if gridSource?.allowsMultipleSelection ?? false {
            gridSource?.select(indexPath: indexPath)
            configureFavouriteToolbarButtons()
            delegate?.didSelectNodes(withCount: gridSource?.selectedNodes?.count ?? 0)
        } else {
            gridSource?.getSelectedNode(at: indexPath) { selectedNode, allNodes in
                guard let selectedNode = selectedNode, let allNodes = allNodes else { return }
                viewModel.dispatch(.didSelectNode(selectedNode, allNodes))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if gridSource?.allowsMultipleSelection ?? false {
            gridSource?.deselect(indexPath: indexPath)
            configureFavouriteToolbarButtons()
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
extension FavouritesExplorerGridViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.didScroll(scrollView: scrollView)
    }
}

// MARK: - CollectionView Waterfall Layout Delegate Methods (Required)
extension FavouritesExplorerGridViewController: CHTCollectionViewDelegateWaterfallLayout {
    // ** Size for the cells in the Waterfall Layout */
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // create a cell size from the image size, and return the size
        return dtCollectionManager?.currentItemSize(for: indexPath) ?? .zero
    }
}

// MARK: - FilesExplorerGridSourceDelegate
extension FavouritesExplorerGridViewController: FilesExplorerGridSourceDelegate {
    func showMoreNodeOptions(for node: MEGANode, sender: UIView) {
        showMoreOptions(forNode: node, sender: sender)
    }
}
