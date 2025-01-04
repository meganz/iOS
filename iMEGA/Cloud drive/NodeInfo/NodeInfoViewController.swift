import CloudDrive
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI
import UIKit

enum NodeInfoTableViewSection {
    case info
    case details
    case location
    case description(NodeDescriptionCellController)
    case tags(NodeTagsCellController)
    case link
    case versions
    case sharing
    case pendingSharing
    case removeSharing
}

enum InfoSectionRow {
    case preview
    case owner
    case verifyContact
}

enum DetailsSectionRow {
    case location
    case fileSize
    case currentFileVersionSize
    case folderSize
    case currentFolderVersionsSize
    case previousFolderVersionsSize
    case countVersions
    case fileType
    case modificationDate
    case addedDate
    case contains
    case linkCreationDate
}

@MainActor
@objc protocol NodeInfoViewControllerDelegate {
    func nodeInfoViewController(_ nodeInfoViewController: NodeInfoViewController, presentParentNode node: MEGANode)
}

final class NodeInfoViewController: UITableViewController {
    private var node: MEGANode
    private var folderInfo: MEGAFolderInfo?
    private var delegate: (any NodeInfoViewControllerDelegate)?
    private var nodeVersions: [MEGANode] = []
    
    private let viewModel: NodeInfoViewModel
    private var cachedSections: [NodeInfoTableViewSection] = []
    private var cachedPendingShares: [MEGAShare] = []
    private var cachedActiveShares: [MEGAShare] = []
    private var cachedDetailRows: [DetailsSectionRow] = []
    private var cachedInfoRows: [InfoSectionRow] = []

    var presentViewController: ((UIViewController) -> Void)?
    var dismissViewController: ((_ completion: (() -> Void)?) -> Void)?
    var showSavedDescriptionState: ((NodeDescriptionCellControllerModel.SavedState) -> Void)?
    var hasPendingNodeDescriptionChanges: (() -> Bool)?
    var saveNodeDescriptionChanges: (() async -> NodeDescriptionCellControllerModel.SavedState?)?

    private var isContactVerified: Bool {
        viewModel.isContactVerified()
    }

    private var shouldDisplayContactVerificationInfo: Bool {
        viewModel.shouldDisplayContactVerificationInfo
    }

