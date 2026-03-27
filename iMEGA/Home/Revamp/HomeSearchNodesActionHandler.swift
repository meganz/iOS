import MEGAAppPresentation

struct HomeSearchNodesActionHandler: NodesActionHandling {
    private let nodeRouter: any NodeRouting
    
    init(nodeRouter: some NodeRouting) {
        self.nodeRouter = nodeRouter
    }
    
    func handle(action: MEGAAppPresentation.NodeAction) {
        nodeRouter.didTapMoreAction(on: action.handle, button: action.sender, displayMode: .homeSearch, isFromSharedItem: false)
    }
    
    /// Home Search doesn't support Edit mode.
    func handle(action: MEGAAppPresentation.NodesAction) {}
}
