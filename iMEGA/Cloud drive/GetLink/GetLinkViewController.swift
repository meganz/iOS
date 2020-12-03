import UIKit

enum GetLinkTableViewSection: Int {
    case info
    case decryptKeySeparate
    case expiryDate
    case passwordProtection
    case link
    case key
}

enum ExpiryDateSectionRow {
    case activateExpiryDate
    case configureExpiryDate
    case pickExpiryDate
}

enum PasswordProtectionSectionRow {
    case configurePasword
}

enum LinkSectionRow {
    case link
    case password
    case removePassword
}

enum KeySectionRow {
    case key
}

struct GetLinkViewModel {
    var link: String = ""
    var separateKey: Bool = false
    var linkWithoutKey: String {
        if link.contains("file") || link.contains("folder") {
            return link.components(separatedBy: "#")[0]
        } else {
            return link.components(separatedBy: "!")[0] + "!" + link.components(separatedBy: "!")[1]
        }
    }
    var key: String {
        get {
            if link.contains("file") || link.contains("folder") {
                return link.components(separatedBy: "#")[1]
            } else {
                return link.components(separatedBy: "!")[2]
            }
        }
    }
    var expiryDate: Bool = false
    var date: Date?
    var selectDate: Bool = false
    var passwordProtect: Bool = false
    var password: String?
    var multilink: Bool = false
}

class GetLinkViewController: UIViewController {
    
    private lazy var dateFormatter = DateFormatter.dateMedium()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var multilinkDescriptionLabel: UILabel!
    @IBOutlet weak var multilinkDescriptionView: UIView!
    @IBOutlet weak var multilinkDescriptionStackView: UIStackView!
    @IBOutlet private var shareBarButton: UIBarButtonItem!
    @IBOutlet private var copyLinkBarButton: UIBarButtonItem!
    @IBOutlet private var copyKeyBarButton: UIBarButtonItem!
    
    let flexibleBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    
    private var nodes = [MEGANode]()
    private var getLinkVM = GetLinkViewModel()
    private var nodesToExportCount = 0
    
    @objc class func instantiate(withNodes nodes: [MEGANode]) -> MEGANavigationController {
        guard let getLinkVC = UIStoryboard(name: "GetLink", bundle: nil).instantiateViewController(withIdentifier: "GetLinksViewControllerID") as? GetLinkViewController else {
            fatalError("Could not instantiate GetLinkViewController")
        }
        
        getLinkVC.nodes = nodes
        getLinkVC.getLinkVM.multilink = nodes.count > 1
        
        return MEGANavigationController.init(rootViewController: getLinkVC)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigation()
        
