import MEGAL10n

extension SharedItemsViewController: DZNEmptyDataSetSource {
    public func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        let emptyStateView = EmptyStateView(image: imageForEmptyState(), title: titleForEmptyState(), description: descriptionForEmptyState(), buttonTitle: buttonTitleForEmptyState())
        
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
                    return UIImage.searchEmptyState
                } else {
                    return nil
                }
            } else {
                if incomingButton?.isSelected ?? false {
                    return UIImage.incomingEmptyState
                } else if outgoingButton?.isSelected ?? false {
                    return UIImage.outgoingEmptyState
                } else if linksButton?.isSelected ?? false {
                    return UIImage.linksEmptyState
                }
            }
        } else {
            return UIImage.noInternetEmptyState
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
