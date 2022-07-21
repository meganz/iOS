
final class AlbumToolbarConfigurator: ExplorerToolbarConfigurator {
    enum AlbumType {
        case favourite
        case normal
    }
    
    let favouriteAction: ButtonAction
    let removeToRubbishBinAction: ButtonAction
    let albumType: AlbumType
    
    private var favouriteItemImage: ImageAsset {
        albumType == .favourite ? Asset.Images.NodeActions.removeFavourite :
        Asset.Images.NodeActions.favourite
    }
    
    lazy var favouriteItem = UIBarButtonItem(
        image: favouriteItemImage.image,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var removeToRubbishBinItem = UIBarButtonItem(
        image: Asset.Images.NodeActions.rubbishBin.image,
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
        favouriteAction: @escaping ButtonAction,
        removeToRubbishBinAction: @escaping ButtonAction,
        moreAction: @escaping ButtonAction,
        albumType: AlbumType
    ) {
        self.favouriteAction = favouriteAction
        self.removeToRubbishBinAction = removeToRubbishBinAction
        self.albumType = albumType
        
        super.init(
            downloadAction: downloadAction,
            shareLinkAction: shareLinkAction,
            moveAction: moveAction,
            copyAction: copyAction,
            deleteAction: deleteAction,
            moreAction: moreAction
        )
    }
    
    override func buttonPressed(_ barButtonItem: UIBarButtonItem) {
        switch barButtonItem {
        case downloadItem:
            super.downloadAction(barButtonItem)
        case shareLinkItem:
            super.shareLinkAction(barButtonItem)
        case favouriteItem:
            favouriteAction(barButtonItem)
        case removeToRubbishBinItem:
            removeToRubbishBinAction(barButtonItem)
        case moreItem:
            super.moreAction(barButtonItem)
        default:
            break
        }
    }
    
    override func toolbarItems(forNodes nodes: [MEGANode]?) -> [UIBarButtonItem] {
        let barButtonItems = [
            downloadItem,
            flexibleItem,
            shareLinkItem,
            flexibleItem,
            favouriteItem,
            flexibleItem,
            removeToRubbishBinItem,
            flexibleItem,
            moreItem
        ]

        return enable(nodes?.isNotEmpty == true, barButtonItems: barButtonItems)
    }
}
