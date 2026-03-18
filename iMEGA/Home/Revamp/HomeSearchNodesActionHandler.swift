import MEGAAppPresentation

struct HomeSearchNodesActionHandler: NodesActionHandling {
    private let nodeRouter: any NodeRouting
    
    init(nodeRouter: some NodeRouting) {
        self.nodeRouter = nodeRouter
    }
    
    func handle(action: MEGAAppPresentation.NodeAction) {
        nodeRouter.didTapMoreAction(on: action.handle, button: action.sender, displayMode: .cloudDrive, isFromSharedItem: false)
    }
    
    /// Multiple nodes selection is not handled here as of current implementation.
    /// It is handled in SearchBridge's context closure constructed in CloudDriveViewControllerFactory.
    /// Reason: The root home search is HomeSearchResultsView which use Search module. In Root home search, edit mode is not supported.
    /// Once enter a children folder, a NewCloudDriveViewController is pushed (Check HomeSearchResultsRouter)
    func handle(action: MEGAAppPresentation.NodesAction) {}
}
