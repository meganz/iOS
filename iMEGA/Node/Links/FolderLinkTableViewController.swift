
import Foundation
import MEGADomain

class FolderLinkTableViewController: UIViewController  {
    
    @IBOutlet weak var tableView: UITableView!
    
    var folderLink: FolderLinkViewController
    
    @objc class func instantiate(withFolderLink folderLink: FolderLinkViewController) -> FolderLinkTableViewController {
        guard let folderLinkTableVC = UIStoryboard(name: "Links", bundle: nil).instantiateViewController(withIdentifier: "FolderLinkTableViewControllerID") as? FolderLinkTableViewController else {
            fatalError("Could not instantiate FolderLinkTableViewController")
        }

        folderLinkTableVC.folderLink = folderLink
        
        return folderLinkTableVC
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.folderLink = FolderLinkViewController()
        super.init(coder: aDecoder)
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
        
        if editing {
            tableView.visibleCells.forEach { (cell) in
                let view = UIView()
                view.backgroundColor = .clear
                cell.selectedBackgroundView = view
            }
        } else {
            tableView.visibleCells.forEach { (cell) in
                cell.selectedBackgroundView = nil
            }
        }
    }
    
    @objc func tableViewSelectIndexPath(_ indexPath: IndexPath) {
        tableView(tableView, didSelectRowAt: indexPath)
    }
    
    @objc func reload(node: MEGANode) {
        guard MEGAReachabilityManager.isReachable(),
              let rowIndex = folderLink.searchController.isActive ? folderLink.searchNodesArray?.firstIndex(of: node) : folderLink.nodesArray.firstIndex(of: node),
              tableView.hasRow(at: IndexPath(row: rowIndex, section: 0)) else { return }
        
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: [IndexPath(row: rowIndex, section: 0)], with: .none)
        }
    }
    
    private func getNode(at indexPath: IndexPath) -> MEGANode? {
        folderLink.searchController.isActive ? folderLink.searchNodesArray?[safe: indexPath.row] : folderLink.nodesArray[safe: indexPath.row]
    }
}

// MARK: - UITableViewDataSource

extension FolderLinkTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if MEGAReachabilityManager.isReachable() {
            if folderLink.searchController.isActive {
                return folderLink.searchNodesArray?.count ?? 0
            } else {
                if folderLink.isFolderLinkNotValid {
                    return 0
                } else {
                    return folderLink.nodesArray.count
                }
            }
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let node = getNode(at: indexPath),
              let cell = tableView.dequeueReusableCell(withIdentifier: "nodeCell", for: indexPath) as? NodeTableViewCell else {
            fatalError("Could not instantiate NodeCollectionViewCell. Node at \(indexPath) not found: \(getNode(at: indexPath) == nil)")
        }
        
        cell.backgroundColor = UIColor.mnz_secondaryBackgroundGroupedElevated(traitCollection)
        cell.infoLabel.textColor = UIColor.mnz_label()
        
        config(cell, by: node, at: indexPath)
        
        return cell
    }
    
    private func config(_ cell: NodeTableViewCell, by node: MEGANode, at indexPath: IndexPath) {
        if node.isFile() {
            if node.hasThumbnail() {
                Helper.thumbnail(for: node, api: MEGASdkManager.sharedMEGASdkFolder(), cell: cell)
            } else {
                cell.thumbnailImageView.image = NodeAssetsManager.shared.icon(for: node)
            }
            cell.infoLabel.text = Helper.sizeAndModicationDate(for: node, api: MEGASdkManager.sharedMEGASdkFolder())
        } else if node.isFolder() {
            cell.thumbnailImageView.image = NodeAssetsManager.shared.icon(for: node)
            cell.infoLabel.text = Helper.filesAndFolders(inFolderNode: node, api: MEGASdkManager.sharedMEGASdkFolder())
        }
        
        cell.thumbnailPlayImageView.isHidden = node.name?.mnz_isVideoPathExtension != true
        cell.nameLabel.text = node.name
        cell.nameLabel.textColor = UIColor.mnz_label()
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
        
        cell.separatorView.layer.borderColor = UIColor.mnz_separator(for: traitCollection).cgColor
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
                                        image: Asset.Images.ActionSheetIcons.select.image) { _ in
                self.setTableViewEditing(true, animated: true)
                self.tableView?.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
                self.tableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
            return UIMenu(title: "", children: [selectAction])
        }

        return contextMenuConfiguration
    }
    
    func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let folderLinkVC = animator.previewViewController as? FolderLinkViewController else { return }
        animator.addCompletion {
            self.navigationController?.pushViewController(folderLinkVC, animated: true)
        }
    }
}
