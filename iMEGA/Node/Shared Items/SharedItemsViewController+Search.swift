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
    
    func evaluateSearchResult(searchText: String, sortType: MEGASortOrderType, asyncSearchClosure: @escaping (String, MEGASortOrderType) async throws -> [MEGANode]?) async {
        do {
            SVProgressHUD.show()
            if let nodes = try await asyncSearchClosure(searchText, sortType) {
                if let mutableNodeArray = (nodes as NSArray).mutableCopy() as? NSMutableArray {
                    searchNodesArray = mutableNodeArray
                }
            }  else {
                searchNodesArray.removeAllObjects()
            }
            await SVProgressHUD.dismiss()
        } catch {
            SVProgressHUD.showError(withStatus: error.localizedDescription)
        }
        self.tableView?.reloadData()
    }

    @objc func search(by searchText: String) {
        guard let searchNodeUseCaseOCWrapper else { return }
        Task { @MainActor in
            if incomingButton?.isSelected ?? false {
                searchUnverifiedNodes(key: searchText)
                await evaluateSearchResult(searchText: searchText, sortType: sortOrderType, asyncSearchClosure: searchNodeUseCaseOCWrapper.searchOnInShares)
            } else if outgoingButton?.isSelected ?? false {
                searchUnverifiedNodes(key: searchText)
                await evaluateSearchResult(searchText: searchText, sortType: sortOrderType, asyncSearchClosure: searchNodeUseCaseOCWrapper.searchOnOutShares)
            } else if linksButton?.isSelected ?? false {
                searchUnverifiedNodesArray.removeAllObjects()
                await evaluateSearchResult(searchText: searchText, sortType: sortOrderType, asyncSearchClosure: searchNodeUseCaseOCWrapper.searchOnPublicLinks)
            }
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
