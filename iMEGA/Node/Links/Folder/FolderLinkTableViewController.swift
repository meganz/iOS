import Foundation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n

class FolderLinkTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    unowned var folderLink: FolderLinkViewController!
    
    @objc class func instantiate(withFolderLink folderLink: FolderLinkViewController) -> FolderLinkTableViewController {
        guard let folderLinkTableVC = UIStoryboard(name: "Links", bundle: nil).instantiateViewController(withIdentifier: "FolderLinkTableViewControllerID") as? FolderLinkTableViewController else {
            fatalError("Could not instantiate FolderLinkTableViewController")
        }

        folderLinkTableVC.folderLink = folderLink
        
        return folderLinkTableVC
    }
    
    override func viewDidLoad() {
        tableView.backgroundView = UIView()
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
            let view = UIView()
            view.backgroundColor = .clear
            cell.selectedBackgroundView = editing ?  UIView() : nil
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
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "nodeCell", for: indexPath) as? NodeTableViewCell
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
        cell.nameLabel.text = node.name
        cell.nameLabel.textColor = TokenColors.Text.primary
        cell.node = node
        
        if tableView.isEditing {
            folderLink.selectedNodesArray?.forEach {
                if let tempNode = $0 as? MEGANode, tempNode.handle == node.handle {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
            
            let view = UIView()
            view.backgroundColor = .clear
            cell.selectedBackgroundView = view
        } else {
            cell.selectedBackgroundView = nil
        }
        
        cell.separatorView.layer.borderColor = TokenColors.Border.strong.cgColor
        cell.separatorView.layer.borderWidth = 0.5
        
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = true
        cell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = true
        let isDownloaded = node.isFile() && MEGAStore.shareInstance().offlineNode(with: node) != nil
        cell.downloadedView.isHidden = !isDownloaded
    }
}

// MARK: - UITableViewDelegate

extension FolderLinkTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let node = getNode(at: indexPath) else {
            return
        }
        if tableView.isEditing {
            folderLink.selectedNodesArray?.add(node)
            folderLink.setNavigationBarTitleLabel()
            folderLink.setToolbarButtonsEnabled(true)
            folderLink.areAllNodesSelected = folderLink.selectedNodesArray?.count == folderLink.nodesArray.count
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
            folderLink.setToolbarButtonsEnabled(folderLink.selectedNodesArray?.count != 0)
            folderLink.areAllNodesSelected = false
        }
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        setTableViewEditing(true, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
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
