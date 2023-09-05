import MEGADomain
import MEGAL10n
import MEGASDKRepo
import MEGASwiftUI
import UIKit

enum NodeInfoTableViewSection {
    case info
    case details
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

@objc protocol NodeInfoViewControllerDelegate {
    func nodeInfoViewController(_ nodeInfoViewController: NodeInfoViewController, presentParentNode node: MEGANode)
}

class NodeInfoViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var node = MEGANode()
    private var folderInfo: MEGAFolderInfo?
    private var delegate: (any NodeInfoViewControllerDelegate)?
    private var nodeVersions: [MEGANode] = []
    
    private var viewModel: NodeInfoViewModel?
    private var cachedSections: [NodeInfoTableViewSection] = []
    private var cachedPendingShares: [MEGAShare] = []
    private var cachedActiveShares: [MEGAShare] = []
    private var cachedDetailRows: [DetailsSectionRow] = []
    private var cachedInfoRows: [InfoSectionRow] = []

    private var isContactVerified: Bool {
        viewModel?.isContactVerified() == true
    }

    private var shouldDisplayContactVerificationInfo: Bool {
        viewModel?.shouldDisplayContactVerificationInfo == true
    }
    
    // MARK: - Lifecycle

    @objc class func instantiate(withViewModel viewModel: NodeInfoViewModel,
                                 delegate: (any NodeInfoViewControllerDelegate)?) -> MEGANavigationController {
        guard let nodeInfoVC = UIStoryboard(name: "Node", bundle: nil).instantiateViewController(withIdentifier: "NodeInfoViewControllerID") as? NodeInfoViewController else {
            fatalError("Could not instantiate NodeInfoViewController")
        }
        
        nodeInfoVC.viewModel = viewModel
        nodeInfoVC.node = viewModel.node
        nodeInfoVC.delegate = delegate
        nodeInfoVC.nodeVersions = viewModel.node.mnz_versions()
        return MEGANavigationController.init(rootViewController: nodeInfoVC)
    }