    init?(
        coder: NSCoder,
        viewModel: NodeInfoViewModel,
        delegate: (any NodeInfoViewControllerDelegate)?
    ) {
        self.viewModel = viewModel
        self.node = viewModel.node
        self.nodeVersions = viewModel.node.mnz_versions()
        self.delegate = delegate
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    @objc class func instantiate(
        withViewModel viewModel: NodeInfoViewModel,
        delegate: (any NodeInfoViewControllerDelegate)?
    ) -> MEGANavigationController {
        makeInstance(with: viewModel, delegate: delegate).navigationController
    }

    class func makeInstance(
        with viewModel: NodeInfoViewModel,
        delegate: (any NodeInfoViewControllerDelegate)?
    ) -> (navigationController: MEGANavigationController, nodeInfoViewController: NodeInfoViewController) {
        let nodeInfoVC = UIStoryboard(name: "Node", bundle: nil).instantiateViewController(
            identifier: "NodeInfoViewControllerID"
        ) { coder in
            NodeInfoViewController(coder: coder, viewModel: viewModel, delegate: delegate)
        }

        let navigationController = MEGANavigationController(
            rootViewController: NodeInfoWrapperViewController(with: nodeInfoVC)
        )
        
        return (navigationController, nodeInfoVC)
    }

    // MARK: - Public Interface
    func display(_ node: MEGANode, withDelegate delegate: some NodeInfoViewControllerDelegate) {
        self.node = node
        self.delegate = delegate
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }

        sdk.add(self)
        
        tableView.sectionHeaderTopPadding = 0
        tableView.register(UINib(nibName: "GenericHeaderFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "GenericHeaderFooterViewID")
        tableView.register(HostingTableViewCell<NodeInfoVerifyAccountTableViewCell>.self,
                                 forCellReuseIdentifier: "NodeInfoVerifyAccountTableViewCell")
        tableView.register(HostingTableViewCell<NodeInfoLocationView>.self, forCellReuseIdentifier: "NodeInfoLocationView")
        NodeDescriptionCellController.registerCell(for: tableView)
        NodeTagsCellController.registerCell(for: tableView)

        viewModel.dispatch(.viewDidLoad)
        setupColor()
    }

    deinit {
        sdk.remove(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if node.isFolder() {
            fetchFolderInfo()
        } else {
            cacheNodePropertiesSoThatTableViewChangesAreAtomic()
            reloadData()
        }

        addKeyboardNotificationsFromDescriptionCell()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardNotificationsFromDescriptionCell()
        viewModel.dispatch(.viewDidDisappear)
    }
    
    private func executeCommand(_ command: NodeInfoViewModel.Command) {
        switch command {
        case .reloadSections:
            cacheNodePropertiesSoThatTableViewChangesAreAtomic()
            reloadData()
        }
    }
    
    private func reloadData() {
        tableView.reloadData()
    }
    
    /// Custom UI update method to respond to node updates
    /// Call this method instead of `reloadData()`  when you want to handle node updates
    private func reloadDataUponNodeUpdate() {
        logDebug(message: "Reload data for node \(node.handle) upon updates")
        cacheNodePropertiesSoThatTableViewChangesAreAtomic()
        handleNodeDescriptionUpdateIfNeeded()

        guard cachedSections.isNotEmpty else {
            MEGALogError("[Node Info] No caches section created after node update")
            return
        }

        // In case the number of sections changed after node update, we'll need to reload the whole tableView
        // E.g: When user remove all the contacts in the .sharing section
        guard cachedSections.count == tableView.numberOfSections else {
            tableView.reloadData()
            return
        }

        // We reload all the sections in the tableview, except for the `description` section
        // because the built-in reloadSections will cause the sections to lose its first responder status
        // while in fact we need to keep the first responder as is.
        guard let (_, descSection) = nodeDescriptionCellControllerWithSection() else {
            tableView.reloadData()
            return
        }

        let sectionsToReload = (0 ..< cachedSections.count).filter { $0 != descSection }
        tableView.reloadSections(.init(sectionsToReload), with: .automatic)
    }
    
    // MARK: - Private methods

    private func setupColor() {
        let backgroundColor = TokenColors.Background.page
        view.backgroundColor = backgroundColor
        tableView.backgroundColor = backgroundColor
    }
    
    private var sdk: MEGASdk {
        MEGASdk.shared
    }
    
    private func fetchFolderInfo() {
        sdk.getFolderInfo(
                for: node,
                delegate: RequestDelegate { [weak self] result in
            guard
                let self,
                case .success(let request) = result,
                let folderInfo = request.megaFolderInfo
            else {
                MEGALogError("Could not fetch MEGAFolderInfo")
                self?.presentingViewController?.dismiss(animated: true)
                return
            }
            self.folderInfo = folderInfo
            cacheNodePropertiesSoThatTableViewChangesAreAtomic()
            reloadData()
        })
    }
    
    private func reloadOrShowWarningAfterNodeUpdate() {
        guard let nodeUpdated = sdk.node(forHandle: node.handle) else {
            let alertTitle = node.isFolder() ? Strings.Localizable.youNoLongerHaveAccessToThisFolderAlertTitle : Strings.Localizable.youNoLongerHaveAccessToThisFileAlertTitle
            
            let warningAlertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)
            warningAlertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            presentViewController?(warningAlertController)
            return
        }
        
        node = nodeUpdated
        reloadDataUponNodeUpdate()
    }
    
    private func showNodeVersions() {
        guard let nodeVersionsVC = storyboard?.instantiateViewController(withIdentifier: "NodeVersionsVC") as? NodeVersionsViewController else {
            fatalError("Could not instantiate NodeVersionsViewController")
        }
        nodeVersionsVC.node = node
        navigationController?.pushViewController(nodeVersionsVC, animated: true)
    }
    
    private func showParentNode() {
        if let parentNode = sdk.parentNode(for: node) {
            dismissViewController? {
                self.delegate?.nodeInfoViewController(self, presentParentNode: parentNode)
            }
        } else {
            MEGALogError("Unable to find parent node")
        }
    }
    
    private func showManageLinkView() {
        GetLinkRouter(presenter: self,
                      nodes: [node]).start()
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        Task { await viewModel.openSharedDialog() }
    }
    
    private func currentVersionRemoved() {
        guard let firstVersion = nodeVersions.first else {
            return
        }
        node = firstVersion
        nodeVersions = node.mnz_versions()
        reloadData()
    }
    
    private func nodeVersionRemoved() {
        nodeVersions = node.mnz_versions()
        reloadDataUponNodeUpdate()
    }
    
    private func showAlertForRemovingPendingShare(forIndexPat indexPath: IndexPath) {
        guard let email = cachedPendingShares[indexPath.row].user else {
            MEGALogError("Could not fetch pending share email")
            return
        }
        
        let removePendingShareAlertController = UIAlertController(title: Strings.Localizable.removeUserTitle, message: email, preferredStyle: .alert)
        
        removePendingShareAlertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
        removePendingShareAlertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default, handler: { [weak self] _ in
            guard let self else { return }
            sdk.share(node, withEmail: email, level: MEGAShareType.accessUnknown.rawValue, delegate: MEGAShareRequestDelegate(toChangePermissionsWithNumberOfRequests: 1, completion: { [weak self] in
                
                guard
                    let self,
                    let nodeUpdated = sdk.node(forHandle: node.handle)
                else {
                    MEGALogError("Could not fetch updated Node")
                    return
                }
                node = nodeUpdated
                reloadData()
            }))
        }))
        
        presentViewController?(removePendingShareAlertController)
    }
    
