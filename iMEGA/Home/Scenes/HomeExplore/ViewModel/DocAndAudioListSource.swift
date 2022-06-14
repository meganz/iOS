
final class DocAndAudioListSource: NSObject, FilesExplorerListSourceProtocol {
    
    // MARK:- Private variables.

    var nodes: [MEGANode]?
    var selectedNodes: [MEGANode]?
    var tableView: UITableView
    weak var delegate: FilesExplorerListSourceDelegate?
    
    // MARK:- Initializers.

    init(tableView: UITableView,
         nodes: [MEGANode]?,
         selectedNodes: [MEGANode]?,
         delegate: FilesExplorerListSourceDelegate?) {
        self.tableView = tableView
        self.nodes = nodes
        self.selectedNodes = selectedNodes
        self.delegate = delegate
        super.init()
        configureTableView(tableView)
    }

    // MARK:- Actions
    
    @objc func moreButtonTapped(sender: UIButton) {
        guard let node = nodes?[sender.tag] else { return  }
        
        delegate?.showMoreOptions(forNode: node, sender: sender)
    }
    
    // MARK:- Interface methods.
    
    func onTransferCompleted(forNode node: MEGANode) {
        reloadCell(withNode: node, afterDelay: 0)
    }
    
    // MARK:- Private methods.
    
    private func configureTableView(_ tableView: UITableView) {        
        tableView.rowHeight = 60
        tableView.register(UINib(nibName: "NodeTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "nodeCell")
    }
    
    private func reloadCell(withNode node: MEGANode, afterDelay delay: Int) {
        let deadline: DispatchTime = DispatchTime.now() + DispatchTimeInterval.seconds(delay)
        DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
            self?.reloadCell(withNode: node)
        }
    }
}

// MARK:- UITableViewDataSource

extension DocAndAudioListSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let node = nodes?[indexPath.row] else { return UITableViewCell() }
        
        var cell: NodeTableViewCell?
        cell = tableView.dequeueReusableCell(withIdentifier: "nodeCell", for: indexPath) as? NodeTableViewCell
        
        if let moreButton = cell?.moreButton {
            moreButton.removeTarget(nil, action: nil, for: .allEvents)
            moreButton.tag = indexPath.row
            moreButton.addTarget(self, action: #selector(moreButtonTapped(sender:)), for: .touchUpInside)
        }
                
        cell?.cellFlavor = .explorerView
        cell?.configureCell(for: node, api: MEGASdkManager.sharedMEGASdk())
        cell?.setSelectedBackgroundView(withColor: .clear)
        
        if tableView.isEditing,
           let selectedNodes = selectedNodes,
           !selectedNodes.isEmpty,
           selectedNodes.contains(node) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        
        return cell ?? UITableViewCell()
    }
}

// MARK:- UITableViewDelegate

extension DocAndAudioListSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        deselect(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        delegate?.shouldBeginMultipleSelectionInteraction()
        return true
    }
    
    func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        delegate?.didBeginMultipleSelectionInteraction()
    }
    
    func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
        delegate?.didEndMultipleSelectionInteraction()
    }
}

// MARK:- Swipe gesture UITableViewDelegate

extension DocAndAudioListSource {
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        guard let nodeCell = tableView.cellForRow(at: indexPath) as? NodeTableViewCell,
              let node = nodeCell.node else {
            return nil
        }

        if !isNodeInRubbishBin(node){
            let shareLinkAction = contextualAction(
                withImageName: Asset.Images.Generic.link.name,
                backgroundColor: .systemOrange
            ) { [weak self] in
                self?.shareLink(node: nodeCell.node)
            }
            let rubbishBinAction = contextualAction(
                withImageName: Asset.Images.NodeActions.rubbishBin.name,
                backgroundColor: .mnz_redError()
            ) { [weak self] in
                self?.moveToRubbishBin(node: nodeCell.node)
            }
            let downloadAction = contextualAction(withImageName: Asset.Images.NodeActions.offline.name, backgroundColor: .mnz_turquoise(for: tableView.traitCollection)) { [weak self] in
                self?.download(node: node)
            }

            let actions = [rubbishBinAction, shareLinkAction, downloadAction]
            
            return UISwipeActionsConfiguration(actions: actions)
        }

        return nil
    }

    // MARK:- Private methods
    
    private func indexPath(forNode node: MEGANode) -> IndexPath? {
        guard let index = nodes?.firstIndex(of: node) else {
            MEGALogDebug("Could not find the node with name \(node.name ?? "no node name") as the index is nil")
            return nil
        }

        return IndexPath(row: index, section: 0)
    }

    private func shareLink(node: MEGANode) {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            CopyrightWarningViewController.presentGetLinkViewController(for: [node], in: UIApplication.mnz_presentingViewController())
        }
        
        tableView.setEditing(false, animated: true)
    }

    private func moveToRubbishBin(node: MEGANode) {
        node.mnz_moveToTheRubbishBin { [weak self] in
            self?.tableView.setEditing(false, animated: true)
        }
    }

    private func restore(node: MEGANode) {
        node.mnz_restore()
        tableView.setEditing(false, animated: true)
    }

    private func download(node: MEGANode) {
        delegate?.download(node: node)
        tableView.setEditing(false, animated: true)
    }

    private func contextualAction(withImageName imageName: String, backgroundColor: UIColor, completion: @escaping () -> Void) -> UIContextualAction {
        let action = UIContextualAction(style: .normal,
                                        title: nil)
        { (action, sourceView, callback) in
            completion()
        }

        action.image = UIImage(named: imageName)
        action.image = action.image?.withTintColor(.white)

        action.backgroundColor = backgroundColor
        return action
    }
    
    private func isOwner(ofNode node: MEGANode) -> Bool {
        return MEGASdkManager.sharedMEGASdk().accessLevel(for: node) == .accessOwner
    }

    private func isNodeInRubbishBin(_ node: MEGANode) -> Bool {
        return MEGASdkManager.sharedMEGASdk().isNode(inRubbish: node)
    }

    private func restorationNode(forNode node: MEGANode) -> MEGANode? {
        return MEGASdkManager.sharedMEGASdk().node(forHandle: node.restoreHandle)
    }
}
