
final class FilesExplorerGridSource: NSObject {
    private unowned let collectionView: UICollectionView
    private(set) var nodes: [MEGANode]?
    private(set) var selectedNodes: [MEGANode]?
    private let moreInfoAction: ((MEGANode, UIButton) -> Void)
    var allowsMultipleSelection: Bool {
        didSet {
            guard oldValue != allowsMultipleSelection else { return }
            selectedNodes = allowsMultipleSelection ? [] : nil
            collectionView.visibleCells.forEach { cell in
                guard let gridCell = cell as? FileExplorerGridCell, let viewModel = gridCell.viewModel else { return }
                viewModel.markSelection = false
                viewModel.allowsSelection = allowsMultipleSelection
            }
        }
    }
    
    init(collectionView: UICollectionView,
         nodes: [MEGANode]?,
         allowsMultipleSelection: Bool,
         selectedNodes: [MEGANode]?,
         moreInfoAction: @escaping ((MEGANode, UIButton) -> Void)) {
        self.collectionView = collectionView
        self.nodes = nodes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.selectedNodes = selectedNodes
        self.moreInfoAction = moreInfoAction
        super.init()
    }
    
    func toggleIndexPathSelection(_ indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? FileExplorerGridCell,
              let viewModel = cell.viewModel,
              let node = nodes?[indexPath.item]  else {
            return
        }
        
        viewModel.markSelection = !viewModel.markSelection
        
        if selectedNodes?.contains(node) ?? false {
            selectedNodes?.removeAll(where: { $0 == node })
        } else {
            selectedNodes?.append(node)
        }
    }
    
    func toggleSelectAllNodes() {
        selectedNodes = (selectedNodes == nodes) ? nil : nodes
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard let gridCell = cell as? FileExplorerGridCell else { return }
        gridCell.viewModel?.updateSelection()
    }
    
    func updateCells(forNodes nodes: [MEGANode]) {
        nodes.forEach(reloadCell(withNode:))
    }
    
    private func reloadCell(withNode node: MEGANode) {
        collectionView.visibleCells.forEach { cell in
            guard let gridCell = cell as? FileExplorerGridCell,
                  gridCell.viewModel?.nodeHandle == node.handle else {
                return
            }
            
            gridCell.viewModel = viewModel(forNode: node, cell: gridCell)
        }
    }
    
    private func viewModel(forNode node: MEGANode,
                           cell: FileExplorerGridCell) -> FileExplorerGridCellViewModel {
        return FileExplorerGridCellViewModel(
            node: node,
            allowsSelection: allowsMultipleSelection,
            markSelection: selectedNodes?.contains(node) ?? false,
            delegate: cell) { [weak self] node, button in
            self?.moreInfoAction(node, button)
        }
    }
}

// MARK:- UICollectionViewDataSource

extension FilesExplorerGridSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return nodes?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FileExplorerGridCell.reuseIdentifier,
                for: indexPath
        ) as? FileExplorerGridCell,
        let nodes = nodes else {
            return UICollectionViewCell()
        }
        
        cell.viewModel = viewModel(forNode: nodes[indexPath.item], cell: cell)
        return cell
    }
}
