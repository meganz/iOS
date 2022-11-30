
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
                return Asset.Images.EmptyStates.searchEmptyState.image
            } else {
                switch displayMode {
                case .cloudDrive:
                    return parentNode.type == .root ?
                                                Asset.Images.EmptyStates.cloudEmptyState.image :
                                                Asset.Images.EmptyStates.folderEmptyState.image
                case .rubbishBin:
                    return parentNode.type == .root ?
                                                Asset.Images.EmptyStates.rubbishEmptyState.image :
                                                Asset.Images.EmptyStates.folderEmptyState.image
                default:
                    return nil
                }
            }
        } else {
            return Asset.Images.EmptyStates.noInternetEmptyState.image
        }
    }
    
    func buttonTitleForEmptyState() -> String? {
        guard let parentNode = parentNode else {
            return nil
        }
        
        let parentShareType = MEGASdkManager.sharedMEGASdk().accessLevel(for: parentNode)
        
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
