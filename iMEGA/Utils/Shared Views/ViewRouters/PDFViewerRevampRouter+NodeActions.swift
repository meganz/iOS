import MEGAPDFViewer

extension PDFViewerRevampRouter {
    @MainActor
    static func presentNodeActions(
        for node: MEGANode,
        from presenter: UIViewController?,
        anchor: UIView?,
        barItem: UIBarButtonItem?,
        isLink: Bool,
        isFromSharedItem: Bool,
        onPresented: PDFViewerMoreMenuDependencies.OnMoreAnimationCompletion?
    ) {
        // UIKit skips the presentation, and so never calls `onPresented`,
        // while `presenter` is already presenting.
        guard let presenter, presenter.presentedViewController == nil else {
            onPresented?()
            return
        }

        // Match checks in `-[PreviewDocumentViewController actionsTapped:]`.
        let latestNode = MEGASdk.shared.node(forHandle: node.handle) ?? node
        let displayMode: DisplayMode = latestNode.mnz_isInRubbishBin() ? .rubbishBin : .previewPdfPage
        let sender = nodeActionsSender(from: presenter, anchor: anchor, barItem: barItem)

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
            sender: sender
        )
        presenter.present(actionsViewController, animated: true, completion: onPresented)
    }

    /// Use an "anchor" UI element to help position and animate the node actions
    /// popover on iPad.
    /// Generally, this anchor should be in the same position as the More navbar
    /// button that triggered the presentation of the node actions menu.
    ///
    /// iOS 26+ (Liquid Glass systems)
    /// - `barItem` is used if nonnil to produce a morph animation.
    /// - If not available, fall back to same behaviour as iOS 18 and below.
    ///
    /// iOS 18 and below
    /// - `anchor` is used if nonnil + attached to a window + has nonzero bounds
    /// - If above conditions not satisfied, fall back to `presenter.view`.
    @MainActor
    static func nodeActionsSender(
        from presenter: UIViewController,
        anchor: UIView?,
        barItem: UIBarButtonItem?
    ) -> Any {
        // On iPadOS 26, return the More `UIBarButtonItem` ->
        // `ActionSheetViewController.configurePresentationStyle` sets the
        // popover's `barButtonItem` -> the presentation animation morphs the
        // More button into the popover sheet.
        if #available(iOS 26.0, *), let barItem {
            return barItem
        }

        // Earlier systems use a `UIView` anchor -> shows popover, with an arrow
        // pointing to the anchor.
        if let anchor, anchor.window != nil, !anchor.bounds.isEmpty {
            return anchor
        }
        return presenter.view as Any
    }
}
