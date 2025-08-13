import MEGADomain
import MEGAL10n

final class QuickActionsMenuDelegateHandler: QuickActionsMenuDelegate, RefreshMenuTriggering {
    
    private let showNodeInfo: (NodeEntity) -> Void
    private let manageShare: (NodeEntity) -> Void
    private let shareFolders: ([NodeEntity]) -> Void
    private let download: ([NodeEntity]) -> Void
    private let shareOrManageLink: ([NodeEntity]) -> Void
    private let copy: (NodeEntity) -> Void
    private let removeLink: ([NodeEntity]) -> Void
    private let removeSharing: (NodeEntity) -> Void
    private let rename: (NodeEntity) -> Void
    private let leaveSharing: (NodeEntity) -> Void
    private let hide: ([NodeEntity]) -> Void
    private let unhide: ([NodeEntity]) -> Void
    @Published private var nodeSource: NodeSource

    // this needs to be supplied from the outside to trigger the menu rebuild
    var refreshMenu: (() -> Void)?
    
    init(
        showNodeInfo: @escaping (NodeEntity) -> Void,
        manageShare: @escaping (NodeEntity) -> Void,
        shareFolders: @escaping ([NodeEntity]) -> Void,
        download: @escaping ([NodeEntity]) -> Void,
        shareOrManageLink: @escaping ([NodeEntity]) -> Void,
        copy: @escaping (NodeEntity) -> Void,
        removeLink: @escaping ([NodeEntity]) -> Void,
        removeSharing: @escaping (NodeEntity) -> Void,
        rename: @escaping (NodeEntity) -> Void,
        leaveSharing: @escaping (NodeEntity) -> Void,
        hide: @escaping ([NodeEntity]) -> Void,
        unhide: @escaping ([NodeEntity]) -> Void,
        nodeSource: NodeSource,
        nodeSourceUpdatesListener: some CloudDriveNodeSourceUpdatesListening
    ) {
        self.showNodeInfo = showNodeInfo
        self.manageShare = manageShare
        self.shareFolders = shareFolders
        self.shareOrManageLink = shareOrManageLink
        self.copy = copy
        self.removeLink = removeLink
        self.download = download
        self.removeSharing = removeSharing
        self.rename = rename
        self.leaveSharing = leaveSharing
        self.hide = hide
        self.unhide = unhide

        self.nodeSource = nodeSource
        nodeSourceUpdatesListener.nodeSourcePublisher
            .assign(to: &$nodeSource)
    }
    
    func quickActionsMenu(
        didSelect action: QuickActionEntity,
        needToRefreshMenu: Bool
    ) {
        guard
            case let .node(nodeProvider) = nodeSource,
            let parentNode = nodeProvider()
        else { return }
        
        switch action {
        case .info:
            showNodeInfo(parentNode)
        case .download:
            download([parentNode])
        case .shareLink, .manageLink:
            shareOrManageLink([parentNode])
        case .shareFolder:
            shareFolders([parentNode])
        case .rename:
            rename(parentNode)
        case .leaveSharing:
            leaveSharing(parentNode)
        case .copy:
            copy(parentNode)
        case .manageFolder:
            manageShare(parentNode)
        case .removeSharing:
            removeSharing(parentNode)
        case .removeLink:
            removeLink([parentNode])
        case .hide:
            hide([parentNode])
        case .unhide:
            unhide([parentNode])
        case.dispute:
            NSURL(string: Constants.Link.dispute)?.mnz_presentSafariViewController()
        default:
            break
        }
        
        if needToRefreshMenu {
            assert(refreshMenu != nil, "refreshMenu needs to be set before using")
            refreshMenu?()
        }
    }
}
