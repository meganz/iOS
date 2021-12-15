
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
    
    func nodeAtIndexPath(_ indexPath: IndexPath) -> MEGANode? {
        nodesByDay[safe: indexPath.section]?[safe: indexPath.item]
    }
    
    func didSelectNodeAtIndexPath(_ indexPath: IndexPath) {
        guard let node = nodeAtIndexPath(indexPath) else { return }
        selectedNodes?.append(node)
    }
    
    func didDeselectNodeAtIndexPath(_ indexPath: IndexPath) {
        guard let selectedNode = nodeAtIndexPath(indexPath) else { return }
        selectedNodes?.removeAll(where: { $0 == selectedNode })
    }
    
    func toggleSelectAllNodes() {
        let allNodes = nodesByDay.reduce([], +)
        let selectedSet = Set(selectedNodes ?? [])
        let allNodeSet = Set(allNodes)
        selectedNodes = selectedSet == allNodeSet ? [] : allNodes
        // update the marker for the visible items
        collectionView.visibleCells.forEach { cell in
            guard let cell = cell as? PhotoExplorerCollectionCell else { return }
            cell.allowSelection = allowMultipleSelection
            cell.isSelected = !(selectedNodes?.isEmpty ?? true)
            if selectedNodes?.isEmpty ?? true {
                if let indexPath = collectionView.indexPath(for: cell) {
                    collectionView.deselectItem(at: indexPath, animated: false)
                }
            } else {
                collectionView.selectItem(at: collectionView.indexPath(for: cell), animated: false, scrollPosition: [])
            }
        }
    }
    
    func isDataSetEmpty() -> Bool {
        return nodesByDay.isEmpty
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
                headerView.label.text = Strings.Localizable.today.localizedUppercase
            } else if NSCalendar.current.isDateInYesterday(modificationDate) {
                headerView.label.text = Strings.Localizable.yesterday.localizedUppercase
            } else {
                headerView.label.text = (modificationDate as NSDate).mnz_formattedDateMediumStyle()
            }
        }
        return headerView
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard let cell = cell as? PhotoExplorerCollectionCell else { return }
        
        cell.allowSelection = allowMultipleSelection
        
        if collectionView.allowsMultipleSelection{
            if selectedNodes?.contains(nodesByDay[indexPath.section][indexPath.row]) ?? false {
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                cell.isSelected = true
            } else {
                collectionView.deselectItem(at: indexPath, animated: false)
                cell.isSelected = false
            }
        }
    }
}
