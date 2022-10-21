
import UIKit
import MEGADomain

enum NodeInfoTableViewSection: Int {
    case info
    case details
    case link
    case versions
    case sharing
    case pendingSharing
    case removeSharing
}

enum InfoSectionRow: Int {
    case preview
    case owner
}

enum DetailsSectionRow: Int {
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
    private var folderInfo : MEGAFolderInfo?
    private weak var delegate: NodeInfoViewControllerDelegate?
    private var nodeVersions: [MEGANode] = []
    
    //MARK: - Lifecycle

    @objc class func instantiate(withNode node: MEGANode, delegate: NodeInfoViewControllerDelegate?) -> MEGANavigationController {
        guard let nodeInfoVC = UIStoryboard(name: "Node", bundle: nil).instantiateViewController(withIdentifier: "NodeInfoViewControllerID") as? NodeInfoViewController else {
            fatalError("Could not instantiate NodeInfoViewController")
        }

        nodeInfoVC.node = node
        nodeInfoVC.delegate = delegate
        nodeInfoVC.nodeVersions = node.mnz_versions()
        return MEGANavigationController.init(rootViewController: nodeInfoVC)
    }
    
    // MARK: - Public Interface
    func display(_ node: MEGANode, withDelegate delegate: NodeInfoViewControllerDelegate) {
        self.node = node
        self.delegate = delegate
    }

    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Localizable.info
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.Localizable.close, style: .plain, target: self, action: #selector(closeButtonTapped))
        
        MEGASdkManager.sharedMEGASdk().add(self)
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.register(UINib(nibName: "GenericHeaderFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "GenericHeaderFooterViewID")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if node.isFolder() {
            fetchFolderInfo()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
            tableView.reloadData()
        }
    }
    
    //MARK: - Private methods

    private func updateAppearance() {
        view.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        tableView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
    }
    
    private func fetchFolderInfo() {
        MEGASdkManager.sharedMEGASdk().getFolderInfo(for: node, delegate: MEGAGetFolderInfoRequestDelegate.init(completion: { [weak self] (request) in
            guard let folderInfo = request?.megaFolderInfo else {
                fatalError("Could not fetch MEGAFolderInfo")
            }
            self?.folderInfo = folderInfo
            
            guard let infoSectionIndex = self?.sections().firstIndex(of: .info), let detailsSectionIndex = self?.sections().firstIndex(of: .details) else {
                fatalError("Could not get Node Info sections to reload")
            }
            self?.tableView.reloadSections([infoSectionIndex, detailsSectionIndex], with: .automatic)
        }))
    }
    