        tableView.register(UINib(nibName: "GenericHeaderFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "GenericHeaderFooterViewID")
        
        if getLinkVM.multilink {
            multilinkDescriptionLabel.text = NSLocalizedString("Options such as Send Decryption Key Separately, Set Expiry Date or Passwords are only available for single items.", comment: "Description text about options when exporting links for several nodes")
            multilinkDescriptionView.isHidden = false
        } else {
            tableView.isUserInteractionEnabled = false
        }
        
        processNodes()
        
        shareBarButton.title = NSLocalizedString("share", comment: "")
        copyLinkBarButton.title = getLinkVM.multilink ? NSLocalizedString("Copy All", comment: "") : NSLocalizedString("copyLink", comment: "")
        copyKeyBarButton.title = NSLocalizedString("copyKey", comment: "")
        
        updateAppearance()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
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
    
    //MARK: - Private
    
    private func configureNavigation() {
        navigationController?.setToolbarHidden(false, animated: true)
        
        if getLinkVM.multilink {
            title = nodes.filter { !$0.isExported() }.count == 0 ? NSLocalizedString("manageLinks", comment: "A menu item in the right click context menu in the Cloud Drive. This menu item will take the user to a dialog where they can manage the public folder/file links which they currently have selected.") : NSLocalizedString("getLinks",comment:  "Title shown under the action that allows you to get several links to files and/or folders")
        } else {
            title = nodes[0].isExported() ? NSLocalizedString("manageLink", comment: "A menu item in the right click context menu in the Cloud Drive. This menu item will take the user to a dialog where they can manage the public folder/file links which they currently have selected.") : NSLocalizedString("getLink", comment: "Title shown under the action that allows you to get a link to file or folder")
        }
        
        setToolbarItems([shareBarButton, flexibleBarButton, copyLinkBarButton], animated: true)
        let doneBarButtonItem = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .done, target: self, action: #selector(doneBarButtonTapped))
        navigationItem.rightBarButtonItem = doneBarButtonItem
    }
    
    private func updateAppearance() {
        tableView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        multilinkDescriptionStackView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
    }
    
    private func configureDecryptKeySeparate(isOn: Bool) {
        getLinkVM.separateKey = isOn
        tableView.reloadData()
        if getLinkVM.separateKey {
            setToolbarItems([shareBarButton, flexibleBarButton, copyKeyBarButton, flexibleBarButton, copyLinkBarButton], animated: true)
        } else {
            setToolbarItems([shareBarButton, flexibleBarButton, copyLinkBarButton], animated: true)
        }
    }
    
    private func configureExpiryDate(isOn: Bool) {
        getLinkVM.expiryDate = isOn
        if !getLinkVM.expiryDate && getLinkVM.date != nil {
            nodesToExportCount = 1
            exportNode(node: nodes[0])
        }
        getLinkVM.date = nil
        getLinkVM.selectDate = false
        guard let expiryDateSection = sections().firstIndex(of: .expiryDate), let linkSection = sections().firstIndex(of: .link) else { return }
        tableView.reloadSections([expiryDateSection, linkSection], with: .automatic)
    }
    
    private func copyKeyToPasteBoard() {
        guard let copyImage = UIImage(named: "copy") else { return }
        UIPasteboard.general.string = getLinkVM.key
        SVProgressHUD.show(copyImage, status: NSLocalizedString("Key Copied to Clipboard", comment: "Message shown when the key has been copied to the Clipboard"))
    }
    
    private func copyLinkToPasteboard(atIndex index: Int?) {
        guard let copyImage = UIImage(named: "copy") else { return }
        if getLinkVM.multilink {
            if let index = index {
                UIPasteboard.general.string = nodes[index].publicLink
                SVProgressHUD.show(copyImage, status: NSLocalizedString("Link Copied to Clipboard", comment: "Message shown when the link has been copied to the Clipboard"))
            } else {
                UIPasteboard.general.string = nodes.map { $0.publicLink }.joined(separator: " ")
                SVProgressHUD.show(copyImage, status: NSLocalizedString("Links Copied to Clipboard", comment: "Message shown when the links have been copied to the Clipboard"))
            }
        } else {
            if getLinkVM.separateKey {
                UIPasteboard.general.string = getLinkVM.linkWithoutKey
            } else {
                UIPasteboard.general.string = getLinkVM.link
            }
            SVProgressHUD.show(copyImage, status: NSLocalizedString("Link Copied to Clipboard", comment: "Message shown when the link has been copied to the Clipboard"))
        }
    }
    
    private func copyPasswordToPasteboard() {
        guard let copyImage = UIImage(named: "copy") else { return }
        UIPasteboard.general.string = getLinkVM.password
        SVProgressHUD.show(copyImage, status: NSLocalizedString("Password Copied to Clipboard", comment: "Message shown when the password has been copied to the Clipboard"))
    }
    
    private func updateModel(forNode node: MEGANode) {
        guard let index = nodes.firstIndex(where: { $0.handle == node.handle } ) else { return }
        nodes[index] = node
        if getLinkVM.multilink {
            tableView.reloadSections([index], with: .automatic)
        } else {
            var sectionsToReload = IndexSet()
            
            if getLinkVM.link.isEmpty {
                getLinkVM.link = node.publicLink
                guard let linkSection = sections().firstIndex(of: .link) else {
                    return
                }
                sectionsToReload.insert(linkSection)
            }
            
            if node.expirationTime > 0 {
                getLinkVM.expiryDate = true
                getLinkVM.date = Date(timeIntervalSince1970: TimeInterval(node.expirationTime))
            }
            
            if !getLinkVM.link.isEmpty {
                tableView.isUserInteractionEnabled = true
            }
            
            guard let expiryDateSection = sections().firstIndex(of: .expiryDate) else {
                return
            }
            sectionsToReload.insert(expiryDateSection)
            
            tableView.reloadSections(sectionsToReload, with: .automatic)
        }
    }
    
    private func processNodes() {
        nodesToExportCount = nodes.filter { !$0.isExported() }.count
        nodes.forEach { (node) in
            if node.isExported() {
                updateModel(forNode: node)
            } else {
                exportNode(node: node)
            }
        }
    }
    
    private func exportNode(node: MEGANode) {
        MEGASdkManager.sharedMEGASdk().export(node, delegate: MEGAExportRequestDelegate.init(completion: { [weak self] (request) in
            (self?.nodesToExportCount -= 1)
            if self?.nodesToExportCount == 0 {
                SVProgressHUD.dismiss()
            }
            guard let nodeUpdated = MEGASdkManager.sharedMEGASdk().node(forHandle: node.handle) else {
                return
            }
            self?.updateModel(forNode: nodeUpdated)
            }, multipleLinks: nodesToExportCount > 1))
    }
    
    @objc private func learnMoreTapped() {
        guard let decryptionKeyVC = storyboard?.instantiateViewController(withIdentifier: "DecryptionKeysViewControllerID") else {
            return
        }
        let decryptionKeyNavigation = MEGANavigationController.init(rootViewController: decryptionKeyVC)
        present(decryptionKeyNavigation, animated: true, completion: nil)
    }
    
    @objc private func doneBarButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func sections() -> [GetLinkTableViewSection] {
        var sections = [GetLinkTableViewSection]()
        
        sections.append(.info)
        sections.append(.decryptKeySeparate)
        sections.append(.expiryDate)
        sections.append(.passwordProtection)
        sections.append(.link)
        if getLinkVM.separateKey {
            sections.append(.key)
        }
        
        return sections
    }
    
    private func expireDateRows() -> [ExpiryDateSectionRow] {
        var expireDateRows = [ExpiryDateSectionRow]()
        expireDateRows.append(.activateExpiryDate)
        if getLinkVM.expiryDate {
            expireDateRows.append(.configureExpiryDate)
        }
        if getLinkVM.selectDate {
            expireDateRows.append(.pickExpiryDate)
        }
        return expireDateRows
    }
    
    private func passwordProtectionRows() -> [PasswordProtectionSectionRow] {
        return [.configurePasword]
    }
    
    private func linkRows() -> [LinkSectionRow] {
        var linkRows = [LinkSectionRow]()
        linkRows.append(.link)
        if getLinkVM.passwordProtect && getLinkVM.password != nil {
            linkRows.append(.password)
            linkRows.append(.removePassword)
        }
        return linkRows
    }
    
    private func keyRows() -> [KeySectionRow] {
        var keyRows = [KeySectionRow]()
        keyRows.append(.key)
        return keyRows
    }
    
    private func encrypt(link: String, with password: String) {
        MEGASdkManager.sharedMEGASdk().encryptLink(withPassword: link, password: password, delegate: MEGAPasswordLinkRequestDelegate.init(completion: {(request) in
            SVProgressHUD.dismiss()
            guard let encryptedLink = request?.text else {
                return
            }
            self.getLinkVM.link = encryptedLink
            self.getLinkVM.password = password
            self.getLinkVM.passwordProtect = true
            self.configureDecryptKeySeparate(isOn: false)
            
            guard let linkSection = self.sections().firstIndex(of: .link), let expiryDateSection = self.sections().firstIndex(of: .expiryDate) else {
                return
            }
            self.tableView.reloadSections([linkSection, expiryDateSection], with: .automatic)
        }, multipleLinks: false))
    }
    
    private func setExpiryDate() {
        MEGASdkManager.sharedMEGASdk().export(nodes[0], expireTime: getLinkVM.date ?? Date(timeInterval: 24*60*60, since: Date()), delegate: MEGAExportRequestDelegate.init(completion: { [weak self] (request) in
            guard let nodeUpdated = MEGASdkManager.sharedMEGASdk().node(forHandle: self?.nodes[0].handle ?? MEGAInvalidHandle) else {
                return
            }
            
            if self?.getLinkVM.passwordProtect ?? false, let password = self?.getLinkVM.password {
                self?.encrypt(link: nodeUpdated.publicLink, with: password)
            } else {
                SVProgressHUD.dismiss()
                self?.updateModel(forNode: nodeUpdated)
            }
        }, multipleLinks: false))
    }
    
    //MARK: - IBActions
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        guard let point = sender.superview?.convert(sender.center, to: tableView), let indexPath = tableView.indexPathForRow(at: point) else { return }
        
        switch sections()[indexPath.section] {
        case .decryptKeySeparate:
            configureDecryptKeySeparate(isOn: sender.isOn)
        case .expiryDate:
            configureExpiryDate(isOn: sender.isOn)
        default:
            break
        }
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        getLinkVM.date = sender.date
        guard let expiryDateSection = sections().firstIndex(of: .expiryDate) else { return }
        tableView.reloadSections([expiryDateSection], with: .automatic)
    }
    
    @IBAction func shareBarButtonTapped(_ sender: UIBarButtonItem) {
        let textToShare = getLinkVM.multilink ? nodes.map { $0.publicLink }.joined(separator: "\n") : getLinkVM.separateKey ? getLinkVM.linkWithoutKey : getLinkVM.link
        let shareActivity = UIActivityViewController(activityItems: [textToShare], applicationActivities: [SendToChatActivity(text: textToShare)])
        shareActivity.excludedActivityTypes = [.print, .assignToContact, .saveToCameraRoll, .addToReadingList, .airDrop]
        shareActivity.popoverPresentationController?.barButtonItem = sender
        shareActivity.completionWithItemsHandler = {activity, _, _, _ in
            if activity?.rawValue == MEGAUIActivityTypeSendToChat {
                shareActivity.dismissView()
            }
        }
        present(shareActivity, animated: true, completion: nil)
    }
    
    @IBAction func copyKeyBarButtonTapped(_ sender: UIBarButtonItem) {
        copyKeyToPasteBoard()
    }
    
    @IBAction func copyLinkBarButtonTapped(_ sender: UIBarButtonItem) {
        copyLinkToPasteboard(atIndex: nil)
    }
    
    //MARK: - TableView cells
    
    private func infoCell(forIndexPath indexPath: IndexPath) -> GetLinkInfoTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkInfoTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkInfoTableViewCell else {
            fatalError("Could not get GetLinkInfoTableViewCell")
        }
        
        cell.configure(forNode: nodes[indexPath.section])
        
        return cell
    }
    