    // MARK: - Public Interface
    func display(_ node: MEGANode, withDelegate delegate: some NodeInfoViewControllerDelegate) {
        self.node = node
        self.delegate = delegate
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Localizable.info
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.Localizable.close, style: .plain, target: self, action: #selector(closeButtonTapped))
        
        sdk.add(self)
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.register(UINib(nibName: "GenericHeaderFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "GenericHeaderFooterViewID")
        tableView.register(HostingTableViewCell<NodeInfoVerifyAccountTableViewCell>.self,
                                 forCellReuseIdentifier: "NodeInfoVerifyAccountTableViewCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if node.isFolder() {
            fetchFolderInfo()
        } else {
            cacheNodePropertiesSoThatTableViewChangesAreAtomic()
            reloadData()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
            reloadData()
        }
    }
    
    private func reloadData() {
        tableView.reloadData()
    }
    // MARK: - Private methods

    private func updateAppearance() {
        view.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        tableView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
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
                fatalError("Could not fetch MEGAFolderInfo")
            }
            self.folderInfo = folderInfo
            cacheNodePropertiesSoThatTableViewChangesAreAtomic()
            reloadData()
        })
    }
    
    private func reloadOrShowWarningAfterActionOnNode() {
        guard let nodeUpdated = sdk.node(forHandle: node.handle) else {
            let alertTitle = node.isFolder() ? Strings.Localizable.youNoLongerHaveAccessToThisFolderAlertTitle : Strings.Localizable.youNoLongerHaveAccessToThisFileAlertTitle
            
            let warningAlertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)
            warningAlertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(warningAlertController, animated: true, completion: nil)
            return
        }
        
        node = nodeUpdated
        reloadData()
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
            sdk.remove(self)
            dismiss(animated: true) {
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
        viewModel?.openSharedDialog()
    }
    
    @objc private func closeButtonTapped() {
        sdk.remove(self)
        viewModel?.complete()
        dismiss(animated: true, completion: nil)
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
        reloadData()
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
        
        present(removePendingShareAlertController, animated: true, completion: nil)
    }
    
    private func prepareShareFolderPermissionsAlertController(fromIndexPat indexPath: IndexPath) {
        let activeShare = cachedActiveShares[indexPath.row - 1].access
        let checkmarkImageView = UIImageView(image: Asset.Images.Generic.turquoiseCheckmark.image)

        guard let cell = tableView.cellForRow(at: indexPath) as? ContactTableViewCell else {
            return
        }
        guard let user = sdk.contact(forEmail: cachedActiveShares[indexPath.row - 1].user) else {
            return
        }
        
        var actions = [ActionSheetAction]()
        let isBackupNode = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo).isBackupNode(node.toNodeEntity())
        
        if !isBackupNode {
            actions.append(ActionSheetAction(title: Strings.Localizable.fullAccess, detail: nil, accessoryView: activeShare == .accessFull ? checkmarkImageView : nil, image: Asset.Images.SharedItems.fullAccessPermissions.image, style: .default) { [weak self] in
                self?.shareNode(withLevel: .accessFull, forUser: user, atIndexPath: indexPath)
            })
            actions.append(ActionSheetAction(title: Strings.Localizable.readAndWrite, detail: nil, accessoryView: activeShare == .accessReadWrite ? checkmarkImageView : nil, image: Asset.Images.SharedItems.readWritePermissions.image, style: .default) { [weak self] in
                self?.shareNode(withLevel: .accessReadWrite, forUser: user, atIndexPath: indexPath)
            })
            actions.append(ActionSheetAction(title: Strings.Localizable.readOnly, detail: nil, accessoryView: activeShare == .accessRead ? checkmarkImageView : nil, image: Asset.Images.SharedItems.readPermissions.image, style: .default) { [weak self] in
                self?.shareNode(withLevel: .accessRead, forUser: user, atIndexPath: indexPath)
            })
        }
        
        actions.append(ActionSheetAction(title: Strings.Localizable.remove, detail: nil, image: Asset.Images.NodeActions.delete.image, style: .destructive) { [weak self] in
            self?.shareNode(withLevel: .accessUnknown, forUser: user, atIndexPath: indexPath)
        })
        
        let permissionsActionSheet = ActionSheetViewController(actions: actions, headerTitle: isBackupNode ? nil : Strings.Localizable.permissions, dismissCompletion: nil, sender: cell.permissionsImageView)
        
        present(permissionsActionSheet, animated: true, completion: nil)
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
        cachedSections = sections()
        cachedDetailRows = detailRows()
        cachedInfoRows = infoRows()
    }

    private func showVerifyCredentials() {
        guard let navigationController else { return }

        viewModel?.openVerifyCredentials(
            from: navigationController,
            completion: { [weak self] in
                guard let self else { return }
                self.cachedInfoRows = self.infoRows()
                self.reloadData()
            }
        )
    }
    
    // MARK: - TableView Data Source

    private func sections() -> [NodeInfoTableViewSection] {
        var sections = [NodeInfoTableViewSection]()
        sections.append(.info)
        sections.append(.details)

        if !node.mnz_isInRubbishBin() {
            if sdk.accessLevel(for: node) == .accessOwner && !node.isTakenDown() {
                sections.append(.link)
            }
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
    
    // MARK: - TableView cells
    
    private func previewCell(forIndexPath indexPath: IndexPath) -> NodeInfoPreviewTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoPreviewCell", for: indexPath) as? NodeInfoPreviewTableViewCell else {
            fatalError("Could not get NodeInfoDetailTableViewCell")
        }
        
        cell.configure(forNode: node,
                       isNodeInRubbish: node.mnz_isInRubbishBin(),
                       folderInfo: folderInfo,
                       isUndecryptedFolder: viewModel?.isNodeUndecryptedFolder == true)
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
    
    private func addContactSharingCell(forIndexPath indexPath: IndexPath) -> ContactTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoContactCell", for: indexPath) as? ContactTableViewCell else {
            fatalError("Could not get ContactTableViewCell")
        }
        
        cell.backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        cell.permissionsImageView.isHidden = true
        cell.avatarImageView.image = Asset.Images.Chat.inviteToChat.image
        cell.nameLabel.text = Strings.Localizable.addContact
        cell.shareLabel.isHidden = true
        
        return cell
    }
    
    private func contactSharingCell(forIndexPath indexPath: IndexPath) -> ContactTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoContactCell", for: indexPath) as? ContactTableViewCell else {
            fatalError("Could not get ContactTableViewCell")
        }
        
        guard let user = sdk.contact(forEmail: cachedActiveShares[indexPath.row - 1].user) else {
            fatalError("Could not get MEGAUser for ContactTableViewCell")
        }
        
        cell.backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
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
        cell.permissionsImageView.image = UIImage.mnz_permissionsButtonImage(for: cachedActiveShares[indexPath.row - 1].access)

        return cell
    }
    
    private func pendingSharingCell(forIndexPath indexPath: IndexPath) -> ContactTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoContactCell", for: indexPath) as? ContactTableViewCell else {
            fatalError("Could not get ContactTableViewCell")
        }
        
        cell.backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        cell.avatarImageView.mnz_setImage(forUserHandle: MEGAInvalidHandle, name: cachedPendingShares[indexPath.row].user)
        cell.nameLabel.text = cachedPendingShares[indexPath.row].user
        cell.shareLabel.isHidden = true
        cell.permissionsImageView.isHidden = false
        cell.permissionsImageView.image = Asset.Images.NodeActions.delete.image
        
        return cell
    }
    
    private func removeSharingCell(forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoRemoveSharing", for: indexPath)
        
        cell.backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        guard let removeLabel = cell.viewWithTag(1) as? UILabel else {
            fatalError("Could not get RemoveLabel")
        }

        removeLabel.text = Strings.Localizable.removeShare
        
        return cell
    }
}