    private func prepareShareFolderPermissionsAlertController(fromIndexPat indexPath: IndexPath) {
        let activeShare = cachedActiveShares[indexPath.row - 1].access
        let checkmarkImageView = UIImageView(image: UIImage.turquoiseCheckmark)

        guard let cell = tableView.cellForRow(at: indexPath) as? ContactTableViewCell else {
            return
        }
        guard let user = sdk.contact(forEmail: cachedActiveShares[indexPath.row - 1].user) else {
            return
        }
        
        var actions = [ActionSheetAction]()
        let isBackupNode = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupNode(node.toNodeEntity())
        
        if !isBackupNode {
            actions.append(ActionSheetAction(title: Strings.Localizable.fullAccess, detail: nil, accessoryView: activeShare == .accessFull ? checkmarkImageView : nil, image: UIImage.fullAccessPermissions, style: .default) { [weak self] in
                self?.shareNode(withLevel: .accessFull, forUser: user, atIndexPath: indexPath)
            })
            actions.append(ActionSheetAction(title: Strings.Localizable.readAndWrite, detail: nil, accessoryView: activeShare == .accessReadWrite ? checkmarkImageView : nil, image: UIImage.readWritePermissions, style: .default) { [weak self] in
                self?.shareNode(withLevel: .accessReadWrite, forUser: user, atIndexPath: indexPath)
            })
            actions.append(ActionSheetAction(title: Strings.Localizable.readOnly, detail: nil, accessoryView: activeShare == .accessRead ? checkmarkImageView : nil, image: UIImage.readPermissions, style: .default) { [weak self] in
                self?.shareNode(withLevel: .accessRead, forUser: user, atIndexPath: indexPath)
            })
        }
        
        actions.append(ActionSheetAction(title: Strings.Localizable.remove, detail: nil, image: UIImage.delete, style: .destructive) { [weak self] in
            self?.shareNode(withLevel: .accessUnknown, forUser: user, atIndexPath: indexPath)
        })
        
        let permissionsActionSheet = ActionSheetViewController(
            actions: actions,
            headerTitle: isBackupNode ? nil : Strings.Localizable.permissions,
            dismissCompletion: nil,
            sender: cell.permissionsImageView
        )
        
        presentViewController?(permissionsActionSheet)
    }
    
