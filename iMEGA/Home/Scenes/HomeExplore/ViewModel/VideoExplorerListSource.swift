import MEGADomain

final class VideoExplorerListSource: NSObject, FilesExplorerListSourceProtocol {
    var explorerType: ExplorerTypeEntity
    var nodes: [MEGANode]?
    var selectedNodes: [MEGANode]?
    unowned var tableView: UITableView
    weak var delegate: FilesExplorerListSourceDelegate?
    
    init(tableView: UITableView,
         nodes: [MEGANode]?,
         selectedNodes: [MEGANode]?,
         explorerType: ExplorerTypeEntity,
         delegate: FilesExplorerListSourceDelegate?) {
        self.tableView = tableView
        self.nodes = nodes
        self.selectedNodes = selectedNodes
        self.delegate = delegate
        self.explorerType = explorerType
        super.init()
        configureTableView(tableView)
    }
    
    private func configureTableView(_ tableView: UITableView?) {
        guard let tableView = tableView else { return }
        
        tableView.register(VideoExplorerTableViewCell.nib,
                           forCellReuseIdentifier: VideoExplorerTableViewCell.reuseIdentifier)
    }
    
    func reloadCell(withNode node: MEGANode) {
        tableView.visibleCells.forEach { cell in
            guard let videoExplorerCell = cell as? VideoExplorerTableViewCell,
                  videoExplorerCell.viewModel?.nodeHandle == node.handle else {
                return
            }
            
            videoExplorerCell.viewModel = viewModel(forNode: node)
        }
    }
    
    func updateCells(forNodes nodes: [MEGANode]) {
        nodes.forEach(reloadCell(withNode:))
    }
    
    fileprivate func viewModel(forNode node: MEGANode) -> VideoExplorerTableCellViewModel {
        VideoExplorerTableCellViewModel(node: node) { [weak self] node, cell in
            guard let self = self else { return }
            
            self.delegate?.showMoreOptions(forNode: node, sender: cell)
        }
    }
}

extension VideoExplorerListSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoExplorerTableViewCell.reuseIdentifier, for: indexPath) as? VideoExplorerTableViewCell,
              let node = nodes?[indexPath.row] else {
            return UITableViewCell()
        }
        
        cell.viewModel = viewModel(forNode: node)
        
        if tableView.isEditing, selectedNodes?.contains(node) == true {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        
        cell.setSelectedBackgroundView(withColor: .clear)
        
        return cell
    }
}

extension VideoExplorerListSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        toggleSelection(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        toggleSelection(at: indexPath)
    }
}
