
import UIKit


class PhotosExplorerViewController: ExplorerBaseViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!

    private var cellSize: CGSize = .zero
    private var cellInset: CGFloat = 1.0
    private var listSource: PhotoExplorerListSource?
    private let viewModel: PhotoExplorerViewModel

    init(viewModel: PhotoExplorerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overriden methods.

    override func viewDidLoad() {
        super.viewDidLoad()
        registerNibs()
        configureRightBarButton()
        collectionView.emptyDataSetSource = self
        
        cellSize = collectionView.mnz_calculateCellSize(forInset: cellInset)
        
        viewModel.invokeCommand = { [weak self] command in
            self?.excuteCommand(command)
        }
        
        SVProgressHUD.show()
        viewModel.dispatch(.onViewReady)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculateCellSizeAndReloadCollectionIfRequired()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.calculateCellSizeAndReloadCollectionIfRequired()
        })
    }
    
    // MARK: - Private methods.
    
    private func registerNibs() {
        collectionView?.register(PhotoExplorerCollectionCell.nib, forCellWithReuseIdentifier: PhotoExplorerCollectionCell.reuseIdentifier)
        collectionView?.register(PhotoExplorerCollectionSectionHeaderView.nib,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PhotoExplorerCollectionSectionHeaderView.reuseIdentifier)

    }
    
    private func excuteCommand(_ command: PhotoExplorerViewModel.Command) {
        switch command {
        case .reloadData(let nodesByDay):
            SVProgressHUD.dismiss()
            listSource = PhotoExplorerListSource(nodesByDay: nodesByDay, collectionView: collectionView)
            collectionView.dataSource = listSource
            collectionView.reloadData()
        case .modified(nodes: let nodes, indexPaths: let indexPaths):
            guard !(collectionView.isDragging || collectionView.isDecelerating || collectionView.isTracking) else { return }
            listSource?.update(nodes: nodes, atIndexPaths: indexPaths)
            collectionView.reloadItems(at: indexPaths)
        case .setTitle(let title):
            self.title = title
        }
    }
    
    private func calculateCellSizeAndReloadCollectionIfRequired() {
        let cellSize = collectionView.mnz_calculateCellSize(forInset: cellInset)
        if cellSize != self.cellSize {
            self.cellSize = cellSize
            collectionView.reloadData()
        }
    }
    
    private func configureRightBarButton() {
        if collectionView.allowsMultipleSelection {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel,
                target: self,
                action: #selector(cancelButtonPressed(_:))
            )
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(named: "selectAll"),
                style: .plain,
                target: self,
                action: #selector(selectButtonPressed(_:))
            )
        }
    }
    
    private func configureLeftBarButton() {
        if collectionView.allowsMultipleSelection {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(named: "selectAll"),
                style: .plain,
                target: self,
                action: #selector(selectAllButtonPressed(_:))
            )
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    @objc private func selectAllButtonPressed(_ barButtonItem: UIBarButtonItem) {
        listSource?.selectAllNodes()
        configureToolbarButtons()
        viewModel.dispatch(.updateTitle(nodeCount: listSource?.selectedNodes?.count ?? 0))
    }
    
    @objc private func cancelButtonPressed(_ barButtonItem: UIBarButtonItem) {
        endEditingMode()
    }
    
    @objc private func selectButtonPressed(_ barButtonItem: UIBarButtonItem) {
        collectionView.allowsMultipleSelection = true
        listSource?.allowMultipleSelection = true
        configureBarButtons()
        configureToolbarButtons()
        showToolbar()
        viewModel.dispatch(.updateTitle(nodeCount: listSource?.selectedNodes?.count ?? 0))
    }
    
    private func configureBarButtons() {
        configureRightBarButton()
        configureLeftBarButton()
    }
    
    override func endEditingMode() {
        collectionView.allowsMultipleSelection = false
        listSource?.allowMultipleSelection = false
        configureBarButtons()
        hideToolbar()
        viewModel.dispatch(.updateTitleToDefault)
    }
    
    override func selectedNodes() -> [MEGANode]? {
        listSource?.selectedNodes
    }
}

// MARK: Collection view delegate

extension PhotosExplorerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let node = listSource?.nodeAtIndexPath(indexPath) else { return }
        if collectionView.allowsMultipleSelection {
            listSource?.didSelectNodeAtIndexPath(indexPath)
            configureToolbarButtons()
            viewModel.dispatch(.updateTitle(nodeCount: listSource?.selectedNodes?.count ?? 0))
        } else {
            viewModel.dispatch(.didSelectNode(node: node))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView.allowsMultipleSelection {
            listSource?.didDeselectNodeAtIndexPath(indexPath)
            configureToolbarButtons()
            viewModel.dispatch(.updateTitle(nodeCount: listSource?.selectedNodes?.count ?? 0))
        }
    }
}

// MARK: Collection view flow layout delegate

extension PhotosExplorerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 46.0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: cellInset, left: cellInset, bottom: cellInset, right: cellInset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellInset
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellInset
    }
}

// MARK: Empty data source delegate

extension PhotosExplorerViewController: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        return EmptyStateView(emptyStateViewModel: viewModel.emptyStateViewModel)
    }
}