// MARK: - UITableViewDataSource

extension NodeInfoViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        let sectionCount = cachedSections.count
        return sectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch cachedSections[section] {
        case .info:
            return cachedInfoRows.count
        case .details:
            return cachedDetailRows.count
        case .sharing:
            return cachedActiveShares.count + 1
        case .pendingSharing:
            return cachedPendingShares.count
        case .link, .versions, .removeSharing:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
        }
    }
}

// MARK: - UITableViewDelegate

extension NodeInfoViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GenericHeaderFooterViewID") as? GenericHeaderFooterView else {
            return UIView(frame: .zero)
        }
        
        header.contentView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        
        switch cachedSections[section] {
        case .details:
            header.configure(title: Strings.Localizable.details, topDistance: 30.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .link:
            header.configure(title: Strings.Localizable.link, topDistance: 30.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .versions:
            header.configure(title: Strings.Localizable.versions.localizedUppercase, topDistance: 30.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .sharing:
            header.configure(title: Strings.Localizable.shareWith.localizedUppercase, topDistance: 30.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .pendingSharing:
            header.configure(title: Strings.Localizable.pending.localizedUppercase, topDistance: 30.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .removeSharing:
            header.configure(title: nil, topDistance: 30.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        default:
            header.configure(title: nil, topDistance: 0.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        }

        return header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GenericHeaderFooterViewID") as? GenericHeaderFooterView else {
            return UIView(frame: .zero)
        }
        footer.contentView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        footer.configure(title: nil, topDistance: 5.0, isTopSeparatorVisible: true, isBottomSeparatorVisible: false)
        
        return footer
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
                viewModel?.openSharedDialog()
            } else {
                prepareShareFolderPermissionsAlertController(fromIndexPat: indexPath)
            }
        case .pendingSharing:
            showAlertForRemovingPendingShare(forIndexPat: indexPath)
        case .info:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - MEGAGlobalDelegate

extension NodeInfoViewController: MEGAGlobalDelegate {
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let nodeList else { return }
            
        for nodeIndex in 0..<nodeList.size.intValue {
            guard let nodeUpdated = nodeList.node(at: nodeIndex) else {
                continue
            }
            
            if nodeUpdated.hasChangedType(.removed) {
                if nodeUpdated.handle == node.handle {
                    currentVersionRemoved()
                } else if nodeVersions.contains(where: { $0.handle == nodeUpdated.handle }) {
                    nodeVersionRemoved()
                }
                break
            }
            
            if nodeUpdated.hasChangedType(.parent) && nodeUpdated.handle == node.handle {
                guard let parentNode = sdk.node(forHandle: nodeUpdated.parentHandle) else { return }
                if parentNode.isFolder() { // Node moved
                    guard let newNode = sdk.node(forHandle: nodeUpdated.handle) else { return }
                    node = newNode
                } else { // Node versioned
                    guard let newNode = sdk.node(forHandle: nodeUpdated.parentHandle) else { return }
                    node = newNode
                }
            }
            
            if nodeUpdated.handle == node.handle {
                reloadOrShowWarningAfterActionOnNode()
                break
            }
        }
        
        cacheNodePropertiesSoThatTableViewChangesAreAtomic()
        reloadData()
    }
}
