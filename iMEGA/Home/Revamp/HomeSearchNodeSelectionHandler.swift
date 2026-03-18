import MEGAAppPresentation

struct HomeSearchNodeSelectionHandler: NodeSelectionHandling {
    private let nodeRouter: any NodeRouting
    
    init(nodeRouter: some NodeRouting) {
        self.nodeRouter = nodeRouter
    }
    
    func handle(selection: NodeSelection) {
        nodeRouter.didTapNode(
            nodeHandle: selection.handle,
            allNodeHandles: selection.siblings.isEmpty ? nil : selection.siblings,
            displayMode: .cloudDrive,
            isFromSharedItem: false,
            warningViewModel: nil
        )
    }
}

