final class FavouritesExplorerGridSource: NSObject {
    
    private enum FavouritesSection: Int {
        case folders = 0, files

        init(section: Int) {
            switch section {
            case 0: self = .folders
            default: self = .files
            }
        }
        
        func cellIdentifier() -> String {
            NodeCollectionViewCell.reusableIdentifier
        }
        
        func sizingViewCell() -> NodeCollectionViewCell {
            NodeCollectionViewCell.instantiateFromNib
        }
        
        static func count() -> Int {
            return 2
        }
    }
    
    private unowned let collectionView: UICollectionView
    private(set) var allNodes: [MEGANode]?
    private(set) var selectedNodes: [MEGANode]?
    private var fileNodes: [MEGANode] = []
    private var folderNodes: [MEGANode] = []
    weak var delegate: (any FilesExplorerGridSourceDelegate)?
    var allowsMultipleSelection: Bool {
        didSet {
            guard oldValue != allowsMultipleSelection else { return }
            selectedNodes = allowsMultipleSelection ? [] : nil
            collectionView.allowsMultipleSelection = allowsMultipleSelection
            collectionView.reloadData()
        }
    }

    init(collectionView: UICollectionView,
         nodes: [MEGANode]?,
         allowsMultipleSelection: Bool,
         selectedNodes: [MEGANode]?,
         delegate: (any FilesExplorerGridSourceDelegate)?) {
        self.collectionView = collectionView
        self.allNodes = nodes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.selectedNodes = selectedNodes
        self.delegate = delegate
        super.init()
        self.configureNodes()
    }
    
    private func configureNodes() {
        guard let allNodes = allNodes else {
            fileNodes = []
            folderNodes = []
            return
        }
        
        let sortOrder = SortOrderType.defaultSortOrderType(forNode: nil)
        let isValidSort = [SortOrderType.nameDescending,
                           SortOrderType.nameAscending,
                           SortOrderType.label].contains(sortOrder)
        // Folder can't be sorted by size
        let folderSortOrder = isValidSort ? sortOrder : .nameAscending
        folderNodes = allNodes.folderNodeList().sort(by: folderSortOrder)
        fileNodes = allNodes.fileNodeList().sort(by: sortOrder)
        collectionView.reloadData()
    }
    
    func toggleIndexPathSelection(_ indexPath: IndexPath) {
        guard let node = getNode(at: indexPath) else {
            return
        }

        if selectedNodes?.contains(node) ?? false {
            selectedNodes?.removeAll(where: { $0 == node })
        } else {
            selectedNodes?.append(node)
        }
    }
    
    func select(indexPath: IndexPath) {
        guard let node = getNode(at: indexPath) else {
            return
        }

        if !(selectedNodes?.contains(node) ?? false) {
            selectedNodes?.append(node)
        }
    }
    
    func deselect(indexPath: IndexPath) {
        guard let node = getNode(at: indexPath) else {
            return
        }
        
        if selectedNodes?.contains(node) ?? false {
            selectedNodes?.removeAll(where: { $0 == node })
        }
    }
    
    func toggleSelectAllNodes() {
        let selectedSet = Set(selectedNodes ?? [])
        let nodeSet = Set(allNodes ?? [])
        let isSelectedAll = selectedSet == nodeSet
        selectedNodes = isSelectedAll ? [] : allNodes
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        
        if collectionView.allowsMultipleSelection {
            if !cell.isSelected {
                if let node = getNode(at: indexPath),
                    let selectedNodes = selectedNodes, selectedNodes.contains(node) {
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                    cell.isSelected = true
                }
            }
        }
    }
    
    func getNode(at indexPath: IndexPath) -> MEGANode? {
        switch indexPath.section {
        case FavouritesSection.files.rawValue: return fileNodes[safe: indexPath.row]
        case FavouritesSection.folders.rawValue: return folderNodes[safe: indexPath.row]
        default: return nil
        }
    }
    
    func getSelectedNode(at indexPath: IndexPath, result: (MEGANode?, [MEGANode]?) -> Void) {
        guard let selectedNode = getNode(at: indexPath) else {
            result(nil, nil)
            return
        }

        let nodeName = selectedNode.name ?? ""
        if nodeName.fileExtensionGroup.isVisualMedia {
            let multiMediaNodes = fileNodes.multiMediaNodeList()
            result(selectedNode, multiMediaNodes)
        } else {
            result(selectedNode, allNodes)
        }
    }
    
    private func getRowCount(for section: Int) -> Int {
        switch section {
        case FavouritesSection.files.rawValue: return fileNodes.count
        case FavouritesSection.folders.rawValue: return folderNodes.count
        default: return 0
        }
    }
}

// MARK: - UICollectionViewDataSource
extension FavouritesExplorerGridSource: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return FavouritesSection.count()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getRowCount(for: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = FavouritesSection(section: indexPath.section)
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: section.cellIdentifier(), for: indexPath) as? NodeCollectionViewCell,
              let node = getNode(at: indexPath) else {
            return UICollectionViewCell()
        }
        
        cell.configureCell(for: node,
                           allowedMultipleSelection: collectionView.allowsMultipleSelection, 
                           isFromSharedItem: false,
                           sdk: .shared,
                           delegate: self)
        return cell
    }
}

// MARK: - Manage CollectionViewCells size
extension FavouritesExplorerGridSource: DynamicTypeCollectionViewSizing {
    func provideSizingCell(for indexPath: IndexPath) -> UICollectionViewCell? {
        guard let node = getNode(at: indexPath) else { return nil }
        let cell = FavouritesSection(section: indexPath.section).sizingViewCell()
        cell.configureCell(for: node,
                           allowedMultipleSelection: collectionView.allowsMultipleSelection,
                           isFromSharedItem: false,
                           sdk: .shared,
                           delegate: self,
                           isSampleRow: true)
        return cell
    }
}

// MARK: - NodeCollectionViewCellDelegate
extension FavouritesExplorerGridSource: NodeCollectionViewCellDelegate {
    func showMoreMenu(for node: MEGANode, from sender: UIButton) {
        guard !collectionView.allowsMultipleSelection else { return }
        delegate?.showMoreNodeOptions(for: node, sender: sender)
    }
}
