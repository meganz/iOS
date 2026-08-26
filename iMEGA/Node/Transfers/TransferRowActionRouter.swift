import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import Transfer
import UIKit

/// App-side implementation of the new Transfers screen's per-row actions
/// (`Transfer.TransferRowRouting`). The action sheet and every destination live in the
/// app target and can't be built from the `Transfer` package, so this is injected
/// through `TransfersListViewControllerFactory.make`.
///
/// The `…` button presents an `ActionSheetViewController` (the same sheet style used
/// elsewhere, e.g. Cloud Drive). Its actions and the row-body open all push/present
/// from the Transfers screen's own navigation controller (`navigationController`), set
/// by the composition root once the screen is hosted.
final class TransferRowActionRouter: TransferRowRouting {
    weak var navigationController: UINavigationController?

    private let nodeUseCase: any NodeUseCaseProtocol
    private let nodeNavigationRouter: any NodeNavigationRouting
    private let sdk = MEGASdk.sharedSdk

    init(
        nodeUseCase: some NodeUseCaseProtocol = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        ),
        nodeNavigationRouter: some NodeNavigationRouting = NodeNavigationRouter()
    ) {
        self.nodeUseCase = nodeUseCase
        self.nodeNavigationRouter = nodeNavigationRouter
    }

    func presentActions(
        for transfer: TransferEntity,
        context: TransferRowActionContext,
        onRetry: @MainActor @escaping () -> Void,
        onClear: @MainActor @escaping () -> Void
    ) {
        guard let presenter = navigationController, let presenterView = presenter.view else { return }
        let actions = sheetActions(for: transfer, context: context, onRetry: onRetry, onClear: onClear)
        guard !actions.isEmpty else { return }
        let sheet = TransferActionsSheetViewController(
            actions: actions,
            icon: MEGAAssets.UIImage.image(forFileName: context.name),
            name: context.name,
            detail: context.detail,
            sender: presenterView
        )
        presenter.present(sheet, animated: true)
    }

    func openFile(for transfer: TransferEntity) {
        NodeOpener(navigationController: navigationController)
            .openNode(nodeHandle: transfer.nodeHandle, config: .withOptionalDisplayMode(.transfers))
    }

    func showUpgrade() {
        UpgradeSubscriptionRouter(presenter: navigationController).showUpgradeAccount()
    }

    // MARK: - Action sheet

    /// Completed rows offer View in folder (when allowed), Open with, Share link and
    /// Clear; failed/cancelled rows offer Retry (when the source is still retryable)
    /// and Clear. Mirrors the legacy widget's `DisplayModeTransfers` /
    /// `DisplayModeTransfersFailed` action sets.
    private func sheetActions(
        for transfer: TransferEntity,
        context: TransferRowActionContext,
        onRetry: @MainActor @escaping () -> Void,
        onClear: @MainActor @escaping () -> Void
    ) -> [ActionSheetAction] {
        let clear = action(Strings.Localizable.clear, MEGAAssets.UIImage.monoEraserMediumThinOutline, handler: onClear)

        switch transfer.state {
        case .complete:
            var actions: [ActionSheetAction] = []
            if context.canViewInFolder {
                actions.append(action(Strings.Localizable.viewInFolder, MEGAAssets.UIImage.monoFileSearch02MediumThinOutline) { [weak self] in
                    self?.viewInFolder(for: transfer)
                })
            }
            actions.append(action(Strings.Localizable.openIn, MEGAAssets.UIImage.externalLink) { [weak self] in
                self?.openWith(for: transfer)
            })
            actions.append(action(Strings.Localizable.General.MenuAction.ShareLink.title(1), MEGAAssets.UIImage.link01) { [weak self] in
                self?.shareLink(for: transfer)
            })
            if context.canClear {
                actions.append(clear)
            }
            return actions
        default:
            var actions: [ActionSheetAction] = []
            if context.canRetry {
                actions.append(action(Strings.Localizable.retry, MEGAAssets.UIImage.rotateCcw, handler: onRetry))
            }
            if context.canClear {
                actions.append(clear)
            }
            return actions
        }
    }

    private func action(_ title: String, _ image: UIImage, handler: @escaping () -> Void) -> ActionSheetAction {
        ActionSheetAction(title: title, detail: nil, image: image, style: .default, actionHandler: handler)
    }

    // MARK: - Navigation

    private func viewInFolder(for transfer: TransferEntity) {
        switch transfer.type {
        case .upload: navigateToCloudDriveParent(of: transfer)
        case .download: openOfflineFolder(parentPath: transfer.parentPath)
        default: break
        }
    }

    private func openWith(for transfer: TransferEntity) {
        guard let node = node(for: transfer), let presenter = navigationController else { return }
        ExportFileRouter(presenter: presenter, sender: presenter.view)
            .export(node: node.toNodeEntity())
    }

    private func shareLink(for transfer: TransferEntity) {
        guard MEGAReachabilityManager.isReachableHUDIfNot(), let node = node(for: transfer) else { return }
        let getLinkNC = GetLinkViewController.instantiate(withNodes: [node])
        navigationController?.present(getLinkNC, animated: true)
    }

    private func node(for transfer: TransferEntity) -> MEGANode? {
        sdk.node(forHandle: transfer.nodeHandle)
    }

    /// Uploads deep-link to the destination's parent folder in Cloud Drive. The
    /// transfers screen is dismissed first, then `NodeNavigationRouter` switches to the
    /// Drive tab and rebuilds the node hierarchy (matching the legacy widget).
    private func navigateToCloudDriveParent(of transfer: TransferEntity) {
        guard let node = node(for: transfer),
              let parent = sdk.node(forHandle: node.parentHandle),
              parent.isFolder() else { return }
        let parentEntity = parent.toNodeEntity()
        navigationController?.dismiss(animated: true) { [self] in
            Task {
                guard let hierarchy = await nodeUseCase.parentsForHandle(parentEntity.handle) else { return }
                let access = nodeUseCase.nodeAccessLevel(nodeHandle: parentEntity.handle)
                nodeNavigationRouter.navigateThroughNodeHierarchy(
                    hierarchy,
                    isOwnNode: access == .owner,
                    isInRubbishBin: parentEntity.nodeType == .rubbish
                )
            }
        }
    }

    /// Offline downloads open the Offline screen at the download's parent folder. The
    /// stored `parentPath` is rooted at the offline directory; drop everything up to and
    /// including the first slash to get the path relative to Offline (legacy behaviour).
    private func openOfflineFolder(parentPath: String?) {
        guard let parentPath, let index = parentPath.firstIndex(of: "/") else { return }
        let pathFromOffline = String(parentPath.suffix(from: index).dropFirst())
        guard let offlineVC = UIStoryboard(name: "Offline", bundle: nil)
            .instantiateViewController(withIdentifier: "OfflineViewControllerID") as? OfflineViewController else { return }
        offlineVC.folderPathFromOffline = pathFromOffline.isEmpty ? nil : pathFromOffline
        navigationController?.pushViewController(offlineVC, animated: true)
    }
}

