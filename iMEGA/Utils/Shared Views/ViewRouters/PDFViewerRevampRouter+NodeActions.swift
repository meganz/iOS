import MEGAPDFViewer

extension PDFViewerRevampRouter {
    @MainActor
    static func presentNodeActions(
        for node: MEGANode?,
        from presenter: UIViewController?,
        anchor: UIView?,
        barItem: UIBarButtonItem?,
        context: DocumentPreviewContext,
        linkActions: some DocumentPreviewLinkActionRouting = DocumentPreviewLinkActionRouter(),
        trackingUseCase: some PDFViewerTrackingUseCaseProtocol = PDFViewerTrackingUseCase(),
        analyticsSource: PDFViewerAnalyticsSource,
        onPresented: PDFViewerTrailingPopoverDependencies.OnPresentationCompletion?
    ) {
        // UIKit skips the presentation, and so never calls `onPresented`,
        // while `presenter` is already presenting.
        guard let node, let presenter, presenter.presentedViewController == nil else {
            onPresented?()
            return
        }

        let actionsViewController = DocumentPreviewNodeActionDelegate.makeNodeActionViewController(
            for: node,
            presenter: presenter,
            context: context,
            linkActions: linkActions,
            trackingUseCase: trackingUseCase,
            analyticsSource: analyticsSource,
            sender: nodeActionsSender(anchor: anchor, barItem: barItem)
        )
        presenter.present(actionsViewController, animated: true) {
            trackingUseCase.track(.moreMenuOpened)
            onPresented?()
        }
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
    /// - If above conditions not satisfied, use the normal sheet presentation.
    @MainActor
    static func nodeActionsSender(
        anchor: UIView?,
        barItem: UIBarButtonItem?
    ) -> Any? {
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
        return nil
    }
}
