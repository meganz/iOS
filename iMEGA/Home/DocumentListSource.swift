
final class DocAndAudioListSource: NSObject, FilesExplorerListSourceProtocol {
    
    // MARK:- Private variables.

    var nodes: [MEGANode]?
    weak var tableView: UITableView?
    weak var delegate: FilesExplorerListSourceDelegate?
    
    // MARK:- Initializers.

    init(tableView: UITableView?, nodes: [MEGANode]?, delegate: FilesExplorerListSourceDelegate?) {
        self.tableView = tableView
        self.nodes = nodes
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

    func updateProgress(_ progress: Float, forNode node: MEGANode, infoString: String) {
        if let nodeCell = cell(forNode: node) as? NodeTableViewCell {
            nodeCell.infoLabel.text = infoString
            nodeCell.downloadProgressView.progress = progress
        }
    }
    
    // MARK:- Private methods.
    
    private func configureTableView(_ tableView: UITableView?) {
        guard let tableView = tableView else { return }
        
        tableView.rowHeight = 60
        tableView.register(UINib(nibName: "NodeTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "nodeCell")
        tableView.register(UINib(nibName: "DownloadingNodeCell", bundle: nil),
                           forCellReuseIdentifier: "downloadingNodeCell")
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
        if let handle = node.base64Handle, Helper.downloadingNodes()[handle] != nil {
            cell = tableView.dequeueReusableCell(withIdentifier: "downloadingNodeCell", for: indexPath) as? NodeTableViewCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "nodeCell", for: indexPath) as? NodeTableViewCell
        }
        
        if let moreButton = cell?.moreButton {
            moreButton.removeTarget(nil, action: nil, for: .allEvents)
            moreButton.tag = indexPath.row
            moreButton.addTarget(self, action: #selector(moreButtonTapped(sender:)), for: .touchUpInside)
        }
                
        cell?.cellFlavor = .cloudDrive
        cell?.configureCell(for: node, delegate: nil, api: MEGASdkManager.sharedMEGASdk())
        
        return cell ?? UITableViewCell()
    }
}

// MARK:- UITableViewDelegate

extension DocAndAudioListSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let nodes = nodes else { return }
        
        delegate?.didSelect(node: nodes[indexPath.row])
    }
}
