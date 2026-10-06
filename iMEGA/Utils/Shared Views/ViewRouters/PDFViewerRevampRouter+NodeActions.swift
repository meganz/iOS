import MEGAPDFViewer

extension PDFViewerRevampRouter {
    @MainActor
    static func presentNodeActions(
        for node: MEGANode,
        from presenter: UIViewController,
        isLink: Bool,
        isFromSharedItem: Bool
    ) {
        // Match checks in `-[PreviewDocumentViewController actionsTapped:]`.
        let latestNode = MEGASdk.shared.node(forHandle: node.handle) ?? node
        let displayMode: DisplayMode = latestNode.mnz_isInRubbishBin() ? .rubbishBin : .previewPdfPage
        // To be replaced in upcoming MR
        let delegate = NodeActionViewControllerGenericDelegate(
            viewController: presenter,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: presenter)
        )
        let actionsViewController = NodeActionViewController(
            node: latestNode,
            delegate: delegate,
            isLink: isLink,
            displayMode: displayMode,
            isBackupNode: BackupsOCWrapper().isBackupNode(latestNode),
            isFromSharedItem: isFromSharedItem,
            isPDFViewerRevampEnabled: true,
            // Next commit will update to a non-nil sender,
            // to handle iPad popover
            sender: Optional<Any>.none as Any
        )
        presenter.present(actionsViewController, animated: true)
    }
}