    private func reloadOrShowWarningAfterActionOnNode() {
        guard let nodeUpdated = MEGASdkManager.sharedMEGASdk().node(forHandle: node.handle) else {
            let alertTitle = node.isFolder() ? Strings.Localizable.youNoLongerHaveAccessToThisFolderAlertTitle : Strings.Localizable.youNoLongerHaveAccessToThisFileAlertTitle
            
            let warningAlertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)
            warningAlertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default, handler: { _ in
                self.navigationController?.popViewController(animated: true)
            }))
            present(warningAlertController, animated: true, completion: nil)
            return
        }
        
        node = nodeUpdated
        tableView.reloadData()
    }
    
    private func showNodeVersions() {
        guard let nodeVersionsVC = storyboard?.instantiateViewController(withIdentifier: "NodeVersionsVC") as? NodeVersionsViewController else {
            fatalError("Could not instantiate NodeVersionsViewController")
        }
        nodeVersionsVC.node = node
        navigationController?.pushViewController(nodeVersionsVC, animated: true)
    }
    
    private func showParentNode() {
        if let parentNode = MEGASdkManager.sharedMEGASdk().parentNode(for: node) {
            MEGASdkManager.sharedMEGASdk().remove(self)
            dismiss(animated: true) {
                self.delegate?.nodeInfoViewController(self, presentParentNode: parentNode)
            }
        } else {
            MEGALogError("Unable to find parent node")
        }
    }
    
    private func showManageLinkView() {
        CopyrightWarningViewController.presentGetLinkViewController(for: [node], in: self)
    }
    
    private func showAddShareContactView() {
        BackupNodesValidator(presenter: self, nodes: [node.toNodeEntity()]).showWarningAlertIfNeeded() { [weak self] in
            guard let `self` = self, let contactsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsViewControllerID") as? ContactsViewController else {
                fatalError("Could not instantiate ContactsViewController")
            }
            contactsVC.contactsMode = .shareFoldersWith
            contactsVC.nodesArray = [self.node]
            let navigation = MEGANavigationController.init(rootViewController: contactsVC)
            self.present(navigation, animated: true, completion: nil)
        }
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        showAddShareContactView()
    }
    
    @objc private func closeButtonTapped() {
        MEGASdkManager.sharedMEGASdk().remove(self)
        dismiss(animated: true, completion: nil)
    }
    
    private func currentVersionRemoved() {
        guard let firstVersion = nodeVersions.first else {
            return
        }
        node = firstVersion
        nodeVersions = node.mnz_versions()
        tableView.reloadData()
    }
    
    private func nodeVersionRemoved() {
        nodeVersions = node.mnz_versions()
        
        if node.mnz_numberOfVersions() == 0 {
            tableView.reloadData()
        } else {
            guard let versionsSectionIndex = sections().firstIndex(of: .versions) else { return }
            tableView.reloadSections([versionsSectionIndex], with: .automatic)
        }
    }
    
    private func showAlertForRemovingPendingShare(forIndexPat indexPath: IndexPath) {
        guard let email = pendingOutShares()[indexPath.row].user else {
            MEGALogError("Could not fetch pending share email")
            return
        }
        
        let removePendingShareAlertController = UIAlertController(title: Strings.Localizable.removeUserTitle, message: email, preferredStyle: .alert)
        
        removePendingShareAlertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
        removePendingShareAlertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default, handler: { _ in
            MEGASdkManager.sharedMEGASdk().share(self.node, withEmail: email, level: MEGAShareType.accessUnknown.rawValue, delegate: MEGAShareRequestDelegate.init(toChangePermissionsWithNumberOfRequests: 1, completion: {
                
                guard let nodeUpdated = MEGASdkManager.sharedMEGASdk().node(forHandle: self.node.handle) else {
                    MEGALogError("Could not fetch updated Node")
                    return
                }
                self.node = nodeUpdated
                self.tableView.reloadData()
            }))
        }))
        
        present(removePendingShareAlertController, animated: true, completion: nil)
    }
    
    private func prepareShareFolderPermissionsAlertController(fromIndexPat indexPath: IndexPath) {
        let activeShare = activeOutShares()[indexPath.row - 1].access
        let checkmarkImageView = UIImageView(image: Asset.Images.Generic.turquoiseCheckmark.image)

        guard let cell = tableView.cellForRow(at: indexPath) as? ContactTableViewCell else {
            return
        }
        guard let user = MEGASdkManager.sharedMEGASdk().contact(forEmail: activeOutShares()[indexPath.row - 1].user) else {
            return
        }
        var actions = [ActionSheetAction]()
        let isInboxNode = InboxUseCase(inboxRepository: InboxRepository.newRepo, nodeRepository: NodeRepository.newRepo).isInboxNode(node.toNodeEntity())
        
        if !isInboxNode {
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
        
        let permissionsActionSheet = ActionSheetViewController(actions: actions, headerTitle: isInboxNode ? nil : Strings.Localizable.permissions, dismissCompletion: nil, sender: cell.permissionsImageView)
        
        present(permissionsActionSheet, animated: true, completion: nil)
    }
    
    private func shareNode(withLevel level: MEGAShareType, forUser user: MEGAUser, atIndexPath indexPath: IndexPath) {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
        MEGASdkManager.sharedMEGASdk().share(node, with: user, level: level.rawValue, delegate:
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
        return outShares.filter( { $0.isPending } )
    }
    
    private func activeOutShares() -> [MEGAShare] {
        guard let outShares = node.outShares() as? [MEGAShare] else {
            return []
        }
        return outShares.filter( { !$0.isPending } )
    }
    
    //MARK: - TableView Data Source

    private func sections() -> [NodeInfoTableViewSection] {
        var sections = [NodeInfoTableViewSection]()
        sections.append(.info)
        sections.append(.details)

        if !self.node.mnz_isInRubbishBin() {
            if MEGASdkManager.sharedMEGASdk().accessLevel(for: node) == .accessOwner && !node.isTakenDown() {
                sections.append(.link)
            }
            if node.isFolder() && MEGASdkManager.sharedMEGASdk().accessLevel(for: node) == .accessOwner {
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
        }
        return infoRows
    }
    
    private func detailRows() -> [DetailsSectionRow] {
        var detailRows = [DetailsSectionRow]()
        if MEGASdkManager.sharedMEGASdk().accessLevel(for: node) == .accessOwner {
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
    
    //MARK: - TableView cells
    
    private func previewCell(forIndexPath indexPath: IndexPath) -> NodeInfoPreviewTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoPreviewCell", for: indexPath) as? NodeInfoPreviewTableViewCell else {
            fatalError("Could not get NodeInfoDetailTableViewCell")
        }
        
        cell.configure(forNode: node, isNodeInRubbish: node.mnz_isInRubbishBin(), folderInfo: folderInfo)
        return cell
    }
    
    private func ownerCell(forIndexPath indexPath: IndexPath) -> NodeOwnerInfoTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeOwnerInfoTableViewCell", for: indexPath) as? NodeOwnerInfoTableViewCell else {
            fatalError("Could not get NodeInfoDetailTableViewCell")
        }
        
        if let user = MEGASdkManager.sharedMEGASdk().userFrom(inShare: node) {
            cell.configure(user: user)
        }
        
        return cell
    }
    
    private func detailCell(forIndexPath indexPath: IndexPath) -> NodeInfoDetailTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoDetailCell", for: indexPath) as? NodeInfoDetailTableViewCell else {
            fatalError("Could not get NodeInfoDetailTableViewCell")
        }
        
        cell.configure(forNode: node, rowType: detailRows()[indexPath.row], folderInfo: folderInfo)
        
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
        
        guard let user = MEGASdkManager.sharedMEGASdk().contact(forEmail: activeOutShares()[indexPath.row - 1].user) else {
            fatalError("Could not get MEGAUser for ContactTableViewCell")
        }
        
        cell.backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        cell.avatarImageView.mnz_setImage(forUserHandle: user.handle, name: user.mnz_displayName)
        cell.verifiedImageView.isHidden = !MEGASdkManager.sharedMEGASdk().areCredentialsVerified(of: user)
        if user.mnz_displayName != "" {
            cell.nameLabel.text = user.mnz_displayName
            cell.shareLabel.text = user.email
        } else {
            cell.nameLabel.text = user.email
            cell.shareLabel.isHidden = true
        }
        
        cell.permissionsImageView.isHidden = false
        cell.permissionsImageView.image = UIImage.mnz_permissionsButtonImage(for: activeOutShares()[indexPath.row - 1].access)

        return cell
    }
    
    private func pendingSharingCell(forIndexPath indexPath: IndexPath) -> ContactTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoContactCell", for: indexPath) as? ContactTableViewCell else {
            fatalError("Could not get ContactTableViewCell")
        }
        
        cell.backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        cell.avatarImageView.mnz_setImage(forUserHandle: MEGAInvalidHandle, name: pendingOutShares()[indexPath.row].user)
        cell.nameLabel.text = pendingOutShares()[indexPath.row].user
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
        return sections().count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections()[section] {
        case .info:
            return infoRows().count
        case .details:
            return detailRows().count
        case .sharing:
            return activeOutShares().count + 1
        case .pendingSharing:
            return pendingOutShares().count
        case .link, .versions, .removeSharing:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections()[indexPath.section] {
        case .info:
            switch infoRows()[indexPath.row] {
            case .preview:
                return previewCell(forIndexPath: indexPath)
            case .owner:
                return ownerCell(forIndexPath: indexPath)
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
        
        switch sections()[section] {
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
        switch sections()[indexPath.section] {
        case .details:
            switch detailRows()[indexPath.row] {
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
                showAddShareContactView()
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
        guard let nodeList = nodeList else {
            return
        }
        for nodeIndex in 0..<nodeList.size.intValue {
            guard let nodeUpdated = nodeList.node(at: nodeIndex) else {
                continue
            }
            
            if nodeUpdated.hasChangedType(.outShare) && nodeUpdated.handle == node.handle {
                guard let sharingSection = sections().firstIndex(of: .sharing) else { return }
                if nodeUpdated.outShares().count < tableView.numberOfRows(inSection: sharingSection) - 1 {
                    if nodeUpdated.outShares().count == 0 {
                        tableView.reloadData()
                    } else {
                        tableView.reloadSections([sharingSection], with: .automatic)
                    }
                }
            }
            
            if nodeUpdated.hasChangedType(.removed) {
                if nodeUpdated.handle == node.handle {
                    currentVersionRemoved()
                    break
                } else {
                    if nodeVersions.contains(where: { $0.handle == nodeUpdated.handle }) {
                        nodeVersionRemoved()
                    }
                    break
                }
            }
            
            if nodeUpdated.hasChangedType(.parent) {
                if nodeUpdated.handle == node.handle {
                    guard let parentNode = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeUpdated.parentHandle) else { return }
                    if parentNode.isFolder() { //Node moved
                        guard let newNode = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeUpdated.handle) else { return }
                        node = newNode
                    } else { //Node versioned
                        guard let newNode = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeUpdated.parentHandle) else { return }
                        node = newNode
                    }
                    tableView.reloadData()
                }
            }
            
            if nodeUpdated.handle == self.node.handle {
                self.reloadOrShowWarningAfterActionOnNode()
                break
            }
        }
    }
}
