protocol FilesExplorerGridSourceDelegate: UIViewController {
    func showMoreNodeOptions(for node: MEGANode, sender: UIView)
}

final class FilesExplorerGridSource: NSObject {
    private unowned let collectionView: UICollectionView
    private(set) var nodes: [MEGANode]?
    private(set) var selectedNodes: [MEGANode]?
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
        self.nodes = nodes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.selectedNodes = selectedNodes
        self.delegate = delegate
        super.init()
    }
    
    func toggleIndexPathSelection(_ indexPath: IndexPath) {
        guard let node = nodes?[indexPath.item] else {
            return
        }

        if selectedNodes?.contains(node) ?? false {
            selectedNodes?.removeAll(where: { $0 == node })
        } else {
            selectedNodes?.append(node)
        }
    }
    
    func select(indexPath: IndexPath) {
        guard let node = nodes?[indexPath.item] else {
            return
        }

        if !(selectedNodes?.contains(node) ?? false) {
            selectedNodes?.append(node)
        }
    }
    
    func deselect(indexPath: IndexPath) {
        guard let node = nodes?[indexPath.item] else {
            return
        }
        
        if selectedNodes?.contains(node) ?? false {
            selectedNodes?.removeAll(where: { $0 == node })
        }
    }
    
    func toggleSelectAllNodes() {
        let selectedSet = Set(selectedNodes ?? [])
        let nodeSet = Set(nodes ?? [])
        selectedNodes = selectedSet == nodeSet ? [] : nodes
        collectionView.reloadData()
    }

    func selectNodes(_ nodes: [MEGANode]) {
        selectedNodes = nodes
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        if collectionView.allowsMultipleSelection,
           !cell.isSelected,
           let node = nodes?[indexPath.item],
           let selectedNodes = selectedNodes,
           selectedNodes.contains(node) {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            cell.isSelected = true
        }
    }
    
    private func reloadCell(withNode node: MEGANode) {
        guard let index = nodes?.firstIndex(of: node) else { return }
        
        if let originalNode = nodes?[index],
           let selectedIndex = selectedNodes?.firstIndex(of: originalNode) {
            selectedNodes?[selectedIndex] = node
        }
        
        nodes?[index] = node
        
        let indexPath = IndexPath(item: index, section: 0)
        let visibleCellsIndexPath = collectionView.indexPathsForVisibleItems
        if visibleCellsIndexPath.contains(indexPath) {
            collectionView.reloadItems(at: [indexPath])
        }
    }
    
    func onTransferCompleted(forNode node: MEGANode) {
        reloadCell(withNode: node)
    }
}

// MARK: - UICollectionViewDataSource

extension FilesExplorerGridSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return nodes?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NodeCollectionViewCell.reusableIdentifier,
                                                            for: indexPath) as? NodeCollectionViewCell,
              let node = nodes?[indexPath.item] else {
            return UICollectionViewCell()
        }
        
        cell.configureCell(for: node,
                           allowedMultipleSelection: collectionView.allowsMultipleSelection,
                           isFromSharedItem: false,
                           sdk: MEGASdk.shared,
                           delegate: self)
        return cell
    }
}

// MARK: - Manage CollectionViewCells size with
extension FilesExplorerGridSource: DynamicTypeCollectionViewSizing {
    func provideSizingCell(for indexPath: IndexPath) -> UICollectionViewCell? {
        guard let node = nodes?[indexPath.item] else { return nil }
        let cell = NodeCollectionViewCell.instantiateFromNib
        cell.configureCell(for: node,
                           allowedMultipleSelection: collectionView.allowsMultipleSelection,
                           isFromSharedItem: false,
                           sdk: MEGASdk.shared,
                           delegate: self,
                           isSampleRow: true)
        return cell
    }
}

// MARK: - NodeCollectionViewCellDelegate
extension FilesExplorerGridSource: NodeCollectionViewCellDelegate {
    func showMoreMenu(for node: MEGANode, from sender: UIButton) {
        guard !collectionView.allowsMultipleSelection else { return }
        delegate?.showMoreNodeOptions(for: node, sender: sender)
    }
}
