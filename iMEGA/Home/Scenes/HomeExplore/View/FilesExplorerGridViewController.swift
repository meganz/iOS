import UIKit

class FilesExplorerGridViewController: FilesExplorerViewController {
    
    private lazy var gridFlowLayout: GridFlowLayout = {
        let gridFlowLayout = GridFlowLayout()
        gridFlowLayout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        gridFlowLayout.minimumLineSpacing = 4
        gridFlowLayout.minimumInteritemSpacing = 15
        return gridFlowLayout
    }()
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: gridFlowLayout
        )
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
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        addCollectionView()
        collectionView.register(
            FileExplorerGridCell.nib,
            forCellWithReuseIdentifier: FileExplorerGridCell.reuseIdentifier
        )
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
        
        viewModel.dispatch(.onViewReady)
        delegate?.updateSearchResults()
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
    }
    
    override func toggleSelectAllNodes() {
        gridSource?.toggleSelectAllNodes()
        configureToolbarButtons()
        delegate?.didSelectNodes(withCount: gridSource?.selectedNodes?.count ?? 0)
    }
    
    override func configureSearchController(_ searchController: UISearchController) {
        addSearchBarViewIfNeeded()
        searchBarView.addSubview(searchController.searchBar)
        searchController.searchBar.autoPinEdgesToSuperviewEdges()
    }
    
    override func removeSearchController(_ searchController: UISearchController) {
        guard let searchBar = searchBarView.subviews.first,
              searchBar == searchController.searchBar else {
            return
        }
        
        searchController.searchBar.removeFromSuperview()
        searchBarView.removeFromSuperview()
        collectionView.autoPinEdge(toSuperviewEdge: .top)
    }
    
    override func setEditingMode() {
        setEditing(true, animated: true)
    }
    
    override func endEditingMode() {
        super.endEditingMode()
        setEditing(false, animated: true)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        collectionView.allowsMultipleSelection = editing
        
        if #available(iOS 14, *) {
            collectionView.allowsMultipleSelectionDuringEditing = editing;
        }
        
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
        view.addSubview(collectionView)
        if #available(iOS 11.0, *) {
            collectionView.autoPinEdgesToSuperviewEdges()
        } else {
            collectionView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            addSearchBarViewIfNeeded()
            collectionView.topAnchor.constraint(equalTo: searchBarView.bottomAnchor).isActive = true
        }
    }
    
    private func addSearchBarViewIfNeeded() {
        guard searchBarView.superview == nil else { return }
        view.addSubview(searchBarView)
        searchBarView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        searchBarView.heightAnchor.constraint(
            equalTo: view.heightAnchor,
            multiplier: 0,
            constant: 50
        ).isActive = true
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
                selectedNodes: gridSource?.selectedNodes
            ) { [weak self] node, button in
                self?.showMoreOptions(forNode: node, sender: button)
            }
        case .onNodesUpdate(let updatedNodes):
            gridSource?.updateCells(forNodes: updatedNodes)
        case .reloadData:
            delegate?.updateSearchResults()
        case .setViewConfiguration(let configuration):
            self.configuration = configuration
        default:
            break
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

// MARK:- Scrollview delegate
extension FilesExplorerGridViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.didScroll(scrollView: scrollView)
    }
}
