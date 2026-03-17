import MEGAAppPresentation

struct RecentActionBucketNodesActionHandler: NodesActionHandling {
    private let nodeRouter: any NodeRouting
    
    init(nodeRouter: some NodeRouting) {
        self.nodeRouter = nodeRouter
    }
    
    func handle(action: MEGAAppPresentation.NodeAction) {
        nodeRouter.didTapMoreAction(on: action.handle, button: action.sender, displayMode: .recents, isFromSharedItem: false)
    }
    
    /// To be handle separately with bottom bar action
    func handle(action: MEGAAppPresentation.NodesAction) {}
}