    private func shareNode(withLevel level: MEGAShareType, forUser user: MEGAUser, atIndexPath indexPath: IndexPath) {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
        sdk.share(node, with: user, level: level.rawValue, delegate:
            MEGAShareRequestDelegate.init(toChangePermissionsWithNumberOfRequests: 1, completion: { [weak self] in
                if level != .accessUnknown {
                    self?.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            }))
    }

    private func pendingOutShares() -> [MEGAShare] {
        guard let outShares = node.outShares() as? [MEGAShare] else {
            return []
        }
        return outShares.filter({ $0.isPending })
    }
    
    private func activeOutShares() -> [MEGAShare] {
        guard let outShares = node.outShares() as? [MEGAShare] else {
            return []
        }
        return outShares.filter({ !$0.isPending })
    }
    
    // we are caching all the properties that are needed to render table view so that
    // there's always correct backing for the table view to access the data
    private func cacheNodePropertiesSoThatTableViewChangesAreAtomic() {
        cachedPendingShares = pendingOutShares()
        cachedActiveShares = activeOutShares()
        cachedSections = sections(descriptionCellController: descriptionCellController())
        cachedDetailRows = detailRows()
        cachedInfoRows = infoRows()
        logDebug(message: "Cache sections for \(node.handle) created: \(cachedSections)")
    }

    private func descriptionCellController() -> NodeDescriptionCellController? {
        cachedSections.compactMap { section in
            guard case .description(let controller) = section else { return nil }
            return controller
        }.first
    }

    private func showVerifyCredentials() {
        guard let navigationController else { return }

        viewModel.openVerifyCredentials(
            from: navigationController,
            completion: { [weak self] in
                guard let self else { return }
                self.cachedInfoRows = self.infoRows()
                self.reloadData()
            }
        )
    }
    
    // MARK: - TableView Data Source

    /**
     This method returns an array of `NodeInfoTableViewSection` representing the different sections to be displayed in the table view based on the node's properties and the view model state.

     - Parameters:
     - descriptionCellController: An optional `NodeDescriptionCellController` responsible for managing and displaying the description section in the table view. This controller handles all the table view data source and delegate methods related to the node description. If a `NodeDescriptionCellController` was previously created, it can be passed to this method to avoid creating a new instance, thus reusing the existing controller. If not provided, a new one will be created.

     - Returns: An array of `NodeInfoTableViewSection` containing the sections to be displayed in the table view.
     */
    private func sections(descriptionCellController: NodeDescriptionCellController?) -> [NodeInfoTableViewSection] {
        var sections = [NodeInfoTableViewSection]()
        sections.append(.info)
        sections.append(.details)

        let descriptionSection: NodeInfoTableViewSection
        if let descriptionCellController {
            descriptionSection = .description(descriptionCellController)
        } else {
            descriptionSection = makeNodeDescriptionSection()
        }

        sections.append(descriptionSection)

        if viewModel.shouldShowNodeTags {
            sections.append(
                .tags(
                    NodeTagsCellController(
                        controller: self,
                        viewModel: NodeTagsCellControllerModel(
                            node: node.toNodeEntity(),
                            accountUseCase: AccountUseCase(
                                repository: AccountRepository.newRepo
                            )
                        ), expiredAccountAlertPresenter: UIApplication.shared.delegate as? AppDelegate
                    )
                )
            )
        }

        if viewModel.nodeInfoLocationViewModel != nil {
            sections.append(.location)
        }

        if !node.mnz_isInRubbishBin() {
            if sdk.accessLevel(for: node) == .accessOwner && !node.isTakenDown() {
                sections.append(.link)
            }
        }

        if !node.mnz_isInRubbishBin() {
            if node.isFolder() && sdk.accessLevel(for: node) == .accessOwner {
                sections.append(.sharing)
                if pendingOutShares().isNotEmpty {
                    sections.append(.pendingSharing)
                }
                if activeOutShares().isNotEmpty {
                    sections.append(.removeSharing)
                }
            }
        }
        return sections
    }
    
    private func infoRows() -> [InfoSectionRow] {
        var infoRows = [InfoSectionRow]()
        infoRows.append(.preview)
        if node.isInShare() {
            infoRows.append(.owner)
            if shouldDisplayContactVerificationInfo && !isContactVerified {
                infoRows.append(.verifyContact)
            }
        }
        return infoRows
    }
    
    private func detailRows() -> [DetailsSectionRow] {
        var detailRows = [DetailsSectionRow]()
        if sdk.accessLevel(for: node) == .accessOwner {
            detailRows.append(.location)
        }
        
        if node.isFile() {
            detailRows.append(.fileSize)
            if node.mnz_numberOfVersions() != 0 {
                detailRows.append(.currentFileVersionSize)
            }
            detailRows.append(.fileType)
            detailRows.append(.modificationDate)
        } else if node.isFolder() {
            detailRows.append(.folderSize)
            if folderInfo != nil && folderInfo?.versions != 0 {
                detailRows.append(.currentFolderVersionsSize)
                detailRows.append(.previousFolderVersionsSize)
                detailRows.append(.countVersions)
            }
            detailRows.append(.contains)
        }
        detailRows.append(.addedDate)
        
        if node.isExported() {
            detailRows.append(.linkCreationDate)
        }
        return detailRows
    }

    private func makeNodeDescriptionSection() -> NodeInfoTableViewSection {
        let descriptionViewModel = NodeDescriptionCellControllerModel(
            node: node.toNodeEntity(),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            backupUseCase: BackupsUseCase(
                backupsRepository: BackupsRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            nodeDescriptionUseCase: NodeDescriptionUseCase(
                repository: NodeDescriptionRepository.newRepo
            ),
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            maxCharactersAllowed: 300,
            refreshUI: { [weak self] code in
                guard let self else { return }
                tableView.beginUpdates()
                code()
                tableView.endUpdates()
            }, descriptionSaved: { [weak self] savedState in
                guard let self else { return }
                showSavedDescriptionState?(savedState)
            }
        )

        hasPendingNodeDescriptionChanges = { descriptionViewModel.hasPendingChanges() }
        saveNodeDescriptionChanges = { await descriptionViewModel.savePendingChanges() }

        return .description(NodeDescriptionCellController(viewModel: descriptionViewModel))
    }

    // MARK: - TableView cells
    
    private func previewCell(forIndexPath indexPath: IndexPath) -> NodeInfoPreviewTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoPreviewCell", for: indexPath) as? NodeInfoPreviewTableViewCell else {
            fatalError("Could not get NodeInfoDetailTableViewCell")
        }
        
        cell.configure(forNode: node,
                       isNodeInRubbish: node.mnz_isInRubbishBin(),
                       folderInfo: folderInfo,
                       isUndecryptedFolder: viewModel.isNodeUndecryptedFolder)
        return cell
    }
    
