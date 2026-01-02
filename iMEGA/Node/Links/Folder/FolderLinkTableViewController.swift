import Foundation
import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n

class FolderLinkTableViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!

    unowned var folderLink: FolderLinkViewController!
    var headerContainerView: UIView?
    private var isCloudDriveRevampEnabled: Bool { DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .cloudDriveRevamp) }

    @objc class func instantiate(withFolderLink folderLink: FolderLinkViewController) -> FolderLinkTableViewController {
        guard let folderLinkTableVC = UIStoryboard(name: "Links", bundle: nil).instantiateViewController(withIdentifier: "FolderLinkTableViewControllerID") as? FolderLinkTableViewController else {
            fatalError("Could not instantiate FolderLinkTableViewController")
        }

        folderLinkTableVC.folderLink = folderLink
        
        return folderLinkTableVC
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = UIView()
        if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
            tableViewBottomConstraint.isActive = false
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
        addLongPressGestureIfNeeded()
    }

    func addLongPressGestureIfNeeded() {
        guard isCloudDriveRevampEnabled else { return }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPressGesture)
    }

    @objc func showTableHeaderIfRequired() {
        guard folderLink.shouldShowHeaderView else { return }
        tableView.tableHeaderView = folderLink.headerView(for: self)
    }

    @objc func hideTableHeaderView() {
        tableView.tableHeaderView = nil
    }

    @IBAction func nodeActionsTapped(_ sender: UIButton) {
        guard !tableView.isEditing,
                let indexPath = tableView.indexPathForRow(at: sender.convert(CGPoint.zero, to: tableView)),
                let node = getNode(at: indexPath) else {
            return
        }
        
        folderLink.showActions(for: node, from: sender)
    }
    
    @objc func setTableViewEditing(_ editing: Bool, animated: Bool) {
        tableView.setEditing(editing, animated: animated)
        
        folderLink.setViewEditing(editing)
        folderLink.setNavigationBarButton(editing)
        
        tableView.visibleCells.forEach { (cell) in
            cell.setSelectedBackgroundView(withColor: isCloudDriveRevampEnabled ? TokenColors.Background.surface1 : .clear)
        }
    }
    
    private func getNode(at indexPath: IndexPath) -> MEGANode? {
        nodes[safe: indexPath.row]
    }
    
    @objc func reload(node: MEGANode) {
        guard
            isOnline,
            let rowIndex = nodes.firstIndex(of: node),
            tableView.hasRow(at: IndexPath(row: rowIndex, section: 0))
        else { return }
        
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: [IndexPath(row: rowIndex, section: 0)], with: .none)
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }

        let point = gesture.location(in: tableView)

        guard !tableView.isEditing,
              let indexPath = tableView.indexPathForRow(at: point),
              getNode(at: indexPath) != nil else { return }
        folderLink.setEditMode(true)
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        tableView(tableView, didSelectRowAt: indexPath)
    }
}

extension FolderLinkTableViewController {
    var nodes: [MEGANode] {
        guard isOnline else {
            return []
        }
            
        if isSearching {
            return folderLink.searchNodesArray ?? []
        }
        
        return folderLink.nodesArray
    }
    
    var isOnline: Bool {
        MEGAReachabilityManager.isReachable()
    }
    
    var isSearching: Bool {
        folderLink.searchController.isActive
    }
}

// MARK: - UITableViewDataSource