/// `ActionSheetViewController` with a node-info style header (file-type icon, name,
/// "size · date") matching the sheet used elsewhere (e.g. Cloud Drive). Built from plain
/// values rather than a node, so it also works for failed transfers that have no node.
final class TransferActionsSheetViewController: ActionSheetViewController {
    private let headerIcon: UIImage
    private let headerName: String
    private let headerDetail: String

    init(actions: [BaseAction], icon: UIImage, name: String, detail: String, sender: Any) {
        self.headerIcon = icon
        self.headerName = name
        self.headerDetail = detail
        super.init(nibName: nil, bundle: nil)
        self.actions = actions
        configurePresentationStyle(from: sender)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHeader()
    }

    private func configureHeader() {
        guard let headerView else { return }
        headerView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: TokenSpacing._17)

        let iconView = UIImageView(image: headerIcon)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = headerName
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.textColor = TokenColors.Text.primary
        titleLabel.lineBreakMode = .byTruncatingMiddle

        let detailLabel = UILabel()
        detailLabel.text = headerDetail
        detailLabel.font = .preferredFont(forTextStyle: .caption1)
        detailLabel.textColor = TokenColors.Text.secondary

        let labels = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        labels.axis = .vertical
        labels.spacing = TokenSpacing._1
        labels.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(iconView)
        headerView.addSubview(labels)
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: TokenSpacing._9),
            iconView.heightAnchor.constraint(equalToConstant: TokenSpacing._9),
            iconView.leadingAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.leadingAnchor, constant: TokenSpacing._5),
            iconView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            labels.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: TokenSpacing._3),
            labels.trailingAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.trailingAnchor, constant: -TokenSpacing._5),
            labels.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])

        tableView.tableHeaderView = headerView
    }
}