    private func ownerCell(forIndexPath indexPath: IndexPath) -> NodeOwnerInfoTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeOwnerInfoTableViewCell", for: indexPath) as? NodeOwnerInfoTableViewCell else {
            fatalError("Could not get NodeInfoDetailTableViewCell")
        }
        
        if let user = sdk.userFrom(inShare: node) {
            cell.configure(
                user: user,
                shouldDisplayUserVerifiedIcon: shouldDisplayContactVerificationInfo && isContactVerified
            )
        }
        
        return cell
    }

    private func verifyContactCell(_ indexPath: IndexPath) -> HostingTableViewCell<NodeInfoVerifyAccountTableViewCell> {
        guard let cell = tableView?.dequeueReusableCell(withIdentifier: "NodeInfoVerifyAccountTableViewCell", for: indexPath) as? HostingTableViewCell<NodeInfoVerifyAccountTableViewCell> else {
            return HostingTableViewCell<NodeInfoVerifyAccountTableViewCell>()
        }

        let upgradeCellView = NodeInfoVerifyAccountTableViewCell(
            onTap: { [weak self] in
                self?.showVerifyCredentials()
            }
        )
        cell.host(upgradeCellView, parent: self)
        cell.selectionStyle = .none
        cell.backgroundColor = TokenColors.Background.page
        return cell
    }
    
    private func locationCell(_ indexPath: IndexPath) -> HostingTableViewCell<NodeInfoLocationView> {
        guard let nodeInfoLocationViewModel = viewModel.nodeInfoLocationViewModel,
            let cell = tableView?.dequeueReusableCell(withIdentifier: "NodeInfoLocationView", for: indexPath) as? HostingTableViewCell<NodeInfoLocationView> else {
            return HostingTableViewCell<NodeInfoLocationView>()
        }
        
        cell.host(NodeInfoLocationView(viewModel: nodeInfoLocationViewModel), parent: self)
        cell.selectionStyle = .none
        cell.backgroundColor = TokenColors.Background.page
        
        return cell
    }
    
    private func detailCell(forIndexPath indexPath: IndexPath) -> NodeInfoDetailTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoDetailCell", for: indexPath) as? NodeInfoDetailTableViewCell else {
            fatalError("Could not get NodeInfoDetailTableViewCell")
        }
        
        cell.configure(forNode: node, rowType: cachedDetailRows[indexPath.row], folderInfo: folderInfo)
        
        return cell
    }
    
    private func linkCell(forIndexPath indexPath: IndexPath) -> NodeInfoActionTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoActionCell", for: indexPath) as? NodeInfoActionTableViewCell else {
            fatalError("Could not get NodeInfoActionTableViewCell")
        }
        
        cell.configureLinkCell(forNode: node)
        
        return cell
    }
    
    private func versionsCell(forIndexPath indexPath: IndexPath) -> NodeInfoActionTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoActionCell", for: indexPath) as? NodeInfoActionTableViewCell else {
            fatalError("Could not get NodeInfoActionTableViewCell")
        }
        
        cell.configureVersionsCell(forNode: node)
        
        return cell
    }
    
    private func addContactSharingCell(forIndexPath indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoContactCell", for: indexPath) as? ContactTableViewCell else {
            return UITableViewCell()
        }
        
        cell.backgroundColor = TokenColors.Background.page
        cell.permissionsImageView.isHidden = true
        cell.avatarImageView.image = UIImage.inviteContactShare
        cell.nameLabel.text = Strings.Localizable.addContact
        cell.shareLabel.isHidden = true
        
        return cell
    }
    
    private func contactSharingCell(forIndexPath indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoContactCell", for: indexPath) as? ContactTableViewCell else {
            return UITableViewCell()
        }
        
        guard let user = sdk.contact(forEmail: cachedActiveShares[safe: indexPath.row - 1]?.user) else {
            CrashlyticsLogger.log("[NodeInfo] User not found.")
            return UITableViewCell()
        }
        
        cell.backgroundColor = TokenColors.Background.page
        cell.avatarImageView.mnz_setImage(forUserHandle: user.handle, name: user.mnz_displayName)
        cell.verifiedImageView.isHidden = !sdk.areCredentialsVerified(of: user)
        if user.mnz_displayName != "" {
            cell.nameLabel.text = user.mnz_displayName
            cell.shareLabel.text = user.email
        } else {
            cell.nameLabel.text = user.email
            cell.shareLabel.isHidden = true
        }
        
        cell.permissionsImageView.isHidden = false
        
        let permissionImage = UIImage.mnz_permissionsButtonImage(for: cachedActiveShares[indexPath.row - 1].access)
        cell.permissionsImageView.image = permissionImage?.withRenderingMode(.alwaysTemplate)
        cell.permissionsImageView.tintColor = TokenColors.Icon.secondary
        return cell
    }
    
    private func pendingSharingCell(forIndexPath indexPath: IndexPath) -> ContactTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoContactCell", for: indexPath) as? ContactTableViewCell else {
            fatalError("Could not get ContactTableViewCell")
        }
        
        cell.backgroundColor = TokenColors.Background.page
        cell.avatarImageView.mnz_setImage(forUserHandle: MEGAInvalidHandle, name: cachedPendingShares[indexPath.row].user ?? "")
        cell.nameLabel.text = cachedPendingShares[indexPath.row].user
        cell.shareLabel.isHidden = true
        cell.permissionsImageView.isHidden = false
        cell.permissionsImageView.image = UIImage.delete
        cell.permissionsImageView.tintColor = TokenColors.Support.error
        return cell
    }
    
    private func removeSharingCell(forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoRemoveSharing", for: indexPath)
        
        cell.backgroundColor = TokenColors.Background.page
        guard let removeLabel = cell.viewWithTag(1) as? UILabel else {
            fatalError("Could not get RemoveLabel")
        }

        removeLabel.text = Strings.Localizable.removeShare
        
        removeLabel.textColor = TokenColors.Text.error
        return cell
    }

    private func removeKeyboardNotificationsFromDescriptionCell() {
        nodeDescriptionCellControllerWithSection()?.0.removeKeyboardNotifications()
    }

    private func addKeyboardNotificationsFromDescriptionCell() {
        guard let (controller, section) = nodeDescriptionCellControllerWithSection() else { return }
        controller.addKeyboardNotifications(tableView: tableView, indexPath: IndexPath(row: 0, section: section))
    }

    private func nodeDescriptionCellControllerWithSection() -> (NodeDescriptionCellController, Int)? {
        cachedSections.enumerated().compactMap {
            if case .description(let controller) = $0.element {
                return (controller, $0.offset)
            } else {
                return nil
            }
        }.first
    }
    
    private func handleNodeDescriptionUpdateIfNeeded() {
        guard let (descriptionController, _) = nodeDescriptionCellControllerWithSection() else { return }
        descriptionController.processNodeUpdate(node.toNodeEntity())
    }
}

