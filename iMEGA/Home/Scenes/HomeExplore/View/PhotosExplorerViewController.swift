
import UIKit


class PhotosExplorerViewController: ExplorerBaseViewController {
    
    @IBOutlet private weak var collectionView: UICollectionView!

    private var cellSize: CGSize = .zero
    private var cellInset: CGFloat = 1.0
    private var listSource: PhotoExplorerListSource?
    private let viewModel: PhotoExplorerViewModel
    
    private lazy var selectAllBarButtonItem = UIBarButtonItem(
        image: Asset.Images.NavigationBar.selectAll.image,
        style: .plain,
        target: self,
        action: #selector(selectButtonPressed(_:))
    )
    
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
        selectAllBarButtonItem.isEnabled = false
        
        cellSize = collectionView.mnz_calculateCellSize(forInset: cellInset)
        
        viewModel.invokeCommand = { [weak self] command in
            self?.excuteCommand(command)
        }
        
        viewModel.dispatch(.onViewReady)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AudioPlayerManager.shared.addDelegate(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AudioPlayerManager.shared.removeDelegate(self)
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
            listSource = PhotoExplorerListSource(
                nodesByDay: nodesByDay,
                collectionView: collectionView,
                selectedNodes: listSource?.selectedNodes,
                allowMultipleSelection: listSource?.allowMultipleSelection ?? false
            )
            collectionView.dataSource = listSource
            collectionView.emptyDataSetSource = self
            collectionView.reloadData()
            selectAllBarButtonItem.isEnabled = !(listSource?.isDataSetEmpty() ?? true)
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
            navigationItem.rightBarButtonItem = selectAllBarButtonItem
        }
    }
    
    private func configureLeftBarButton() {
        if collectionView.allowsMultipleSelection {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: Asset.Images.NavigationBar.selectAll.image,
                style: .plain,
                target: self,
                action: #selector(selectAllButtonPressed(_:))
            )
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    @objc private func selectAllButtonPressed(_ barButtonItem: UIBarButtonItem) {
        listSource?.toggleSelectAllNodes()
        configureToolbarButtons()
        viewModel.dispatch(.updateTitle(nodeCount: listSource?.selectedNodes?.count ?? 0))
    }
    
    @objc private func cancelButtonPressed(_ barButtonItem: UIBarButtonItem) {
        endEditingMode()
    }
    
    @objc private func selectButtonPressed(_ barButtonItem: UIBarButtonItem) {
        startEditingMode()
    }
    
    private func configureBarButtons() {
        configureRightBarButton()
        configureLeftBarButton()
    }
    
    private func startEditingMode() {
        collectionView.allowsMultipleSelection = true
        
        if #available(iOS 14, *) {
            collectionView.allowsMultipleSelectionDuringEditing = true;
        }
        
        if (listSource?.allowMultipleSelection ?? false) == false {
            listSource?.allowMultipleSelection = true
        }
        
        configureBarButtons()
        configureToolbarButtons()
        showToolbar()
        viewModel.dispatch(.updateTitle(nodeCount: listSource?.selectedNodes?.count ?? 0))
        
        audioPlayer(hidden: true)
    }
    
    override func endEditingMode() {
        collectionView.allowsMultipleSelection = false
        
        if #available(iOS 14, *) {
            collectionView.allowsMultipleSelectionDuringEditing = false;
        }
        
        listSource?.allowMultipleSelection = false
        configureBarButtons()
        hideToolbar()
        viewModel.dispatch(.updateTitleToDefault)
        
        audioPlayer(hidden: false)
    }
    
    override func selectedNodes() -> [MEGANode]? {
        listSource?.selectedNodes
    }
    
    private func audioPlayer(hidden: Bool) {
        if AudioPlayerManager.shared.isPlayerAlive() {
            AudioPlayerManager.shared.playerHidden(hidden, presenter: self)
        }
    }
}

// MARK: Collection view delegate

extension PhotosExplorerViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        listSource?.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let node = listSource?.nodeAtIndexPath(indexPath) else { return }
        if collectionView.allowsMultipleSelection {
            listSource?.didSelectNodeAtIndexPath(indexPath)
            configureToolbarButtons()
            viewModel.dispatch(.updateTitle(nodeCount: listSource?.selectedNodes?.count ?? 0))
        } else {
            viewModel.dispatch(.didSelectNode(node: node))
            collectionView.clearSelectedItems()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView.allowsMultipleSelection {
            listSource?.didDeselectNodeAtIndexPath(indexPath)
            configureToolbarButtons()
            viewModel.dispatch(.updateTitle(nodeCount: listSource?.selectedNodes?.count ?? 0))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        startEditingMode()
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
        return EmptyStateView.create(for: .photos)
    }
}

//MARK:- AudioPlayer
extension PhotosExplorerViewController: AudioPlayerPresenterProtocol {
    func updateContentView(_ height: CGFloat) {
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: height, right: 0)
    }
}
