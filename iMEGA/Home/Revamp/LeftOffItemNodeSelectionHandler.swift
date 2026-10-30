import MEGAAppPresentation

/// Dedicated handler for a file tapped in "Continue where you left off".
/// Needed for handling audio nodes where `sourcePage` is `.continueWhereYouLeftOff`
struct LeftOffItemNodeSelectionHandler: NodeSelectionHandling {
    private let nodeRouter: any NodeRouting

    init(nodeRouter: some NodeRouting) {
        self.nodeRouter = nodeRouter
    }

    func handle(selection: NodeSelection) {
        nodeRouter.didTapNode(
            nodeHandle: selection.handle,
            allNodeHandles: nil,
            displayMode: .cloudDrive,
            sourcePage: .continueWhereYouLeftOff,
            isFromSharedItem: false,
            warningViewModel: nil
        )
    }
}