extension FolderLinkTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        nodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = isCloudDriveRevampEnabled ? "RevampedNodeCell" : "nodeCell"
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? NodeTableViewCell
        else {
            fatalError("Could not instantiate NodeCollectionViewCell")
        }
        
        cell.backgroundColor = TokenColors.Background.page
        cell.infoLabel.textColor = TokenColors.Text.secondary
        
        if let node = getNode(at: indexPath) {
            config(cell, by: node, at: indexPath)
        } else {
            CrashlyticsLogger.log("Node at \(indexPath) not found, nodes \(nodes.map { $0.handle }), is online \(isOnline), isSearching: \(isSearching)")
        }

        return cell
    }
    
    private func config(_ cell: NodeTableViewCell, by node: MEGANode, at indexPath: IndexPath) {
        if node.isFile() {
            if node.hasThumbnail() {
                Helper.thumbnail(for: node, api: MEGASdk.sharedFolderLink, cell: cell)
            } else {
                cell.thumbnailImageView.image = NodeAssetsManager.shared.icon(for: node)
            }
            cell.infoLabel.text = Helper.sizeAndModificationDate(for: node, api: MEGASdk.sharedFolderLink)
        } else if node.isFolder() {
            cell.thumbnailImageView.image = NodeAssetsManager.shared.icon(for: node)
            cell.infoLabel.text = Helper.filesAndFolders(inFolderNode: node, api: MEGASdk.sharedFolderLink)
        }

        cell.thumbnailPlayImageView.isHidden = node.name?.fileExtensionGroup.isVideo != true
        cell.nameLabel.text = node.nameAfterDecryptionCheck()
        cell.nameLabel.textColor = TokenColors.Text.primary
        cell.node = node

        if tableView.isEditing {
            folderLink.selectedNodesArray?.forEach {
                if let tempNode = $0 as? MEGANode, tempNode.handle == node.handle {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }

            cell.setSelectedBackgroundView(withColor: isCloudDriveRevampEnabled ? TokenColors.Background.surface1 : .clear)
        } else {
            cell.selectedBackgroundView = nil
        }

        if !isCloudDriveRevampEnabled {
            cell.separatorView.layer.borderColor = TokenColors.Border.strong.cgColor
            cell.separatorView.layer.borderWidth = 0.5
        } else {
            cell.tintColor = TokenColors.Components.selectionControlAlt
        }

        cell.downloadedImageView.image = isCloudDriveRevampEnabled ? MEGAAssets.UIImage.arrowDownCircle : MEGAAssets.UIImage.downloaded

        cell.thumbnailImageView.accessibilityIgnoresInvertColors = true
        cell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = true
        let isDownloaded = node.isFile() && MEGAStore.shareInstance().offlineNode(with: node) != nil
        cell.downloadedView.isHidden = !isDownloaded

        if node.label != .unknown, let labelString = MEGANode.string(for: node.label)?.appending("Small") {
            cell.labelView?.isHidden = false
            cell.labelImageView?.image = MEGAAssets.UIImage.image(named: labelString)
        } else {
            cell.labelView?.isHidden = true
        }
    }
}

// MARK: - UITableViewDelegate

extension FolderLinkTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let node = getNode(at: indexPath) else {
            return
        }
        
        if folderLink.selectedNodesArray == nil {
            folderLink.selectedNodesArray = []
        }
        
        if tableView.isEditing {
            folderLink.selectedNodesArray?.add(node)
            folderLink.setNavigationBarTitleLabel()
            folderLink.areAllNodesSelected = folderLink.selectedNodesArray?.count == folderLink.nodesArray.count
            let selectedNodesNotEmpty = (folderLink.selectedNodesArray?.count ?? 0) > 0
            folderLink.refreshToolbarButtonsStatus(selectedNodesNotEmpty && folderLink.isDecryptedFolderAndNoUndecryptedNodeSelected())
            if isCloudDriveRevampEnabled {
                // In revamp UI, we need to reload the cell to make the background color to update
                tableView.reloadRows(at: [indexPath], with: .none)
            }

            return
        }
        
        guard node.isFolder() || node.isNodeKeyDecrypted() else {
            showSnackBar(message: Strings.Localizable.CloudDrive.FolderLink.SnackBar.undecryptedFileOpenError)
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        folderLink.didSelect(node)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
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
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        !tableView.isEditing
    }
    
    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        folderLink.setNavigationBarButton(tableView.isEditing)
        
        if !tableView.isEditing {
            setTableViewEditing(true, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if isCloudDriveRevampEnabled { return nil }
        let contextMenuConfiguration = UIContextMenuConfiguration(identifier: nil) {
            guard let node = self.getNode(at: indexPath) else { return nil }
            if node.isFolder() {
                let folderLinkVC = self.folderLink.fromNode(node)
                return folderLinkVC
            } else {
                return nil
            }
        } actionProvider: { _ in
            let selectAction = UIAction(title: Strings.Localizable.select,
                                        image: MEGAAssets.UIImage.selectItem) { _ in
                self.setTableViewEditing(true, animated: true)
                self.tableView?.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
                self.tableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
            return UIMenu(title: "", children: [selectAction])
        }

        return contextMenuConfiguration
    }
    
    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: any UIContextMenuInteractionCommitAnimating) {
        guard let folderLinkVC = animator.previewViewController as? FolderLinkViewController else { return }
        animator.addCompletion {
            self.navigationController?.pushViewController(folderLinkVC, animated: true)
        }
    }
}

extension FolderLinkTableViewController: FolderLinkViewHosting {}
