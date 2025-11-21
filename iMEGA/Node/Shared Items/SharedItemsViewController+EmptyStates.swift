import MEGAAssets
import MEGAL10n

extension SharedItemsViewController {
    private func hasContentToDisplay() -> Bool {
        guard MEGAReachabilityManager.isReachable() else {
            return false
        }

        if searchController.isActive {
            let hasSearchNodes = searchNodesArray.count > 0
            let hasSearchUnverifiedNodes = searchUnverifiedNodesArray.count > 0
            return hasSearchNodes || hasSearchUnverifiedNodes
        }

        if incomingButton?.isSelected == true {
            let incomingCount = incomingNodesMutableArray.count
            let unverifiedCount = incomingUnverifiedNodesMutableArray?.count ?? 0
            return incomingCount > 0 || unverifiedCount > 0
        }

        if outgoingButton?.isSelected == true {
            return outgoingNodesMutableArray.count > 0
        }

        if linksButton?.isSelected == true {
            return publicLinksArray.isNotEmpty
        }

        return false
    }
    
    @objc public func updateEmptyStateIfNeeded() {
        let hasData = hasContentToDisplay()

        tableView?.backgroundView = hasData ? nil : emptyStateView()
    }
    
    public func emptyStateView() -> UIView? {
        let emptyStateView = EmptyStateView(
            image: imageForEmptyState(),
            title: titleForEmptyState(),
            description: descriptionForEmptyState(),
            buttonTitle: buttonTitleForEmptyState()
        )
        
        emptyStateView.button?.addTarget(self, action: #selector(emptyStateButtonAction(sender:)), for: .touchUpInside)
        
        return emptyStateView
    }
    
    func titleForEmptyState() -> String? {
        if MEGAReachabilityManager.isReachable() {
            if searchController.isActive {
                if let text = searchController.searchBar.text, !text.isEmpty {
                    return Strings.Localizable.noResults
                }
            } else {
                if incomingButton?.isSelected ?? false {
                    return Strings.Localizable.noIncomingSharedItemsEmptyStateText
                } else if outgoingButton?.isSelected ?? false {
                    return Strings.Localizable.noOutgoingSharedItemsEmptyStateText
                } else if  linksButton?.isSelected ?? false {
                    return Strings.Localizable.noPublicLinks
                }
            }
        } else {
            return Strings.Localizable.noInternetConnection
        }
        return nil
    }
    
    func descriptionForEmptyState() -> String? {
        !MEGAReachabilityManager.isReachable() && !MEGAReachabilityManager.shared().isMobileDataEnabled ?
                                                                                                Strings.Localizable.mobileDataIsTurnedOff : nil
    }
    
    func imageForEmptyState() -> UIImage? {
        if MEGAReachabilityManager.isReachable() {
            if searchController.isActive {
                if let text = searchController.searchBar.text, !text.isEmpty {
                    return MEGAAssets.UIImage.searchEmptyState
                } else {
                    return nil
                }
            } else {
                if incomingButton?.isSelected ?? false {
                    return MEGAAssets.UIImage.glassShareIn
                } else if outgoingButton?.isSelected ?? false {
                    return MEGAAssets.UIImage.glassShareOut
                } else if linksButton?.isSelected ?? false {
                    return MEGAAssets.UIImage.glassLink
                }
            }
        } else {
            return MEGAAssets.UIImage.glassNoCloud
        }
        
        return nil
    }
    
    func buttonTitleForEmptyState() -> String? {
        !MEGAReachabilityManager.isReachable() && !MEGAReachabilityManager.shared().isMobileDataEnabled ?
                                                                                                Strings.Localizable.turnMobileDataOn : nil
    }
    
    @objc func emptyStateButtonAction(sender: Any) {
        if !MEGAReachabilityManager.isReachable(),
           !MEGAReachabilityManager.shared().isMobileDataEnabled,
           let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
