import MEGAAssets

class ExplorerToolbarConfigurator {
    typealias ButtonAction = (UIBarButtonItem) -> Void
    let downloadAction: ButtonAction
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
        image: MEGAAssets.UIImage.offline,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var shareLinkItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.link,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var moveItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.move,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var copyItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.copy,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var deleteItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.rubbishBin,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var exportItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.export,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var moreItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.moreNavigationBar,
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
        let hasDisputedNodes = nodes?.contains(where: { $0.isTakenDown() }) ?? false

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
            
            return enable(false, hasDisputedNodes: hasDisputedNodes, barButtonItems: barButtonItems)
        }
        
        switch lowestAccessLevel(forNodes: nodes) {
        case .accessRead, .accessReadWrite:
            return enable(
                true,
                hasDisputedNodes: hasDisputedNodes,
                barButtonItems: [downloadItem, flexibleItem, copyItem]
            )
        case .accessFull:
            return enable(
                true,
                hasDisputedNodes: hasDisputedNodes,
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
                hasDisputedNodes: hasDisputedNodes,
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
            let accessLevel = MEGASdk.shared.accessLevel(for: node)

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

    private func adjustToolbarItems(
        isToolbarEnabled: Bool,
        hasDisputedNodes: Bool
    ) {
        downloadItem.isEnabled = isToolbarEnabled && !hasDisputedNodes
        shareLinkItem.isEnabled = isToolbarEnabled && !hasDisputedNodes
        moveItem.isEnabled = isToolbarEnabled && !hasDisputedNodes
        copyItem.isEnabled = isToolbarEnabled && !hasDisputedNodes
        exportItem.isEnabled = isToolbarEnabled && !hasDisputedNodes
    }

    func enable(
        _ enable: Bool,
        hasDisputedNodes: Bool,
        barButtonItems: [UIBarButtonItem],
        excludeBarButtonItems: [UIBarButtonItem] = []
    ) -> [UIBarButtonItem] {
        barButtonItems.forEach {
            if !excludeBarButtonItems.contains($0) {
                $0.isEnabled = enable
            }
        }
        adjustToolbarItems(isToolbarEnabled: enable, hasDisputedNodes: hasDisputedNodes)
        return barButtonItems
    }
}