// MARK: - UITableViewDataSource

extension NodeInfoViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        let sectionCount = cachedSections.count
        return sectionCount
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch cachedSections[section] {
        case .info:
            cachedInfoRows.count
        case .details:
            cachedDetailRows.count
        case .sharing:
            cachedActiveShares.count + 1
        case .pendingSharing:
            cachedPendingShares.count
        case .location, .link, .versions, .removeSharing:
            1
        case .description(let controller):
            controller.tableView(tableView, numberOfRowsInSection: section)
        case .tags(let controller):
            controller.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch cachedSections[indexPath.section] {
        case .info:
            switch cachedInfoRows[indexPath.row] {
            case .preview:
                return previewCell(forIndexPath: indexPath)
            case .owner:
                return ownerCell(forIndexPath: indexPath)
            case .verifyContact:
                return verifyContactCell(indexPath)
            }
        case .details:
            return detailCell(forIndexPath: indexPath)
        case .location:
            return locationCell(indexPath)
        case .link:
            return linkCell(forIndexPath: indexPath)
        case .versions:
            return versionsCell(forIndexPath: indexPath)
        case .sharing:
            if indexPath.row == 0 {
                return addContactSharingCell(forIndexPath: indexPath)
            } else {
                return contactSharingCell(forIndexPath: indexPath)
            }
        case .pendingSharing:
            return pendingSharingCell(forIndexPath: indexPath)
        case .removeSharing:
            return removeSharingCell(forIndexPath: indexPath)
        case .description(let controller):
            return controller.tableView(tableView, cellForRowAt: indexPath)
        case .tags(let controller):
            return controller.tableView(tableView, cellForRowAt: indexPath)
        }
    }
}

