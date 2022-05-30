
class ExplorerToolbarConfigurator {
    typealias ButtonAction = (UIBarButtonItem) -> Void
    let downloadAction : ButtonAction
    let shareLinkAction: ButtonAction
    let moveAction: ButtonAction
    let copyAction: ButtonAction
    let deleteAction: ButtonAction
    let moreAction: ButtonAction
    
    lazy var flexibleItem = UIBarButtonItem(
        barButtonSystemItem: .flexibleSpace,
        target: nil,
        action: nil
    )
    
    lazy var downloadItem = UIBarButtonItem(
        image: Asset.Images.NodeActions.offline.image,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var shareLinkItem = UIBarButtonItem(
        image: Asset.Images.Generic.link.image,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var moveItem = UIBarButtonItem(
        image: Asset.Images.NodeActions.move.image,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var copyItem = UIBarButtonItem(
        image: Asset.Images.NodeActions.copy.image,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var deleteItem = UIBarButtonItem(
        image: Asset.Images.NodeActions.rubbishBin.image,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var moreItem = UIBarButtonItem(
        image: Asset.Images.NavigationBar.moreNavigationBar.image,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )

    init(downloadAction: @escaping ButtonAction,
         shareLinkAction: @escaping ButtonAction,
         moveAction: @escaping ButtonAction,
         copyAction: @escaping ButtonAction,
         deleteAction: @escaping ButtonAction,
         moreAction: @escaping ButtonAction) {
        self.downloadAction = downloadAction
        self.shareLinkAction = shareLinkAction
        self.moveAction = moveAction
        self.copyAction = copyAction
        self.deleteAction = deleteAction
        self.moreAction = moreAction
    }
    
    @objc func buttonPressed(_ barButtonItem: UIBarButtonItem) {
        switch barButtonItem {
        case downloadItem:
            downloadAction(barButtonItem)
        case shareLinkItem:
            shareLinkAction(barButtonItem)
        case moveItem:
            moveAction(barButtonItem)
        case copyItem:
            copyAction(barButtonItem)
        case deleteItem:
            deleteAction(barButtonItem)
        case moreItem:
            moreAction(barButtonItem)
        default:
            break
        }
    }
    
    func toolbarItems(forNodes nodes: [MEGANode]?) -> [UIBarButtonItem] {
        guard let nodes = nodes, !nodes.isEmpty else {
            let barButtonItems = [
                downloadItem,
                flexibleItem,
                shareLinkItem,
                flexibleItem,
                moveItem,
                flexibleItem,
                deleteItem,
                flexibleItem,
                moreItem
            ]
            
            return enable(false, barButtonItems: barButtonItems)
        }
        
                
        switch lowestAccessLevel(forNodes: nodes) {
        case .accessRead, .accessReadWrite:
            return enable(true, barButtonItems: [downloadItem, flexibleItem, copyItem])
        case .accessFull:
            return enable(
                true,
                barButtonItems: [
                    downloadItem,
                    flexibleItem,
                    copyItem,
                    flexibleItem,
                    deleteItem
                ]
            )
            
        case .accessOwner:
            return enable(
                true,
                barButtonItems: [
                    downloadItem,
                    flexibleItem,
                    shareLinkItem,
                    flexibleItem,
                    moveItem,
                    flexibleItem,
                    deleteItem,
                    flexibleItem,
                    moreItem
                ]
            )
        default:
            break
        }
        
        return []
    }
    
    private func lowestAccessLevel(forNodes nodes: [MEGANode]) -> MEGAShareType {
        var lowestAccessLevel: MEGAShareType = .accessOwner
        
        for node in nodes {
            let accessLevel = MEGASdkManager.sharedMEGASdk().accessLevel(for: node)

            if accessLevel == .accessRead || accessLevel == .accessReadWrite {
                lowestAccessLevel = accessLevel
                break
            }
            
            if lowestAccessLevel.rawValue > accessLevel.rawValue {
                lowestAccessLevel = accessLevel
            }
        }
        
        return lowestAccessLevel
    }
    
    func enable(_ enable: Bool,
                        barButtonItems: [UIBarButtonItem],
                        excludeBarButtonItems: [UIBarButtonItem] = []) -> [UIBarButtonItem] {
        barButtonItems.forEach {
            if !excludeBarButtonItems.contains($0){
                $0.isEnabled = enable
            }
        }
        return barButtonItems
    }
}
