import MEGAAppPresentation
import MEGADesignToken
import MEGADomain

final class AlbumToolbarConfigurator: ExplorerToolbarConfigurator {
    private let favouriteAction: ButtonAction
    private let removeToRubbishBinAction: ButtonAction
    private let exportAction: ButtonAction
    private let sendToChatAction: ButtonAction
    private let albumType: AlbumType
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    
    private var favouriteItemImage: UIImage {
        albumType == .favourite ? UIImage.removeFavourite : UIImage.favourite
    }
    
    var isHiddenNodesEnabled: Bool {
        remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes)
    }
    
    lazy var favouriteItem = UIBarButtonItem(
        image: favouriteItemImage,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var sendToChatItem = UIBarButtonItem(
        image: UIImage.sendToChat,
        style: .plain,
        target: self,
        action: #selector(buttonPressed(_:))
    )
    
    lazy var removeToRubbishBinItem = UIBarButtonItem(
        image: UIImage.rubbishBin,
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
        exportAction: @escaping ButtonAction,
        sendToChatAction: @escaping ButtonAction,
        moreAction: @escaping ButtonAction,
        albumType: AlbumType,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase
    ) {
        self.favouriteAction = favouriteAction
        self.removeToRubbishBinAction = removeToRubbishBinAction
        self.exportAction = exportAction
        self.sendToChatAction = sendToChatAction
        self.albumType = albumType
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
        
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
        case exportItem:
            exportAction(barButtonItem)
        case sendToChatItem:
            sendToChatAction(barButtonItem)
        case moreItem:
            super.moreAction(barButtonItem)
        default:
            super.buttonPressed(barButtonItem)
        }
    }
    
    override func toolbarItems(forNodes nodes: [MEGANode]?) -> [UIBarButtonItem] {
        var barButtonItems = [
            downloadItem,
            flexibleItem,
            shareLinkItem,
            flexibleItem,
            exportItem,
            flexibleItem,
            sendToChatItem
        ]
        barButtonItems.append(contentsOf: additionalBarButtonItems(for: albumType))
        
        for barButtonItem in barButtonItems {
            barButtonItem.tintColor = TokenColors.Icon.primary
        }
        
        return enable(
            nodes?.isNotEmpty == true,
            hasDisputedNodes: nodes?.contains(where: { $0.isTakenDown() }) == true,
            barButtonItems: barButtonItems)
    }
    
    private func additionalBarButtonItems(for albumType: AlbumType) -> [UIBarButtonItem] {
        switch albumType {
        case .favourite:
            return [
                flexibleItem,
                isHiddenNodesEnabled ?  moreItem : favouriteItem
            ]
        case .gif, .raw:
            guard isHiddenNodesEnabled else { return [] }
            
            return [
                flexibleItem,
                moreItem
            ]
        case .user:
            return [
                flexibleItem,
                isHiddenNodesEnabled ? moreItem : removeToRubbishBinItem
            ]
        }
    }
}
