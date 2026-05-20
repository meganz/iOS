import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGAInfrastructure
import MEGAL10n

class FolderLinkCollectionViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!

    unowned var folderLink: FolderLinkViewController!
    var headerContainerView: UIView?

    let layout = CHTCollectionViewWaterfallLayout()
    
    var fileList = [MEGANode]()
    var folderList = [MEGANode]()
    
    var dtCollectionManager: DynamicTypeCollectionManager?
    
    lazy var diffableDataSource = FolderLinkCollectionViewDiffableDataSource(collectionView: collectionView, controller: self)

    private var displayNodes: [MEGANode]? {
        folderLink.searchController.isActive ? folderLink.searchNodesArray : folderLink.nodesArray
    }

    private let hapticFeedbackUsecase = HapticFeedbackUseCase()

    @objc class func instantiate(withFolderLink folderLink: FolderLinkViewController) -> FolderLinkCollectionViewController {
        guard let folderLinkCollectionVC = UIStoryboard(name: "Links", bundle: nil).instantiateViewController(withIdentifier: "FolderLinkCollectionViewControllerID") as? FolderLinkCollectionViewController else {
            fatalError("Could not instantiate FolderLinkCollectionViewController")
        }

        folderLinkCollectionVC.folderLink = folderLink
        
        return folderLinkCollectionVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        setupDataSource()
        addLongPressGestureIfNeeded()
        
        if #available(iOS 26.0, *) {
            collectionViewBottomConstraint.priority = .defaultLow
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadData()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.layout.configThumbnailListColumnCount()
        }, completion: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            dtCollectionManager?.resetCollectionItems()
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func setupDataSource() {
        diffableDataSource.configureDataSource()
    }

    private func addLongPressGestureIfNeeded() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPressGesture)
    }

    private func setupCollectionView() {
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.minimumColumnSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.configThumbnailListColumnCount()
        
        collectionView
            .register(
                NodeCollectionViewCell.cellNib,
                forCellWithReuseIdentifier: NodeCollectionViewCell.reusableIdentifier
            )

        collectionView
            .register(
                NodeCollectionViewCell.folderLinkCellNib,
                forCellWithReuseIdentifier: NodeCollectionViewCell.folderLinkReusableIdentifier
            )

        collectionView.collectionViewLayout = layout
        
        dtCollectionManager = DynamicTypeCollectionManager(delegate: self)
    }
    
    private func buildNodeListFor(fileType: FileType) -> [MEGANode] {
        displayNodes?.filter { ($0.isFile() && fileType == .file) || ($0.isFolder() && fileType == .folder) } ?? []
    }
    
    func getNode(at indexPath: IndexPath) -> MEGANode? {
        let listOfNodes = folderLink.searchController.isActive ? folderLink.searchNodesArray : folderLink.nodesArray
        return listOfNodes?[safe: indexPath.row]
    }
    
    @objc func setCollectionViewEditing(_ editing: Bool, animated: Bool) {
        collectionView.allowsMultipleSelection = editing
        
        collectionView.allowsMultipleSelectionDuringEditing = editing
        
        folderLink.setViewEditing(editing)

        diffableDataSource.reload(nodes: folderList + fileList)
    }
    
    @objc func reloadData() {
        if MEGAReachabilityManager.isReachable(), let listOfNodes = folderLink.searchController.isActive ? folderLink.searchNodesArray : folderLink.nodesArray,
           !listOfNodes.isEmpty {
            removeErrorViewIfRequired()
            // For revamp UI, we display one single section for listOfNodes instead of 2 sections for folders and files.
            // [SAO-3147] Refactor the data source to fully remove .folder and .file separation.
            diffableDataSource.load(data: [.folder: listOfNodes], keys: [.folder])
        } else {
            diffableDataSource.load(data: [:], keys: [])
            showErrorViewIfRequired()
        }
    }

    @objc func collectionViewSelectIndexPath(_ indexPath: IndexPath) {
        collectionView(collectionView, didSelectItemAt: indexPath)
    }
    
    @objc func reload(node: MEGANode) {
        if MEGAReachabilityManager.isReachable() {
            diffableDataSource.reload(nodes: [node])
        } else {
            diffableDataSource.load(data: [:], keys: [])
            showErrorViewIfRequired()
        }
    }
    
    private func showErrorViewIfRequired() {
        guard view.subviews.notContains(where: { $0 is EmptyStateView}),
              let customView = folderLink.customView(forEmptyDataSet: collectionView) else { return }
        view.wrap(customView)
    }
    
    private func removeErrorViewIfRequired() {
        view.subviews.lazy.filter({ $0 is EmptyStateView}).forEach({ $0.removeFromSuperview() })
    }
}

// MARK: - UICollectionViewDelegate

extension FolderLinkCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let node = getNode(at: indexPath) else {
            return
        }

        if collectionView.allowsMultipleSelection {
            folderLink.selectedNodesArray?.add(node)
            folderLink.setNavigationBarTitleLabel()
            folderLink.refreshToolbarButtonsStatus(folderLink.isDecryptedFolderAndNoUndecryptedNodeSelected())
            folderLink.areAllNodesSelected = folderLink.selectedNodesArray?.count == folderLink.nodesArray.count
            return
        }
        
        guard node.isFolder() || node.isNodeKeyDecrypted() else {
            showSnackBar(message: Strings.Localizable.CloudDrive.FolderLink.SnackBar.undecryptedFileOpenError)
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        
        folderLink.didSelect(node)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView.allowsMultipleSelection {
            guard let node = getNode(at: indexPath), let selectedNodesCopy = folderLink.selectedNodesArray as? [MEGANode] else {
                return
            }

            selectedNodesCopy.forEach { (tempNode) in
                if node.handle == tempNode.handle {
                    folderLink.selectedNodesArray?.remove(tempNode)
                }
            }
            
            folderLink.setNavigationBarTitleLabel()
            let selectedNodesNotEmpty = folderLink.selectedNodesArray?.count != 0
            folderLink.refreshToolbarButtonsStatus(selectedNodesNotEmpty && folderLink.isDecryptedFolderAndNoUndecryptedNodeSelected())
            folderLink.areAllNodesSelected = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView.allowsMultipleSelection {
            guard let node = getNode(at: indexPath), let selectedNodesCopy = folderLink.selectedNodesArray as? [MEGANode] else {
                return
            }
            
            let isSelected = selectedNodesCopy.contains { $0.handle == node.handle }
            if isSelected {
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
            
            cell.isSelected = isSelected
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setCollectionViewEditing(true, animated: true)
    }
}

extension FolderLinkCollectionViewController: CHTCollectionViewDelegateWaterfallLayout {
    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAt indexPath: IndexPath!) -> CGSize {
        // (184, 180) is the size needed for the cells to match with that of revamped CD.
        CGSize(width: 184, height: 180)
    }

    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0, folderLink.shouldShowHeaderView else { return 0 }
        return 40
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: collectionView)

        guard !collectionView.isEditing,
              let indexPath = collectionView.indexPathForItem(at: point),
              getNode(at: indexPath) != nil else { return }
        hapticFeedbackUsecase.generateHapticFeedback(.light)
        folderLink.setEditMode(true)
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        collectionView(collectionView, didSelectItemAt: indexPath)
    }
}

extension FolderLinkCollectionViewController: NodeCollectionViewCellDelegate {
    func showMoreMenu(for node: MEGANode, from sender: UIButton) {
        guard !collectionView.allowsMultipleSelection else { return }
        folderLink.showActions(for: node, from: sender)
    }
}

extension FolderLinkCollectionViewController: FolderLinkViewHosting {}
