
final class FavouriteExplorerToolbarConfigurator: ExplorerToolbarConfigurator {
    let favouriteAction: ButtonAction
    
    lazy var favouriteItem = UIBarButtonItem(
        image: Asset.Images.NodeActions.removeFavourite.image,
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
        case downloadItem:
            super.downloadAction(barButtonItem)
        case favouriteItem:
            favouriteAction(barButtonItem)
        case shareLinkItem:
            super.shareLinkAction(barButtonItem)
        case deleteItem:
            super.deleteAction(barButtonItem)
        default:
            break
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
            deleteItem
        ]
        
        return enable(nodes?.isNotEmpty == true, barButtonItems: barButtonItems)
    }
}
