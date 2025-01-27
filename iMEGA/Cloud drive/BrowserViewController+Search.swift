extension BrowserViewController {
    
    private static var searchTask: Task<Void, any Error>?
    
    @objc func updateSearchResults(searchString: String) {
        if searchController.isActive {
            if searchString.count > 0 {
                viewModel.searchDebouncer.start { [weak self] in
                    self?.search(by: searchString)
                }
            } else {
                cancelSearchTask()
                SVProgressHUD.dismiss()
                guard let nodes else { return }
                searchNodesArray?.removeAllObjects()
                searchNodesArray = NSMutableArray(array: nodes.toNodeArray())
                tableView?.reloadData()
            }
        } else {
            cancelSearchTask()
            SVProgressHUD.dismiss()
            tableView?.reloadData()
        }
    }
    
    private func search(by searchText: String) {
        cancelSearchTask()
        BrowserViewController.searchTask = Task {
            SVProgressHUD.show()
            if isIncomingRoot {
                if nodeSearcher == nil {
                    nodeSearcher = SharedItemsNodeSearcher()
                }
                guard let nodeSearcher else { return }
                let nodes = try await nodeSearcher.searchOnInShares(text: searchText, sortType: .defaultAsc)
                guard let nodes else { return }
                searchNodesArray?.removeAllObjects()
                searchNodesArray = NSMutableArray(array: nodes)
            } else {
                let nodes = try await viewModel.search(by: searchText)
                searchNodesArray?.removeAllObjects()
                searchNodesArray = NSMutableArray(array: nodes.toMEGANodes(in: MEGASdk.shared))
            }
            tableView?.reloadData()
            await SVProgressHUD.dismiss()
        }
    }
    
    private var isIncomingRoot: Bool {
        incomingButton?.isSelected ?? false && isParentBrowser
    }
    
    private func cancelSearchTask() {
        BrowserViewController.searchTask?.cancel()
    }
}
