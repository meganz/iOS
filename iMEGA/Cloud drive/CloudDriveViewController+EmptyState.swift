import MEGAL10n

extension CloudDriveViewController: DZNEmptyDataSetSource {
    public func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        let emptyStateView = EmptyStateView(image: imageForEmptyState(), title: titleForEmptyState(), description: descriptionForEmptyState(), buttonTitle: buttonTitleForEmptyState())
        
        guard let menuConfig = uploadAddMenuConfiguration() else { return emptyStateView }
        
        emptyStateView.button?.menu = contextMenuManager?.contextMenu(with: menuConfig)
        emptyStateView.button?.showsMenuAsPrimaryAction = true
        
        return emptyStateView
    }
    
    func titleForEmptyState() -> String? {
        if MEGAReachabilityManager.isReachable() {
            guard let parentNode = parentNode else {
                return nil
            }
            
            if searchController?.isActive ?? false {
                return Strings.Localizable.noResults
            } else {
                switch displayMode {
                case .cloudDrive:
                    return parentNode.type == .root ?
                                                Strings.Localizable.cloudDriveEmptyStateTitle :
                                                Strings.Localizable.emptyFolder
                case .rubbishBin:
                    return parentNode.type == .rubbish ?
                                                Strings.Localizable.cloudDriveEmptyStateTitleRubbishBin :
                                                Strings.Localizable.emptyFolder
                default:
                    return nil
                }
            }
        } else {
            return Strings.Localizable.noInternetConnection
        }
    }
    
    func descriptionForEmptyState() -> String? {
        if !MEGAReachabilityManager.isReachable() && !MEGAReachabilityManager.shared().isMobileDataEnabled {
            return Strings.Localizable.mobileDataIsTurnedOff
        }
        
        return nil
    }
    
    func imageForEmptyState() -> UIImage? {
        if MEGAReachabilityManager.isReachable() {
            guard let parentNode = parentNode else {
                return nil
            }
            
            if searchController?.isActive ?? false {
                return UIImage.searchEmptyState
            } else {
                switch displayMode {
                case .cloudDrive:
                    return parentNode.type == .root ? UIImage.cloudEmptyState :UIImage.folderEmptyState
                case .rubbishBin:
                    return parentNode.type == .root ? UIImage.rubbishEmptyState : UIImage.folderEmptyState
                default:
                    return nil
                }
            }
        } else {
            return UIImage.noInternetEmptyState
        }
    }
    
    func buttonTitleForEmptyState() -> String? {
        guard let parentNode = parentNode else {
            return nil
        }
        
        let parentShareType = MEGASdk.shared.accessLevel(for: parentNode)
        
        if parentShareType == .accessRead {
            return nil
        }
        
        if MEGAReachabilityManager.isReachable() {
            switch displayMode {
            case .cloudDrive:
                if !(searchController?.isActive ?? false) {
                    return Strings.Localizable.addFiles
                }
            default:
                return nil
            }
        } else {
            if !MEGAReachabilityManager.shared().isMobileDataEnabled {
                return Strings.Localizable.turnMobileDataOn
            }
        }
        
        return nil
    }
}
