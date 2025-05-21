import MEGAAssets

final class FavouriteExplorerToolbarConfigurator: ExplorerToolbarConfigurator {
    let favouriteAction: ButtonAction
    
    lazy var favouriteItem = UIBarButtonItem(
        image: MEGAAssets.UIImage.removeFavourite,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    init(
        downloadAction: @escaping ButtonAction,
        shareLinkAction: @escaping ButtonAction,
        moveAction: @escaping ButtonAction,
        copyAction: @escaping ButtonAction,
        deleteAction: @escaping ButtonAction,
        moreAction: @escaping ButtonAction,
        favouriteAction: @escaping ButtonAction
    ) {
        self.favouriteAction = favouriteAction
        
        super.init(downloadAction: downloadAction,
                   shareLinkAction: shareLinkAction,
                   moveAction: moveAction,
                   copyAction: copyAction,
                   deleteAction: deleteAction,
                   moreAction: moreAction)
    }
    
    override func buttonPressed(_ barButtonItem: UIBarButtonItem) {
        switch barButtonItem {
        case favouriteItem:
            favouriteAction(barButtonItem)
        default:
            super.buttonPressed(barButtonItem)
        }
    }
    
    override func toolbarItems(forNodes nodes: [MEGANode]?) -> [UIBarButtonItem] {
        let barButtonItems = [
            downloadItem,
            flexibleItem,
            favouriteItem,
            flexibleItem,
            shareLinkItem,
            flexibleItem,
            deleteItem,
            flexibleItem,
            moreItem
        ]
        
        let hasDisputedNodes = (nodes ?? []).filter { $0.isTakenDown() }.count > 0
        let hasSelectedNodes = nodes?.isNotEmpty == true
        
        let adjustedBarButtonItems = enable(
            hasSelectedNodes,
            hasDisputedNodes: hasDisputedNodes,
            barButtonItems: barButtonItems
        )
        
        favouriteItem.isEnabled = !hasDisputedNodes && hasSelectedNodes
        
        return adjustedBarButtonItems
    }
}
