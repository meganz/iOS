
import UIKit

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
    case offline
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
    func nodeInfo(_ nodeInfo: NodeInfoViewController, presentParentNode node: MEGANode)
}

class NodeInfoViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var node = MEGANode()
    private var folderInfo : MEGAFolderInfo?
    private weak var delegate: NodeInfoViewControllerDelegate?

    //MARK: - Lifecycle

    @objc class func instantiate(withNode node: MEGANode, delegate: NodeInfoViewControllerDelegate?) -> MEGANavigationController {
        guard let nodeInfoVC = UIStoryboard(name: "Node", bundle: nil).instantiateViewController(withIdentifier: "NodeInfoViewControllerID") as? NodeInfoViewController else {
            fatalError("Could not instantiate NodeInfoViewController")
        }

        nodeInfoVC.node = node
        nodeInfoVC.delegate = delegate
        
        return MEGANavigationController.init(rootViewController: nodeInfoVC)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = AMLocalizedString("info", "A button label. The button allows the user to get more info of the current context.")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: AMLocalizedString("close", "A button label. The button allows the user to close the conversation."), style: .plain, target: self, action: #selector(closeButtonTapped))
        
        MEGASdkManager.sharedMEGASdk().add(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchFolderInfo()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
                tableView.reloadData()
            }
        }
    }
    
    //MARK: - Private methods

    private func updateAppearance() {
        tableView.backgroundColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection)
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
            let alertTitle = node.isFolder() ? AMLocalizedString("youNoLongerHaveAccessToThisFolder_alertTitle", "Alert title shown when you are seeing the details of a folder and you are not able to access it anymore because it has been removed or moved from the shared folder where it used to be") : AMLocalizedString("youNoLongerHaveAccessToThisFile_alertTitle", "Alert title shown when you are seeing the details of a file and you are not able to access it anymore because it has been removed or moved from the shared folder where it used to be");
            
            let warningAlertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)
            warningAlertController.addAction(UIAlertAction(title: AMLocalizedString("ok", "Button title to accept something"), style: .default, handler: { _ in
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
                self.delegate?.nodeInfo(self, presentParentNode: parentNode)
            }
        } else {
            MEGALogError("Unable to find parent node")
        }
    }
    
    private func showManageLinkView() {
        CopyrightWarningViewController.presentGetLinkViewController(for: [node], in: self)
    }
    
    private func showAddShareContactView() {
        guard let contactsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsViewControllerID") as? ContactsViewController else {
            fatalError("Could not instantiate ContactsViewController")
        }
        contactsVC.contactsMode = .shareFoldersWith
        contactsVC.nodesArray = [node]
        let navigation = MEGANavigationController.init(rootViewController: contactsVC)
        present(navigation, animated: true, completion: nil)
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        showAddShareContactView()
    }
    
    @IBAction func offlineSwitchTapped(_ sender: UISwitch) {
        if sender.isOn { //Start download
            if let downloadImage = UIImage(named: "hudDownload") {
                SVProgressHUD.show(downloadImage, status: AMLocalizedString("downloadStarted", "Message shown when a download starts"))
            }
            node.mnz_downloadNodeOverwriting(false)
        } else {
            let nodePath = Helper.pathForOffline() + node.name
            if FileManager.default.fileExists(atPath: nodePath) {
                do { //Remove file and data base object if exist
                    try FileManager.default.removeItem(atPath: nodePath)
                    if let offlineNode = MEGAStore.shareInstance()?.offlineNode(with: node) {
                        MEGAStore.shareInstance()?.remove(offlineNode)
                    }
                } catch {
                    SVProgressHUD.showError(withStatus: "")
                }
            }
            
            if let transfers = MEGASdkManager.sharedMEGASdk().downloadTransfers.mnz_transfersArrayFromTranferList() { //Cancel transfer if it is in progress
                transfers.forEach { (transfer) in
                    if transfer.nodeHandle == node.handle {
                        MEGASdkManager.sharedMEGASdk().cancelTransfer(transfer)
                    }
                }
            }
        }
    }
    
    @objc private func closeButtonTapped() {
        MEGASdkManager.sharedMEGASdk().remove(self)
        dismiss(animated: true, completion: nil)
    }
    
    private func currentVersionRemoved() {
        if node.mnz_versions()?.count == 1 {
            dismiss(animated: true, completion: nil)
        } else {
            node = node.mnz_versions()[1]
            tableView.reloadData()
        }
    }
    
    private func showAlertForRemovingPendingShare(forIndexPat indexPath: IndexPath) {
        guard let email = pendingOutShares()[indexPath.row].user else {
            MEGALogError("Could not fetch pending share email")
            return
        }
        
        let removePendingShareAlertController = UIAlertController(title: AMLocalizedString("removeUserTitle", "Alert title shown when you want to remove one or more contacts"), message: email, preferredStyle: .alert)
        
        removePendingShareAlertController.addAction(UIAlertAction(title: AMLocalizedString("cancel", "Button title to cancel something"), style: .cancel, handler: nil))
        removePendingShareAlertController.addAction(UIAlertAction(title: AMLocalizedString("ok", nil), style: .default, handler: { _ in
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
        guard let cell = tableView.cellForRow(at: indexPath) as? ContactTableViewCell else {
            return
        }
        guard let user = MEGASdkManager.sharedMEGASdk().contact(forEmail: activeOutShares()[indexPath.row - 1].user) else {
            return
        }
        var actions = [ActionSheetAction]()

        actions.append(ActionSheetAction(title: AMLocalizedString("fullAccess", "Permissions given to the user you share your folder with"), detail: nil, image: UIImage(named: "fullAccessPermissions"), style: .default) { [weak self] in
            self?.shareNode(withLevel: .accessFull, forUser: user, atIndexPath: indexPath)
        })
        actions.append(ActionSheetAction(title: AMLocalizedString("readAndWrite", "Permissions given to the user you share your folder with"), detail: nil, image: UIImage(named: "readWritePermissions"), style: .default) { [weak self] in
            self?.shareNode(withLevel: .accessReadWrite, forUser: user, atIndexPath: indexPath)
        })
        actions.append(ActionSheetAction(title: AMLocalizedString("readOnly", "Permissions given to the user you share your folder with"), detail: nil, image: UIImage(named: "readPermissions"), style: .default) { [weak self] in
            self?.shareNode(withLevel: .accessRead, forUser: user, atIndexPath: indexPath)
        })
        
        let permissionsActionSheet = ActionSheetViewController(actions: actions, headerTitle: AMLocalizedString("permissions", "Title of the view that shows the kind of permissions (Read Only, Read & Write or Full Access) that you can give to a shared folder"), dismissCompletion: nil, sender: cell.permissionsImageView)
        
        present(permissionsActionSheet, animated: true, completion: nil)
    }
    
    private func shareNode(withLevel level: MEGAShareType, forUser user: MEGAUser, atIndexPath indexPath: IndexPath) {
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
        MEGASdkManager.sharedMEGASdk().share(node, with: user, level: level.rawValue, delegate: MEGAShareRequestDelegate.init(toChangePermissionsWithNumberOfRequests: 1, completion: { [weak self] in
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
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
        sections.append(.link)
        if MEGASdkManager.sharedMEGASdk().hasVersions(for: node) {
            sections.append(.versions)
        }

        if node.isFolder() && MEGASdkManager.sharedMEGASdk().accessLevel(for: node) == .accessOwner {
            sections.append(.sharing)
            if pendingOutShares().count > 0 {
                sections.append(.pendingSharing)
            }
            if activeOutShares().count > 0 {
                sections.append(.removeSharing)
            }
        }
        
        return sections
    }
    
    private func infoRows() -> [InfoSectionRow] {
        var infoRows = [InfoSectionRow]()
        infoRows.append(.preview)
        if node.isFile() {
            infoRows.append(.offline)
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
        
        cell.nameLabel.text = node.name;
        if (node.type == .file) {
            cell.previewImage.mnz_setThumbnail(by: node)
            cell.sizeLabel.text = Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk())
            cell.shareButton.isHidden = true
        } else if (node.type == .folder) {
            cell.previewImage.mnz_image(for: node)
        }
        
        return cell
    }
    
    private func offlineCell (forIndexPath indexPath: IndexPath) -> NodeInfoOfflineTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoOfflineCell", for: indexPath) as? NodeInfoOfflineTableViewCell else {
            fatalError("Could not get NodeInfoOfflineTableViewCell")
        }

        cell.titleLabel.text = AMLocalizedString("Available Offline", "Text indicating if a node is downloaded locally")
        cell.offlineSwitch.isOn = MEGAStore.shareInstance()?.offlineNode(with: node) != nil

        return cell
    }
    
    private func detailCell(forIndexPath indexPath: IndexPath) -> NodeInfoDetailTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoDetailCell", for: indexPath) as? NodeInfoDetailTableViewCell else {
            fatalError("Could not get NodeInfoDetailTableViewCell")
        }
        
        cell.valueLabel.textColor = UIColor.mnz_label()

        switch detailRows()[indexPath.row] {
        case .location:
            cell.keyLabel.text = AMLocalizedString("location", "Title label of a node property.")
            cell.valueLabel.text = MEGASdkManager.sharedMEGASdk().parentNode(for: node)?.name
            cell.valueLabel.textColor = UIColor.mnz_turquoise(for: traitCollection)
        case .fileSize:
            cell.keyLabel.text = AMLocalizedString("totalSize", "Size of the file or folder you are sharing")
            cell.valueLabel.text = node.mnz_numberOfVersions() == 0 ? Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk()) : Helper.memoryStyleString(fromByteCount: node.mnz_versionsSize())
        case .currentFileVersionSize:
            cell.keyLabel.text = AMLocalizedString("currentVersion", "Title of section to display information of the current version of a file")
            cell.valueLabel.text = Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk())
        case .fileType:
            cell.keyLabel.text = AMLocalizedString("type", "Refers to the type of a file or folder.")
            cell.valueLabel.text = node.mnz_fileType()
        case .folderSize:
            cell.keyLabel.text = AMLocalizedString("totalSize", "Size of the file or folder you are sharing")
            cell.valueLabel.text = Helper.memoryStyleString(fromByteCount: (folderInfo?.currentSize ?? 0) + (folderInfo?.versionsSize ?? 0))
        case .currentFolderVersionsSize:
            cell.keyLabel.text = AMLocalizedString("currentVersions", "Title of section to display information of all current versions of files.")
            cell.valueLabel.text = Helper.memoryStyleString(fromByteCount: folderInfo?.currentSize ?? 0)
        case .previousFolderVersionsSize:
            cell.keyLabel.text = AMLocalizedString("previousVersions", "A button label which opens a dialog to display the full version history of the selected file.")
            cell.valueLabel.text = Helper.memoryStyleString(fromByteCount: folderInfo?.versionsSize ?? 0)
        case .countVersions:
            cell.keyLabel.text = AMLocalizedString("versions", "Title of section to display number of all historical versions of files")
            guard let versions = folderInfo?.versions else {
                fatalError("Could not get versions from folder info")
            }
            cell.valueLabel.text = String(versions)
        case .contains:
            cell.keyLabel.text = AMLocalizedString("contains", "Label for what a selection contains.")
            cell.valueLabel.text = NSString.mnz_string(byFiles: folderInfo?.files ?? 0, andFolders: folderInfo?.folders ?? 0)
        case .addedDate:
            cell.keyLabel.text = AMLocalizedString("Added", "A label for any ‘Added’ text or title. For example to show the upload date of a file/folder.")
            cell.valueLabel.text = (node.creationTime as NSDate).mnz_formattedDefaultDateForMedia()
        case .modificationDate:
            cell.keyLabel.text = AMLocalizedString("modified", "A label for any 'Modified' text or title.")
            cell.valueLabel.text = (node.modificationTime as NSDate).mnz_formattedDefaultDateForMedia()
        case .linkCreationDate:
            cell.keyLabel.text = AMLocalizedString("Link Creation", "Text referencing the date of creation of a link")
            cell.valueLabel.text = (node.modificationTime as NSDate).mnz_formattedDefaultDateForMedia()
        }
        return cell
    }
    
    private func linkCell(forIndexPath indexPath: IndexPath) -> NodeInfoActionTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoActionCell", for: indexPath) as? NodeInfoActionTableViewCell else {
            fatalError("Could not get NodeInfoActionTableViewCell")
        }
        
        cell.iconImageView.image = UIImage(named: "link")
        cell.iconImageView.tintColor = UIColor.mnz_primaryGray(for: self.traitCollection)
        if self.node.isExported() {
            cell.titleLabel.text = AMLocalizedString("manageLink", "Item menu option upon right click on one or multiple files.")
        } else {
            cell.titleLabel.text = AMLocalizedString("getLink", "Title shown under the action that allows you to get a link to file or folder")
        }
        cell.subtitleLabel.isHidden = true
        cell.separatorView.backgroundColor = UIColor.mnz_separator(for: self.traitCollection)
        cell.separatorView.isHidden = true
        
        return cell;
    }
    
    private func versionsCell(forIndexPath indexPath: IndexPath) -> NodeInfoActionTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoActionCell", for: indexPath) as? NodeInfoActionTableViewCell else {
            fatalError("Could not get NodeInfoActionTableViewCell")
        }
        
        cell.iconImageView.image = UIImage(named: "versions")
        cell.iconImageView.tintColor = UIColor.mnz_primaryGray(for: self.traitCollection)
        cell.titleLabel.text = AMLocalizedString("versions", "Title of section to display number of all historical versions of files.")
        cell.subtitleLabel.text = String(node.mnz_numberOfVersions())
        cell.subtitleLabel.isHidden = false
        cell.separatorView.backgroundColor = UIColor.mnz_separator(for: self.traitCollection)
        cell.separatorView.isHidden = true
        cell.accessoryType = .disclosureIndicator
        
        return cell;
    }
    
    private func addContactSharingCell(forIndexPath indexPath: IndexPath) -> ContactTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoContactCell", for: indexPath) as? ContactTableViewCell else {
            fatalError("Could not get ContactTableViewCell")
        }
        
        cell.permissionsImageView.isHidden = true
        cell.avatarImageView.image = UIImage(named: "inviteToChat")
        cell.nameLabel.text = AMLocalizedString("addContactButton", "Button title to 'Add' the contact to your contacts list")
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
        
        cell.avatarImageView.mnz_setImage(forUserHandle: MEGAInvalidHandle, name: pendingOutShares()[indexPath.row].user)
        cell.nameLabel.text = pendingOutShares()[indexPath.row].user
        cell.shareLabel.isHidden = true
        cell.permissionsImageView.isHidden = false
        cell.permissionsImageView.image = UIImage(named: "delete")
        
        return cell
    }
    
    private func removeSharingCell(forIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nodeInfoRemoveSharing", for: indexPath)
        
        guard let removeLabel = cell.viewWithTag(1) as? UILabel else {
            fatalError("Could not get RemoveLabel")
        }

        removeLabel.text = AMLocalizedString("removeSharing", "Alert title shown on the Shared Items section when you want to remove 1 share")
        
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
            case .offline:
                return offlineCell(forIndexPath: indexPath)
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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections()[indexPath.section] {
        case .details:
            return 33
        case .link, .versions, .removeSharing:
            return 44
        case .sharing, .pendingSharing:
            return 60
        case .info:
            switch infoRows()[indexPath.row] {
            case .preview:
                return 230
            case .offline:
                return 44
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections()[section] {
        case .details, .link, .versions, .sharing, .pendingSharing:
            return 58
        case .removeSharing:
            return 38
        case .info:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 2
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableCell(withIdentifier: "nodeInfoTableHeader") as? NodeInfoHeaderTableViewCell else {
            fatalError("Could not get NodeInfoHeaderTableViewCell")
        }
        
        header.contentView.backgroundColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection)
        header.titleLabel.textColor = UIColor.mnz_secondaryGray(for: traitCollection)
        
        switch sections()[section] {
        case .details:
            header.titleLabel.text = AMLocalizedString("DETAILS", "ext used for a title or header listing the details of something.")
        case .link:
            header.titleLabel.text = AMLocalizedString("LINK", "Text used as title or header for reference an url, for instance, a node link.")
        case .versions:
            header.titleLabel.text = AMLocalizedString("VERSIONS", "Text used as title or header to display number of all historical versions of files.")
        case .sharing:
            header.titleLabel.text = AMLocalizedString("SHARE WITH", "Text used for a title or header to list users whom you are sharing something.")
        case .pendingSharing:
            header.titleLabel.text = AMLocalizedString("PENDING", "Text used for a title or header to list pending users whom you are sharing something.")
        case .removeSharing, .info:
            header.titleLabel.text = ""
        }

        header.separatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        
        return header.contentView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = tableView.dequeueReusableCell(withIdentifier: "nodeInfoTableFooter")
        footer?.contentView.backgroundColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection)
        
        guard let separator = footer?.viewWithTag(2) else {
            return footer
        }
        separator.backgroundColor = UIColor.mnz_separator(for: traitCollection)

        return footer?.contentView
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
            
            if nodeUpdated.hasChangedType(.removed) {
                if nodeUpdated.handle == node.handle {
                    currentVersionRemoved()
                    break
                } else {
                    if node.mnz_numberOfVersions() > 1 {
                        guard let versionsSectionIndex = sections().firstIndex(of: .versions) else { return }
                        tableView.reloadSections([versionsSectionIndex], with: .automatic)
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
                self.reloadOrShowWarningAfterActionOnNode();
                break
            }
        }
    }
}
