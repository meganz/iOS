import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

struct RecentActionBucketNodesActionHandler: NodesActionHandling {
    private let nodeRouter: any NodeRouting
    private let nodesActionHandler: NodeActionsDelegateHandler
    private let nodeRepository: any NodeRepositoryProtocol
    private let tracker: any AnalyticsTracking
    
    init(
        nodeRouter: some NodeRouting,
        nodesActionHandler: NodeActionsDelegateHandler,
        nodeRepository: some NodeRepositoryProtocol = NodeRepository.newRepo,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.nodeRouter = nodeRouter
        self.nodesActionHandler = nodesActionHandler
        self.nodeRepository = nodeRepository
        self.tracker = tracker
    }
    
    func handle(action: MEGAAppPresentation.NodeAction) {
        tracker.trackAnalyticsEvent(with: RecentsChildNodeMoreButtonPressedEvent())
        nodeRouter.didTapMoreAction(on: action.handle, button: action.sender, displayMode: .recents, isFromSharedItem: false)
    }
    
    func handle(action: MEGAAppPresentation.NodesAction) {
        switch action {
        case let .download(handles):
            nodesActionHandler.download(nodes(from: handles))
        case let .shareLink(handles):
            nodesActionHandler.shareOrManageLink(nodes(from: handles))
        case let .copy(handles):
            nodesActionHandler.browserAction(.copy, nodes(from: handles))
        case let .move(handles):
            nodesActionHandler.browserAction(.move, nodes(from: handles))
        case let .moveToRubbishBin(handles):
            nodesActionHandler.moveToRubbishBin(nodes(from: handles))
        default:
            break
        }
    }
    
    private func nodes(from handles: Set<HandleEntity>) -> [NodeEntity] {
        handles.compactMap(nodeRepository.nodeForHandle)
    }
}