// MARK: - UITableViewDelegate

extension NodeInfoViewController {
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if case .tags(let controller) = cachedSections[section] {
            return controller.tableView(tableView, viewForHeaderInSection: section)
        }
        
        var topDistance: CGFloat = 30.0
        if case .description(let controller) = cachedSections[section] {
            return controller.tableView(tableView, viewForHeaderInSection: section)
        } else if section == 0 {
            topDistance = 1
        } else if section > 0, case .description(let controller) = cachedSections[section - 1] {
            topDistance = controller.viewModel.hasReadOnlyAccess ? topDistance : 5
        }

        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GenericHeaderFooterViewID") as? GenericHeaderFooterView else {
            return UIView(frame: .zero)
        }

        header.titleLabel.attributedText = nil
        header.setPreferredBackgroundColor(TokenColors.Background.page)
        
        switch cachedSections[section] {
        case .details:
            header.configure(title: Strings.Localizable.details, topDistance: topDistance, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .location:
            header.configure(title: Strings.Localizable.CloudDrive.Info.Node.location, topDistance: topDistance, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .link:
            header.configure(title: Strings.Localizable.link, topDistance: topDistance, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .versions:
            header.configure(title: Strings.Localizable.versions.localizedUppercase, topDistance: topDistance, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .sharing:
            header.configure(title: Strings.Localizable.shareWith.localizedUppercase, topDistance: topDistance, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .pendingSharing:
            header.configure(title: Strings.Localizable.pending.localizedUppercase, topDistance: topDistance, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .removeSharing:
            header.configure(title: nil, topDistance: topDistance, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        default:
            header.configure(title: nil, topDistance: topDistance, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        }

        return header
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if case .description(let controller) = cachedSections[section],
           let view = controller.tableView(tableView, viewForFooterInSection: section) {
            return view
        } else if case .tags(let controller) = cachedSections[section],
             let view = controller.tableView(tableView, viewForFooterInSection: section) {
            return view
        }

        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GenericHeaderFooterViewID") as? GenericHeaderFooterView else {
            return UIView(frame: .zero)
        }
        footer.setPreferredBackgroundColor(TokenColors.Background.page)

        let isTopSeparatorVisible = switch cachedSections[section] {
        case .location, .description:
            false
        default:
            true
        }
        footer.configure(
            title: nil,
            topDistance: 5.0,
            isTopSeparatorVisible: isTopSeparatorVisible,
            isBottomSeparatorVisible: false
        )
        return footer
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch cachedSections[indexPath.section] {
        case .details:
            switch cachedDetailRows[indexPath.row] {
            case .location:
                showParentNode()
            default:
                break
            }
        case .link:
            showManageLinkView()
        case .versions:
            showNodeVersions()
        case .removeSharing:
            node.mnz_removeSharing()
        case .sharing:
            if indexPath.row == 0 {
                Task { await viewModel.openSharedDialog() }
            } else {
                prepareShareFolderPermissionsAlertController(fromIndexPat: indexPath)
            }
        case .pendingSharing:
            showAlertForRemovingPendingShare(forIndexPat: indexPath)
        case .tags(let controller):
            controller.tableView(tableView, didSelectRowAt: indexPath)
        case .location, .info, .description:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - MEGAGlobalDelegate

extension NodeInfoViewController: MEGAGlobalDelegate {
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let nodeList else { return }
            
        for nodeIndex in 0..<nodeList.size {
            guard let nodeUpdated = nodeList.node(at: nodeIndex) else {
                continue
            }
            
            logDebug(message: "Node \(nodeUpdated.handle) changed with types: \(nodeUpdated.toNodeEntity().changeTypes)")
            
            if nodeUpdated.hasChangedType(.removed) {
                if nodeUpdated.handle == node.handle {
                    logDebug(message: "Current version removed")
                    return currentVersionRemoved()
                } else if nodeVersions.contains(where: { $0.handle == nodeUpdated.handle }) {
                    logDebug(message: "Node version removed")
                    return nodeVersionRemoved()
                }
            }
            
            if nodeUpdated.hasChangedType(.parent) && nodeUpdated.handle == node.handle {
                guard let parentNode = sdk.node(forHandle: nodeUpdated.parentHandle) else { return }
                if parentNode.isFolder() { // Node moved
                    guard let newNode = sdk.node(forHandle: nodeUpdated.handle) else { return }
                    logDebug(message: "Node moved")
                    node = newNode
                    
                } else { // Node versioned
                    guard let newNode = sdk.node(forHandle: nodeUpdated.parentHandle) else { return }
                    logDebug(message: "Node versioned")
                    node = newNode
                }
                
                return reloadOrShowWarningAfterNodeUpdate()
            }
            
            if nodeUpdated.handle == node.handle {
                logDebug(message: "Generic update")
                
                return reloadOrShowWarningAfterNodeUpdate()
            }
        }
    }
    
    @objc func logDebug(message: String) {
        CrashlyticsLogger.log(category: .nodeInfo, message)
    }
}

extension AppDelegate: CloudDrive.ExpiredAccountAlertPresenting {}
