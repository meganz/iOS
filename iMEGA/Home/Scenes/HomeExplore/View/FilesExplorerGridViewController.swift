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
        
        SVProgressHUD.show()
        isProgressViewBeingShown = true
        viewModel.dispatch(.onViewReady)
        delegate?.updateSearchResults()
    }
    
    override func selectAllNodes() {
        gridSource?.selectAllNodes()
        configureToolbarButtons()
        delegate?.didSelectNodes(withCount: gridSource?.selectedNodes?.count ?? 0)
    }
    
    override func configureSearchController(_ searchController: UISearchController) {
        addSearchBarViewIfNeeded()
        searchBarView.addSubview(searchController.searchBar)
        searchController.searchBar.autoPinEdgesToSuperviewEdges()
    }
    
    override func setEditingMode() {
        gridSource?.allowsMultipleSelection = true
        configureToolbarButtons()
        showToolbar()
    }
    
    override func endEditingMode() {
        super.endEditingMode()
        gridSource?.allowsMultipleSelection = false
        hideToolbar()
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
        case .reloadNodes(let nodes):
            if isProgressViewBeingShown {
                isProgressViewBeingShown = false
                SVProgressHUD.dismiss()
            }
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
        collectionView.deselectItem(at: indexPath, animated: true)
        if gridSource?.allowsMultipleSelection ?? false {
            gridSource?.toggleIndexPathSelection(indexPath)
            configureToolbarButtons()
            delegate?.didSelectNodes(withCount: gridSource?.selectedNodes?.count ?? 0)
        } else {
            if let nodes = gridSource?.nodes {
                viewModel.dispatch(.didSelectNode(nodes[indexPath.item], nodes))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        gridSource?.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    }
}

// MARK:- Scrollview delegate
extension FilesExplorerGridViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.didScroll(scrollView: scrollView)
    }
}
