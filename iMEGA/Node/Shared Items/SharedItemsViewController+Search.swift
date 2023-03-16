import MEGADomain

extension SharedItemsViewController: UISearchBarDelegate {
    
    @objc func loadDefaultSharedItems() {
        if incomingButton?.isSelected ?? false {
            searchUnverifiedNodes(key: "")
            searchNodesArray = incomingNodesMutableArray
        } else if outgoingButton?.isSelected ?? false {
            searchUnverifiedNodes(key: "")
            searchNodesArray = outgoingNodesMutableArray
        } else if linksButton?.isSelected ?? false {
            searchUnverifiedNodesArray.removeAllObjects()
            if publicLinksArray.isNotEmpty, let publicLinksArray = (publicLinksArray as NSArray).mutableCopy() as? NSMutableArray {
                searchNodesArray = publicLinksArray
            }
        }
        tableView?.reloadData()
    }
    
    @objc func evaluateSearchResult(nodeArray: [MEGANode]?, error: Error?) {
        DispatchQueue.main.async {
            if let error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            } else if let nodeArray {
                if let mutableNodeArray = (nodeArray as NSArray).mutableCopy() as? NSMutableArray {
                    self.searchNodesArray = mutableNodeArray
                }
            } else {
                self.searchNodesArray.removeAllObjects()
            }
            self.tableView?.reloadData()
        }
    }
    
    //MARK: - UISearchBarDelegate
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchNodesArray.removeAllObjects()
        searchUnverifiedNodesArray.removeAllObjects()
        searchUnverifiedSharesArray.removeAllObjects()
        
        searchNodeUseCaseOCWrapper?.cancelSearch()
        searchNodeUseCaseOCWrapper = nil
        
        loadDefaultSharedItems()
        
        if !MEGAReachabilityManager.isReachable() {
            self.tableView?.tableHeaderView = nil
        } else {
            configSearch()
        }
    }
}
