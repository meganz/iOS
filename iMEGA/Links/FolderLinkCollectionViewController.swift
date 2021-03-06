
import Foundation


class FolderLinkCollectionViewController: UIViewController  {
   
    @IBOutlet weak var collectionView: UICollectionView!

    var folderLink: FolderLinkViewController

    let layout = CHTCollectionViewWaterfallLayout()
    
    var fileList = [MEGANode]()
    var folderList = [MEGANode]()
    
    @objc class func instantiate(withFolderLink folderLink: FolderLinkViewController) -> FolderLinkCollectionViewController {
        guard let folderLinkCollectionVC = UIStoryboard(name: "Links", bundle: nil).instantiateViewController(withIdentifier: "FolderLinkCollectionViewControllerID") as? FolderLinkCollectionViewController else {
            fatalError("Could not instantiate FolderLinkCollectionViewController")
        }

        folderLinkCollectionVC.folderLink = folderLink
        
        return folderLinkCollectionVC
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.folderLink = FolderLinkViewController()
        super.init(coder: aDecoder)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupCollectionView()
        reloadData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.layout.configThumbnailListColumnCount()

        }, completion: nil)
    }
    
    private func setupCollectionView() {
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.minimumColumnSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.configThumbnailListColumnCount()
        
        collectionView.collectionViewLayout = layout
    }
    
    private func buildNodeListFor(fileType: FileType) -> [MEGANode] {
        guard let listOfNodes = folderLink.searchController.isActive ? folderLink.searchNodesArray : folderLink.nodesArray else {
            return []
        }
        return listOfNodes.filter { ($0.isFile() && fileType == .file) || ($0.isFolder() && fileType == .folder) }
    }
    
    private func getNode(at indexPath: IndexPath) -> MEGANode? {
        return indexPath.section == ThumbnailSection.file.rawValue ? fileList[safe: indexPath.row] : folderList[safe: indexPath.row]
    }
    
    @objc func setCollectionViewEditing(_ editing: Bool, animated: Bool) {
        collectionView.allowsMultipleSelection = editing
        
        if #available(iOS 14, *) {
            collectionView.allowsMultipleSelectionDuringEditing = editing;
        }
        
        folderLink.setViewEditing(editing)
        
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
    }
    
    @IBAction func nodeActionsTapped(_ sender: UIButton) {
        if collectionView.allowsMultipleSelection {
            return
        }
        guard let indexPath = collectionView.indexPathForItem(at: sender.convert(CGPoint.zero, to: collectionView)) else {
            return
        }
        
        folderLink.showActions(for: getNode(at: indexPath), from: sender)
    }
    
    @objc func reloadData() {
        fileList = buildNodeListFor(fileType: .file)
        folderList = buildNodeListFor(fileType: .folder)
        collectionView.reloadData()
    }
    
    @objc func collectionViewSelectIndexPath(_ indexPath: IndexPath) {
        collectionView(collectionView, didSelectItemAt: indexPath)
    }
}

extension FolderLinkCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == ThumbnailSection.file.rawValue ? fileList.count : folderList.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if MEGAReachabilityManager.isReachable() {
            return Int(ThumbnailSection.count.rawValue)
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellId = indexPath.section == 1 ? "NodeCollectionFileID" : "NodeCollectionFolderID"
        
        guard let node = getNode(at: indexPath), let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? NodeCollectionViewCell else {
            fatalError("Could not instantiate NodeCollectionViewCell or Node at index")
        }
        
        cell.configureCell(for: node, api:MEGASdkManager.sharedMEGASdkFolder())
        cell.selectImageView?.isHidden = !collectionView.allowsMultipleSelection
        cell.moreButton?.isHidden = collectionView.allowsMultipleSelection
        
        return cell
    }
}

extension FolderLinkCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let node = getNode(at: indexPath) else {
            return
        }

        if (collectionView.allowsMultipleSelection) {
            folderLink.selectedNodesArray.add(node)
            folderLink.setNavigationBarTitleLabel()
            folderLink.setToolbarButtonsEnabled(true)
            folderLink.areAllNodesSelected = folderLink.selectedNodesArray.count == folderLink.nodesArray.count
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
                    folderLink.selectedNodesArray.remove(tempNode)
                }
            }
            
            folderLink.setNavigationBarTitleLabel()
            folderLink.setToolbarButtonsEnabled(folderLink.selectedNodesArray.count != 0)
            folderLink.areAllNodesSelected = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView.allowsMultipleSelection {
            guard let node = getNode(at: indexPath), let selectedNodesCopy = folderLink.selectedNodesArray as? [MEGANode] else {
                return
            }
            
            let isSelected = selectedNodesCopy.filter { $0.handle == node.handle }.count > 0
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
        return indexPath.section == ThumbnailSection.file.rawValue ? CGSize(width: Int(ThumbnailSize.width.rawValue), height: Int(ThumbnailSize.heightFile.rawValue)) : CGSize(width: Int(ThumbnailSize.width.rawValue), height: Int(ThumbnailSize.heightFolder.rawValue))
    }
}