    private func decryptKeySeparateCell(forIndexPath indexPath: IndexPath) -> GetLinkSwitchOptionTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkSwitchOptionTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkSwitchOptionTableViewCell else {
            fatalError("Could not get GetLinkSwitchOptionTableViewCell")
        }
        
        cell.configureDecryptKeySeparatedCell(isOn: getLinkVM.separateKey, enabled: !getLinkVM.passwordProtect)
        
        return cell
    }
    
    private func activateExpiryDateCell(forIndexPath indexPath: IndexPath) -> GetLinkSwitchOptionTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkSwitchOptionTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkSwitchOptionTableViewCell else {
            fatalError("Could not get GetLinkSwitchOptionTableViewCell")
        }
        
        cell.configureActivateExpiryDateCell(isOn: getLinkVM.expiryDate, enabled: MEGASdkManager.sharedMEGASdk().mnz_isProAccount)
        
        return cell
    }
    
    private func configureExpiryDateCell(forIndexPath indexPath: IndexPath) -> GetLinkDetailTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkDetailTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkDetailTableViewCell else {
            fatalError("Could not get GetLinkDetailTableViewCell")
        }
        
        cell.configureExpiryDateCell(date: getLinkVM.date, dateSelected: getLinkVM.selectDate)
        
        return cell
    }
    
    private func pickExpiryDateCell(forIndexPath indexPath: IndexPath) -> GetLinkDatePickerTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkDatePickerTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkDatePickerTableViewCell else {
            fatalError("Could not get GetLinkDatePickerTableViewCell")
        }
        
        cell.configureDatePickerCell(date: getLinkVM.date)
        
        return cell
    }
    
    private func configurePasswordCell(forIndexPath indexPath: IndexPath) -> GetLinkDetailTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkDetailTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkDetailTableViewCell else {
            fatalError("Could not get GetLinkDetailTableViewCell")
        }
        
        cell.configurePasswordCell(passwordActive: getLinkVM.passwordProtect, enabled: MEGASdkManager.sharedMEGASdk().mnz_isProAccount)
        
        return cell
    }
    
    private func linkCell(forIndexPath indexPath: IndexPath) -> GetLinkStringTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkStringTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkStringTableViewCell else {
            fatalError("Could not get GetLinkStringTableViewCell")
        }
        
        if getLinkVM.multilink {
            cell.configureLinkCell(link: nodes[indexPath.section].isExported() ? nodes[indexPath.section].publicLink : "")
        } else {
            if getLinkVM.separateKey {
                cell.configureLinkCell(link: getLinkVM.linkWithoutKey)
            } else {
                cell.configureLinkCell(link: getLinkVM.link)
            }
        }
        
        return cell
    }
    
    private func passwordCell(forIndexPath indexPath: IndexPath) -> GetLinkPasswordTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkPasswordTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkPasswordTableViewCell else {
            fatalError("Could not get GetLinkPasswordTableViewCell")
        }
        
        cell.configurePasswordCell(password: getLinkVM.password ?? "")
        
        return cell
    }
    
    private func keyCell(forIndexPath indexPath: IndexPath) -> GetLinkStringTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkStringTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkStringTableViewCell else {
            fatalError("Could not get GetLinkStringTableViewCell")
        }
        
        cell.configureKeyCell(key: getLinkVM.key)
        
        return cell
    }
    
    private func removePasswordCell(forIndexPath indexPath: IndexPath) -> GetLinkDetailTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkDetailTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkDetailTableViewCell else {
            fatalError("Could not get GetLinkDetailTableViewCell")
        }
        
        cell.configureRemovePasswordCell()
        
        return cell
    }
    
}

