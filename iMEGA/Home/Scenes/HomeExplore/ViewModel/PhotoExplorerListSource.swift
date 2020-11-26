
class PhotoExplorerListSource: NSObject {
    private var nodesByDay: [[MEGANode]]
    private(set) var selectedNodes: [MEGANode]?
    private unowned var collectionView: UICollectionView
    
    var allowMultipleSelection: Bool {
        didSet {
            selectedNodes = allowMultipleSelection ? [] : nil
            collectionView.visibleCells.forEach { cell in
                if let photoExplorerCollectionCell = cell as? PhotoExplorerCollectionCell {
                    photoExplorerCollectionCell.allowSelection = allowMultipleSelection
                }
            }
            
            if !allowMultipleSelection {
                collectionView.indexPathsForSelectedItems?.forEach {
                    collectionView.deselectItem(at: $0, animated: false)
                }
            }
        }
    }
    
    init(nodesByDay: [[MEGANode]],
         collectionView: UICollectionView,
         selectedNodes: [MEGANode]?,
         allowMultipleSelection: Bool) {
        self.nodesByDay = nodesByDay
        self.collectionView = collectionView
        self.selectedNodes = selectedNodes
        self.allowMultipleSelection = allowMultipleSelection
        super.init()
    }
    
    func update(nodes:  [MEGANode], atIndexPaths indexPaths: [IndexPath]) {
        for (index, element) in indexPaths.enumerated() {
            let originalNode = nodesByDay[element.section][element.item]
            let updatedNode = nodes[index]
            
            // if the node exsists in selected node list then replace it.
            if let index = selectedNodes?.firstIndex(of: originalNode) {
                selectedNodes?[index] = updatedNode
            }
            
            nodesByDay[element.section][element.item] = updatedNode
        }
    }
    
    func nodeAtIndexPath(_ indexPath: IndexPath) -> MEGANode {
        return nodesByDay[indexPath.section][indexPath.item]
    }
    
    func didSelectNodeAtIndexPath(_ indexPath: IndexPath) {
        selectedNodes?.append(nodeAtIndexPath(indexPath))
    }
    
    func didDeselectNodeAtIndexPath(_ indexPath: IndexPath) {
        let selectedNode = nodeAtIndexPath(indexPath)
        selectedNodes?.removeAll(where: { $0 == selectedNode })
    }
    
    func selectAllNodes() {
        selectedNodes = nodesByDay.reduce([], +)
        
        collectionView.indexPathsForVisibleItems.forEach { indexPath in
            if let photoExplorerCollectionCell = collectionView.cellForItem(at: indexPath) as? PhotoExplorerCollectionCell {
                photoExplorerCollectionCell.allowSelection = allowMultipleSelection
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
            }
        }

    }
}

extension PhotoExplorerListSource: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        nodesByDay.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        nodesByDay[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoExplorerCollectionCell.reuseIdentifier, for: indexPath) as? PhotoExplorerCollectionCell else {
            return UICollectionViewCell()
        }
        
        cell.viewModel = FileExplorerGridCellViewModel(node: nodesByDay[indexPath.section][indexPath.row])

        cell.allowSelection = allowMultipleSelection
        
        if collectionView.allowsMultipleSelection,
           selectedNodes?.contains(nodesByDay[indexPath.section][indexPath.row]) ?? false {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            cell.isSelected = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let headerView = collectionView.dequeueReusableSupplementaryView(ofKind:  UICollectionView.elementKindSectionHeader,
                                                                         withReuseIdentifier: PhotoExplorerCollectionSectionHeaderView.reuseIdentifier,
                                                                         for: indexPath) as? PhotoExplorerCollectionSectionHeaderView else {
                                                                            return UICollectionReusableView()
        }
        if let modificationDate = nodesByDay[indexPath.section].first?.modificationTime {
            if NSCalendar.current.isDateInToday(modificationDate) {
                headerView.label.text = NSLocalizedString("TODAY", comment: "Section title for the photo explorer view")
            } else if NSCalendar.current.isDateInYesterday(modificationDate) {
                headerView.label.text = NSLocalizedString("YESTERDAY", comment: "Section title for the photo explorer view")
            } else {
                headerView.label.text = (modificationDate as NSDate).mnz_formattedDateMediumStyle()
            }
        }
        return headerView
    }
}
