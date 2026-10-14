import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

/// Gives a revamped document viewer the node actions that
/// `PreviewDocumentViewController` handles itself, and forwards the rest.
@MainActor
final class DocumentPreviewNodeActionDelegate: NodeActionViewControllerDelegate, NodeInfoViewControllerDelegate {
    private let context: DocumentPreviewContext
    private let linkActions: any DocumentPreviewLinkActionRouting
    private let makeNodeInfo: (@MainActor (MEGANode, any NodeInfoViewControllerDelegate) -> UIViewController)?
    private let wrapped: any NodeActionViewControllerDelegate
    private weak var presenter: UIViewController?
    private let tracker: any AnalyticsTracking
    private let navigateToParent: @MainActor (MEGANode) -> Void
    private let moveToRubbishBin: @MainActor (MEGANode, UIViewController) -> Void
    private let restore: @MainActor (MEGANode) -> Void

    init(
        wrapping wrapped: some NodeActionViewControllerDelegate,
        presenter: UIViewController,
        context: DocumentPreviewContext = DocumentPreviewContext(
            isLink: false, fileLink: nil, isFromSharedItem: false
        ),
        linkActions: some DocumentPreviewLinkActionRouting = DocumentPreviewLinkActionRouter(),
        makeNodeInfo: (@MainActor (MEGANode, any NodeInfoViewControllerDelegate) -> UIViewController)? = nil,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        navigateToParent: @escaping @MainActor (MEGANode) -> Void = defaultNavigateToParent,
        moveToRubbishBin: @escaping @MainActor (MEGANode, UIViewController) -> Void = defaultMoveToRubbishBin,
        restore: @escaping @MainActor (MEGANode) -> Void = defaultRestore
    ) {
        self.context = context
        self.linkActions = linkActions
        self.makeNodeInfo = makeNodeInfo
        self.wrapped = wrapped
        self.presenter = presenter
        self.tracker = tracker
        self.navigateToParent = navigateToParent
        self.moveToRubbishBin = moveToRubbishBin
        self.restore = restore
    }

    static func makeGenericDelegate(
        context: DocumentPreviewContext,
        presenter: UIViewController
    ) -> NodeActionViewControllerGenericDelegate {
        NodeActionViewControllerGenericDelegate(
            viewController: presenter,
            isNodeFromFolderLink: context.isFolderLink,
            messageId: context.messageId,
            chatId: context.chatId,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: presenter)
        )
    }

    static func makeNodeActionViewController(
        for node: MEGANode,
        presenter: UIViewController,
        context: DocumentPreviewContext,
        linkActions: some DocumentPreviewLinkActionRouting = DocumentPreviewLinkActionRouter(),
        sender: Any?
    ) -> NodeActionViewController {
        // Match checks in `-[PreviewDocumentViewController actionsTapped:]`.
        let latestNode = MEGASdk.shared.node(forHandle: node.handle) ?? node
        let displayMode: DisplayMode = latestNode.mnz_isInRubbishBin() ? .rubbishBin : .previewPdfPage
        let delegate = DocumentPreviewNodeActionDelegate(
            wrapping: makeGenericDelegate(context: context, presenter: presenter),
            presenter: presenter,
            context: context,
            linkActions: linkActions
        )
        return NodeActionViewController(
            node: latestNode,
            delegate: delegate,
            isLink: context.isLink,
            displayMode: displayMode,
            isInVersionsView: isPreviewingVersion(
                presentingViewController: presenter.navigationController?.presentingViewController
            ),
            isBackupNode: BackupsOCWrapper().isBackupNode(latestNode),
            isFromSharedItem: context.isFromSharedItem,
            isPDFViewerRevampEnabled: true,
            sender: sender as Any
        )
    }

    /// Matches `-[PreviewDocumentViewController isPreviewingVersion]`.
    static func isPreviewingVersion(presentingViewController: UIViewController?) -> Bool {
        guard let navigationController = presentingViewController as? MEGANavigationController else {
            return false
        }
        return navigationController.viewControllers.last is NodeVersionsViewController
    }

    static func defaultNavigateToParent(_ node: MEGANode) {
        node.navigateToParentAndPresent()
    }

    static func defaultMoveToRubbishBin(_ node: MEGANode, presenter: UIViewController) {
        node.mnz_askToMoveToTheRubbishBin(in: presenter)
    }

    static func defaultRestore(_ node: MEGANode) {
        node.mnz_restore()
    }

    func nodeAction(
        _ nodeAction: NodeActionViewController,
        didSelect action: MegaNodeActionType,
        for node: MEGANode,
        from sender: Any
    ) {
        switch action {
        case .import:
            if let presenter {
                linkActions.importNode(node, isFolderLink: false, from: presenter)
            }
        case .download where context.isLink:
            if let presenter {
                if let link = context.fileLink {
                    linkActions.downloadFileLink(link, from: presenter)
                } else {
                    linkActions.downloadFolderLinkNodes([node], from: presenter)
                }
            }
        case .sendToChat where context.isLink:
            if let presenter {
                linkActions.sendToChat(node, fileLink: context.fileLink, from: presenter)
            }
        case .shareLink, .manageLink:
            if context.isLink, let link = context.fileLink {
                if let presenter {
                    linkActions.shareFileLink(link, from: presenter, sender: sender)
                }
            } else {
                wrapped.nodeAction?(nodeAction, didSelect: action, for: node, from: sender)
            }
        case .moveToRubbishBin:
            if let presenter {
                moveToRubbishBin(node, presenter)
            }
        case .restore:
            presenter?.dismiss(animated: true)
            restore(node)
        case .info:
            showNodeInfo(node)
        case .hide:
            tracker.trackAnalyticsEvent(with: DocumentPreviewHideNodeMenuItemEvent())
            wrapped.nodeAction?(nodeAction, didSelect: action, for: node, from: sender)
        default:
            wrapped.nodeAction?(nodeAction, didSelect: action, for: node, from: sender)
        }
    }

    func nodeInfoViewController(
        _ nodeInfoViewController: NodeInfoViewController,
        presentParentNode node: MEGANode
    ) {
        presenter?.dismiss(animated: true) { [navigateToParent] in
            navigateToParent(node)
        }
    }

    private func showNodeInfo(_ node: MEGANode) {
        if let makeNodeInfo {
            presenter?.present(makeNodeInfo(node, self), animated: true)
            return
        }
        let viewModel = NodeInfoViewModel(
            withNode: node,
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            backupUseCase: BackupsUseCase(
                backupsRepository: BackupsRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            )
        )
        presenter?.present(
            NodeInfoViewController.instantiate(withViewModel: viewModel, delegate: self),
            animated: true
        )
    }
}