//MARK: - UITableViewDataSource

extension GetLinkViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if getLinkVM.multilink {
            return nodes.count
        } else {
            return sections().count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if getLinkVM.multilink {
            return 2
        } else {
            switch sections()[section] {
            case .info, .decryptKeySeparate:
                return 1
            case .expiryDate:
                return expireDateRows().count
            case .passwordProtection:
                return passwordProtectionRows().count
            case .link:
                return linkRows().count
            case .key:
                return keyRows().count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if getLinkVM.multilink {
            if indexPath.row == 0 {
                return infoCell(forIndexPath: indexPath)
            } else {
                return linkCell(forIndexPath: indexPath)
            }
        } else {
            switch sections()[indexPath.section] {
            case .info:
                return infoCell(forIndexPath: indexPath)
            case .decryptKeySeparate:
                return decryptKeySeparateCell(forIndexPath: indexPath)
            case .expiryDate:
                switch expireDateRows()[indexPath.row] {
                case .activateExpiryDate:
                    return activateExpiryDateCell(forIndexPath: indexPath)
                case .configureExpiryDate:
                    return configureExpiryDateCell(forIndexPath: indexPath)
                case .pickExpiryDate:
                    return pickExpiryDateCell(forIndexPath: indexPath)
                }
            case .passwordProtection:
                switch passwordProtectionRows()[indexPath.row] {
                case .configurePasword:
                    return configurePasswordCell(forIndexPath: indexPath)
                }
            case .link:
                switch linkRows()[indexPath.row] {
                case .link:
                    return linkCell(forIndexPath: indexPath)
                case .password:
                    return passwordCell(forIndexPath: indexPath)
                case .removePassword:
                    return removePasswordCell(forIndexPath: indexPath)
                }
            case .key:
                return keyCell(forIndexPath: indexPath)
            }
        }
    }
}

//MARK: - UITableViewDelegate

extension GetLinkViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if getLinkVM.multilink {
            if indexPath.row == 0 {
                return 60
            } else {
                return 44
            }
        } else {
            if sections()[indexPath.section] == .info {
                return 60
            } else if sections()[indexPath.section] == .expiryDate && expireDateRows()[indexPath.row] == .pickExpiryDate {
                if #available(iOS 14.0, *) {
                    return 60
                } else {
                    return 160
                }
            } else {
                return 44
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if getLinkVM.multilink {
            if section == 0 {
                return 38
            } else {
                return 0
            }
        } else {
            switch sections()[section] {
            case .link, .key:
                return 38
            case .expiryDate:
                return 20
            case .passwordProtection:
                if getLinkVM.expiryDate && !getLinkVM.selectDate && (getLinkVM.date != nil) {
                    return 20
                } else {
                    return 0
                }
            default:
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if getLinkVM.multilink {
            return 25
        } else {
            switch sections()[section] {
            case .decryptKeySeparate:
                return 38
            default:
                return 25
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GenericHeaderFooterViewID") as? GenericHeaderFooterView else {
            return UIView(frame: .zero)
        }
        
        header.contentView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        header.bottomSeparatorView.isHidden = false
        
        if getLinkVM.multilink {
            header.titleLabel.text = NSLocalizedString("LINK", comment: "Text presenting a link as header usually")
            header.topSeparatorView.isHidden = true
        } else {
            switch sections()[section] {
            case .link:
                header.titleLabel.text = NSLocalizedString("LINK", comment: "Text presenting a link as header usually")
                header.topSeparatorView.isHidden = true
            case .key:
                header.titleLabel.text = NSLocalizedString("KEY", comment: "Text presenting a key (for a LINK or similar) as header usually")
                header.topSeparatorView.isHidden = true
            case .expiryDate:
                header.titleLabel.text = ""
                header.topSeparatorView.isHidden = true
            case .passwordProtection:
                header.titleLabel.text = ""
                header.topSeparatorView.isHidden = getLinkVM.expiryDate && !getLinkVM.selectDate && (getLinkVM.date != nil)
            default:
                header.titleLabel.text = ""
            }
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GenericHeaderFooterViewID") as? GenericHeaderFooterView else {
            return UIView(frame: .zero)
        }
        
        footer.contentView.backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
        footer.topSeparatorView.isHidden = false
        footer.titleLabel.text = ""
        
        if getLinkVM.multilink {
            if section == nodes.count - 1 {
                footer.titleLabel.text = NSLocalizedString("Tap to Copy", comment: "Text hint to let the user know that tapping something will be copied into the pasteboard")
                footer.titleLabel.textAlignment = .center
                footer.bottomSeparatorView.isHidden = true
            }
        } else {
            switch sections()[section] {
            case .decryptKeySeparate:
                footer.bottomSeparatorView.isHidden = true
                let attributedString = NSMutableAttributedString(string: NSLocalizedString("Export the link and decryption key separately.", comment: "Hint text for option separate the key from the link in Get Link View"))
                let learnMoreString = NSAttributedString(string: " " + NSLocalizedString("Learn more", comment: "Label for any ‘Learn more’ button, link, text, title, etc. - (String as short as possible)."), attributes: [NSAttributedString.Key.foregroundColor: UIColor.mnz_turquoise(for: traitCollection) as Any])
                attributedString.append(learnMoreString)
                footer.titleLabel.numberOfLines = 2
                footer.titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(learnMoreTapped)))
                footer.titleLabel.isUserInteractionEnabled = true
                footer.titleLabel.attributedText = attributedString
            case .expiryDate:
                if getLinkVM.expiryDate && !getLinkVM.selectDate && (getLinkVM.date != nil) {
                    footer.titleLabel.text = String(format: NSLocalizedString("Link expires %@", comment: "Text indicating the date until a link will be valid"), dateFormatter.localisedString(from: getLinkVM.date ?? Date()))
                }
                footer.bottomSeparatorView.isHidden = getLinkVM.expiryDate && !getLinkVM.selectDate && (getLinkVM.date != nil)
            case .link, .passwordProtection, .key:
                footer.bottomSeparatorView.isHidden = true
            case .info:
                footer.bottomSeparatorView.isHidden = false
            }
        }
        return footer
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if getLinkVM.multilink {
            if indexPath.row == 1 {
                copyLinkToPasteboard(atIndex: indexPath.section)
            }
        } else {
            switch sections()[indexPath.section] {
            case .info, .decryptKeySeparate:
                break
            case .expiryDate:
                switch expireDateRows()[indexPath.row] {
                case .activateExpiryDate, .pickExpiryDate:
                    break
                case .configureExpiryDate:
                    if getLinkVM.selectDate {
                        setExpiryDate()
                    }
                    getLinkVM.selectDate = !getLinkVM.selectDate
                    guard let expiryDateSection = sections().firstIndex(of: .expiryDate) else { return }
                    tableView.reloadSections([expiryDateSection], with: .automatic)
                }
            case .passwordProtection:
                switch passwordProtectionRows()[indexPath.row] {
                case .configurePasword:
                    if MEGASdkManager.sharedMEGASdk().mnz_isProAccount {
                        present(SetLinkPasswordViewController.instantiate(withDelegate: self), animated: true, completion: nil)
                    }
                }
            case .link:
                switch linkRows()[indexPath.row] {
                case .link:
                    copyLinkToPasteboard(atIndex: nil)
                case .password:
                    copyPasswordToPasteboard()
                case .removePassword:
                    getLinkVM.passwordProtect = false
                    getLinkVM.password = nil
                    getLinkVM.link = nodes[0].publicLink
                    tableView.reloadData()
                }
                break
            case .key:
                copyKeyToPasteBoard()
            }
        
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

//MARK: - SetLinkPasswordViewControllerDelegate

extension GetLinkViewController: SetLinkPasswordViewControllerDelegate {
    func setLinkPassword(_ setLinkPassword: SetLinkPasswordViewController, password: String) {
        setLinkPassword.dismissView()
        encrypt(link: nodes[0].publicLink, with: password)
    }
    
    func setLinkPasswordCanceled(_ setLinkPassword: SetLinkPasswordViewController) {
        setLinkPassword.dismissView()
    }
}
