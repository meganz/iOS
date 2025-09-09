import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAFoundation
import MEGAL10n
import MEGASwiftUI
import UIKit

enum GetLinkTableViewSection: Int {
    case info
    case linkAccessInfo
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

class GetLinkViewController: UIViewController {
    
    private lazy var dateFormatter: some DateFormatting = DateFormatter.dateMedium()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var multilinkDescriptionLabel: UILabel!
    @IBOutlet weak var multilinkDescriptionView: UIView!
    @IBOutlet weak var multilinkDescriptionStackView: UIStackView!
    @IBOutlet private var shareBarButton: UIBarButtonItem!
    @IBOutlet private var copyLinkBarButton: UIBarButtonItem!
    @IBOutlet private var copyKeyBarButton: UIBarButtonItem!
    
    let flexibleBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    
    private var getLinkVM = GetNodeLinkViewModel(shareUseCase: ShareUseCase(
        shareRepository: ShareRepository.newRepo,
        filesSearchRepository: FilesSearchRepository.newRepo,
        nodeRepository: NodeRepository.newRepo))
    private var nodesToExportCount = 0
    private var justUpgradedToProAccount = false
    private var isLinkAlreadyCreated = false
    private var defaultDateStored = false
    
    private var getLinkViewModel: (any GetLinkViewModelType)?
    
    @objc class func instantiate(withNodes nodes: [MEGANode]) -> MEGANavigationController {
        guard let getLinkVC = UIStoryboard(name: "GetLink", bundle: nil).instantiateViewController(withIdentifier: "GetLinksViewControllerID") as? GetLinkViewController else {
            fatalError("Could not instantiate GetLinkViewController")
        }
        
        getLinkVC.getLinkVM.nodes = nodes
        
        return MEGANavigationController(rootViewController: getLinkVC)
    }
    
    class func instantiate(viewModel: any GetLinkViewModelType) -> MEGANavigationController {
        guard let getLinkVC = UIStoryboard(name: "GetLink", bundle: nil).instantiateViewController(withIdentifier: "GetLinksViewControllerID") as? GetLinkViewController else {
            fatalError("Could not instantiate GetLinkViewController")
        }
        
        getLinkVC.getLinkViewModel = viewModel
        
        return MEGANavigationController(rootViewController: getLinkVC)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "GenericHeaderFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "GenericHeaderFooterViewID")
        
        copyKeyBarButton.title = Strings.Localizable.copyKey
        
        if var getLinkViewModel {
            let doneBarButtonItem = UIBarButtonItem(title: Strings.Localizable.done, style: .done, target: self, action: #selector(doneBarButtonTapped))
            navigationItem.rightBarButtonItem = doneBarButtonItem
            
            getLinkViewModel.invokeCommand = { [weak self] command in
                self?.executeCommand(command)
            }
            
            getLinkViewModel.dispatch(.onViewReady)
        } else {
            loadNodes()
        }
        
        configureNavigation()
        setupColors()
        tableView.sectionHeaderTopPadding = 0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let getLinkViewModel {
            getLinkViewModel.dispatch(.onViewDidAppear)
        } else {
            getLinkVM.dispatch(.onViewDidAppear)
        }
    }
    
    private func loadNodes() {
        if !MEGASdk.shared.mnz_isProAccount {
            MEGASdk.shared.add(self as any MEGARequestDelegate)
            
            MEGAPurchase.sharedInstance()?.purchaseDelegateMutableArray.add(self)
            MEGAPurchase.sharedInstance()?.restoreDelegateMutableArray.add(self)
        }
        
        getLinkVM.invokeCommand = executeCommand(_:)
        
        getLinkVM.dispatch(.onViewReady)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SVProgressHUD.dismiss()
        
        if isMovingFromParent && !MEGASdk.shared.mnz_isProAccount {
            removeDelegates()
        }
        
        if let getLinkViewModel {
            getLinkViewModel.dispatch(.onViewWillDisappear)
        }
        
        NotificationCenter.default.post(name: Notification.Name.MEGAShareCreated, object: nil)
    }
    
    // MARK: - Private
    
    private func configureNavigation() {
        let doneBarButtonItem = UIBarButtonItem(title: Strings.Localizable.done, style: .done, target: self, action: #selector(doneBarButtonTapped))
        navigationItem.rightBarButtonItem = doneBarButtonItem
    }
    
    private func setupColors() {
        tableView.backgroundColor = TokenColors.Background.page
        multilinkDescriptionStackView.backgroundColor = TokenColors.Background.page
    }
    
    private func configureDecryptKeySeparate(isOn: Bool) {
        getLinkVM.separateKey = isOn
        tableView.reloadData()
        configureToolbarItems(isDecryptionKeySeperate: isOn)
    }
    
    private func configureToolbarItems(isDecryptionKeySeperate: Bool) {
        if isDecryptionKeySeperate {
            setToolbarItems([shareBarButton, flexibleBarButton, copyKeyBarButton, flexibleBarButton, copyLinkBarButton], animated: true)
        } else {
            setToolbarItems([shareBarButton, flexibleBarButton, copyLinkBarButton], animated: true)
        }
    }
    
    private func configureExpiryDate(isOn: Bool) {
        getLinkVM.expiryDate = isOn
        if !getLinkVM.expiryDate && getLinkVM.date != nil {
            nodesToExportCount = 1
            exportNode(node: getLinkVM.nodes[0])
        }
        getLinkVM.date = nil
        getLinkVM.selectDate = false
        guard let expiryDateSection = sections().firstIndex(of: .expiryDate), let linkSection = sections().firstIndex(of: .link) else { return }
        tableView.reloadSections([expiryDateSection, linkSection], with: .automatic)
    }
    
    private func copyKeyToPasteBoard() {
        UIPasteboard.general.string = getLinkVM.key
        showCopySuccessSnackBar(with: Strings.Localizable.keyCopiedToClipboard)
    }
    
    private func copyLinkToPasteboard(
        atIndex index: Int? = nil,
        isFromLinkCellTap: Bool = false
    ) {
        
        let nodes = getLinkVM.nodes
        
        if getLinkVM.isMultiLink {
            if let index = index, let link = nodes[safe: index]?.publicLink {
                UIPasteboard.general.string = link
            } else {
                UIPasteboard.general.string = nodes.compactMap { $0.publicLink }.joined(separator: " ")
            }
        } else {
            if getLinkVM.separateKey {
                UIPasteboard.general.string = getLinkVM.linkWithoutKey
            } else {
                UIPasteboard.general.string = getLinkVM.link
            }
        }
        
        if isLinkAlreadyCreated {
            showCopySuccessSnackBar(with: Strings.Localizable.SharedItems.GetLink.linkCopied(isFromLinkCellTap ? 1 : nodes.count))
        } else {
            showCopySuccessSnackBar(with: Strings.Localizable.SharedItems.GetLink.linkCreatedAndCopied(nodes.count))
            isLinkAlreadyCreated = true
        }
    }
    
    private func copyPasswordToPasteboard() {
        UIPasteboard.general.string = getLinkVM.password
        showCopySuccessSnackBar(with: Strings.Localizable.passwordCopiedToClipboard)
    }
    
    private func showCopySuccessSnackBar(with message: String) {
        showSnackBar(snackBar: SnackBar(message: message))
    }
    
    private func updateModel(forNode node: MEGANode) {
        guard let index = getLinkVM.nodes.firstIndex(where: { $0.handle == node.handle }) else { return }
        getLinkVM.nodes[index] = node
        if getLinkVM.isMultiLink {
            tableView.reloadSections([index+1], with: .automatic)
        } else {
            var sectionsToReload = IndexSet()
            
            if getLinkVM.link.isEmpty {
                getLinkVM.link = node.publicLink ?? ""
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
        nodesToExportCount = getLinkVM.nodes.filter { !$0.isExported() }.count
        isLinkAlreadyCreated = nodesToExportCount == 0
        getLinkVM.nodes.forEach { (node) in
            if node.isExported() {
                updateModel(forNode: node)
                copyLinkToPasteboard()
            } else {
                exportNode(node: node)
            }
        }
    }
    
    private func exportNode(node: MEGANode) {
        MEGASdk.shared.export(node, delegate: MEGAExportRequestDelegate.init(completion: { [weak self] _ in
            guard let self,
                let nodeUpdated = MEGASdk.shared.node(forHandle: node.handle) else {
                return
            }
            nodesToExportCount -= 1
            
            updateModel(forNode: nodeUpdated)
            if nodesToExportCount <= 0 {
                copyLinkToPasteboard()
                SVProgressHUD.dismiss()
            }
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
        sections.append(.linkAccessInfo)
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
        MEGASdk.shared.encryptLink(withPassword: link, password: password, delegate: MEGAPasswordLinkRequestDelegate.init(completion: {(request) in
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
        MEGASdk.shared.export(getLinkVM.nodes[0], expireTime: getLinkVM.date ?? Date(timeInterval: 24*60*60, since: Date()), delegate: MEGAExportRequestDelegate.init(completion: { [weak self] request in
            guard let nodeHandle = request?.nodeHandle, let nodeUpdated = MEGASdk.shared.node(forHandle: nodeHandle) else {
                return
            }
            SVProgressHUD.dismiss()
            self?.updateModel(forNode: nodeUpdated)
        }, multipleLinks: false))
    }
    
    private func showIncompleteShareLinkAlert(title: String, message: String, completion: @escaping (() -> Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.Localizable.dismiss, style: .default, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: Strings.Localizable.General.share, style: .default, handler: { _ in
            completion()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func showShareActivity(_ sender: UIBarButtonItem, textToShare: String, completion: (() -> Void)?) {
        let shareActivity = UIActivityViewController(activityItems: [textToShare], applicationActivities: [SendToChatActivity(text: textToShare)])
        shareActivity.excludedActivityTypes = [.print, .assignToContact, .saveToCameraRoll, .addToReadingList, .airDrop]
        shareActivity.popoverPresentationController?.barButtonItem = sender
        shareActivity.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                guard let completion = completion else { return }
                completion()
            }
        }
        present(shareActivity, animated: true, completion: nil)
    }
    
    private func showUpgradeToProCustomModalAlert() {
        let upgradeToProCustomModalAlert = CustomModalAlertViewController()
        upgradeToProCustomModalAlert.configureUpgradeToPro(
            onConfirm: { [weak self] in
                self?.getLinkVM.trackProFeatureSeePlans()
            },
            onCancel: { [weak self] in
                self?.getLinkVM.trackProFeatureNotNow()
            }
        )
        
        UIApplication.mnz_presentingViewController().present(upgradeToProCustomModalAlert, animated: true, completion: nil)
    }
    
    private func reloadProSections() {
        guard let expiryDateSection = sections().firstIndex(of: .expiryDate), expiryDateSection < tableView.numberOfSections,
              let passwordSection = sections().firstIndex(of: .passwordProtection), passwordSection < tableView.numberOfSections
        else {
            return
        }
        
        tableView.reloadSections([expiryDateSection, passwordSection], with: .automatic)
    }
    
    private func removeDelegates() {
        MEGASdk.shared.remove(self as any MEGARequestDelegate)
        
        MEGAPurchase.sharedInstance()?.purchaseDelegateMutableArray.remove(self)
        MEGAPurchase.sharedInstance()?.restoreDelegateMutableArray.remove(self)
    }
    
    private func update(expiryDate: Date, shouldCreateLink: Bool) {
        getLinkVM.date = expiryDate
        guard let expiryDateSection = sections().firstIndex(of: .expiryDate) else { return }
        if shouldCreateLink {
            setExpiryDate()
        }
        tableView.reloadSections([expiryDateSection], with: .automatic)
    }
    
    private func showAlert(alertModel: AlertModel) {
        present(UIAlertController(model: alertModel), animated: true)
    }
    
    // MARK: - IBActions
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        guard let point = sender.superview?.convert(sender.center, to: tableView),
              let indexPath = tableView.indexPathForRow(at: point)
        else {
            return
        }
        
        if let getLinkViewModel {
            getLinkViewModel.dispatch(.switchToggled(indexPath: indexPath, isOn: sender.isOn))
            return
        }
        
        switch sections()[indexPath.section] {
        case .decryptKeySeparate:
            configureDecryptKeySeparate(isOn: sender.isOn)
        case .expiryDate:
            if justUpgradedToProAccount {
                // Activity indicators are shown until the updated account details are received
                return
            }
            
            if MEGASdk.shared.mnz_isProAccount {
                configureExpiryDate(isOn: sender.isOn)
            } else {
                showUpgradeToProCustomModalAlert()
                sender.isOn = false
            }
        default:
            break
        }
    }
    
    @IBAction func datePickerEditingBeginEnd(_ sender: UIDatePicker) {
        if getLinkVM.date == nil {
            update(expiryDate: sender.date, shouldCreateLink: false)
            defaultDateStored = true
        }
    }
    
    @IBAction func datePickerEditingDidEnd(_ sender: UIDatePicker) {
        if defaultDateStored {
            setExpiryDate()
            defaultDateStored = false
        }
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        defaultDateStored = false
        update(expiryDate: sender.date, shouldCreateLink: true)
    }
    
    @IBAction func shareBarButtonTapped(_ sender: UIBarButtonItem) {
        if let getLinkViewModel {
            getLinkViewModel.dispatch(.shareLink(sender: sender))
            return
        }
        let textToShare = getLinkVM.isMultiLink ? getLinkVM.nodes.compactMap { $0.publicLink }.joined(separator: "\n") : getLinkVM.separateKey ? getLinkVM.linkWithoutKey : getLinkVM.link
        
        showShareActivity(sender, textToShare: textToShare) { [weak self] in
            if self?.getLinkVM.separateKey ?? false {
                self?.showIncompleteShareLinkAlert(title: Strings.Localizable.decryptionKey, message: Strings.Localizable.ThisLinkWasSharedWithoutADecryptionKey.doYouWantToShareItsKey.localizedCapitalized) {
                    guard let key = self?.getLinkVM.key else {
                        return
                    }
                    self?.showShareActivity(sender, textToShare: key, completion: nil)
                }
            }
            
            if self?.getLinkVM.passwordProtect ?? false {
                self?.showIncompleteShareLinkAlert(title: Strings.Localizable.linkPassword, message: Strings.Localizable.doYouWantToShareThePasswordForThisLink) {
                    guard let password = self?.getLinkVM.password else {
                        return
                    }
                    self?.showShareActivity(sender, textToShare: password, completion: nil)
                }
            }
        }
    }
    
    @IBAction func copyKeyBarButtonTapped(_ sender: UIBarButtonItem) {
        if let getLinkViewModel {
            getLinkViewModel.dispatch(.copyKey)
        } else {
            copyKeyToPasteBoard()
        }
    }
    
    // CC-8410 - When copy share link for video playlist should use SnackBar instead of HUD
    @IBAction func copyLinkBarButtonTapped(_ sender: UIBarButtonItem) {
        if let getLinkViewModel {
            getLinkViewModel.dispatch(.copyLink)
        } else {
            copyLinkToPasteboard(atIndex: nil)
        }
    }
    
    // MARK: - DesignToken
    private func setBackgroundColorWithDesignToken(on cell: UITableViewCell) {
        cell.backgroundColor = TokenColors.Background.page
    }
    
    // MARK: - TableView cells
    
    private func infoCell(forIndexPath indexPath: IndexPath, cellViewModel: GetLinkAlbumInfoCellViewModel? = nil) -> GetLinkInfoTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkInfoTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkInfoTableViewCell else {
            fatalError("Could not get GetLinkInfoTableViewCell")
        }
        if let cellViewModel {
            cell.viewModel = cellViewModel
        } else {
            let sectionIndex = getLinkVM.isMultiLink ? indexPath.section - 1 : indexPath.section
            cell.configure(forNode: getLinkVM.nodes[sectionIndex])
        }
        
        setBackgroundColorWithDesignToken(on: cell)
        
        return cell
    }
    
    private func linkAccessInfoCell(forIndexPath indexPath: IndexPath) -> GetLinkAccessInfoTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkAccessInfoTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkAccessInfoTableViewCell else {
            fatalError("Could not get GetLinkAccessInfoTableViewCell")
        }
        
        cell.configure(
            nodesCount: getLinkVM.nodes.count,
            isPasswordSet: getLinkVM.passwordProtect)
        
        setBackgroundColorWithDesignToken(on: cell)
        
        return cell
    }
    
    private func decryptKeySeparateCell(forIndexPath indexPath: IndexPath) -> GetLinkSwitchOptionTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkSwitchOptionTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkSwitchOptionTableViewCell else {
            fatalError("Could not get GetLinkSwitchOptionTableViewCell")
        }
        
        cell.configureDecryptKeySeparatedCell(isOn: getLinkVM.separateKey, enabled: !getLinkVM.passwordProtect)
        
        setBackgroundColorWithDesignToken(on: cell)
        
        return cell
    }
    
    private func activateExpiryDateCell(forIndexPath indexPath: IndexPath) -> GetLinkSwitchOptionTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkSwitchOptionTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkSwitchOptionTableViewCell else {
            fatalError("Could not get GetLinkSwitchOptionTableViewCell")
        }
        
        cell.configureActivateExpiryDateCell(isOn: getLinkVM.expiryDate, isPro: MEGASdk.shared.mnz_isProAccount, justUpgraded: justUpgradedToProAccount)
        
        setBackgroundColorWithDesignToken(on: cell)
        
        return cell
    }
    
    private func configureExpiryDateCell(forIndexPath indexPath: IndexPath) -> GetLinkDetailTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkDetailTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkDetailTableViewCell else {
            fatalError("Could not get GetLinkDetailTableViewCell")
        }
        
        cell.configureExpiryDateCell(date: getLinkVM.date, dateSelected: getLinkVM.selectDate)
        
        setBackgroundColorWithDesignToken(on: cell)
        
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
        
        cell.configurePasswordCell(passwordActive: getLinkVM.passwordProtect, isPro: MEGASdk.shared.mnz_isProAccount, justUpgraded: justUpgradedToProAccount)
        
        setBackgroundColorWithDesignToken(on: cell)
        
        return cell
    }
    
    private func linkCell(forIndexPath indexPath: IndexPath, cellViewModel: GetLinkStringCellViewModel? = nil) -> GetLinkStringTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkStringTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkStringTableViewCell else {
            fatalError("Could not get GetLinkStringTableViewCell")
        }
        
        if let cellViewModel {
            cell.viewModel = cellViewModel
            return cell
        }
        
        if getLinkVM.isMultiLink {
            let node = getLinkVM.nodes[indexPath.section-1]
            let publicLink = node.publicLink ?? ""
            cell.configureLinkCell(link: node.isExported() ? publicLink : "")
        } else {
            if getLinkVM.separateKey {
                cell.configureLinkCell(link: getLinkVM.linkWithoutKey)
            } else {
                cell.configureLinkCell(link: getLinkVM.link)
            }
        }
        
        setBackgroundColorWithDesignToken(on: cell)
        
        return cell
    }
    
    private func passwordCell(forIndexPath indexPath: IndexPath) -> GetLinkPasswordTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkPasswordTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkPasswordTableViewCell else {
            fatalError("Could not get GetLinkPasswordTableViewCell")
        }
        
        cell.configurePasswordCell(password: getLinkVM.password ?? "")
        
        setBackgroundColorWithDesignToken(on: cell)
        
        return cell
    }
    
    private func keyCell(forIndexPath indexPath: IndexPath) -> GetLinkStringTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkStringTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkStringTableViewCell else {
            fatalError("Could not get GetLinkStringTableViewCell")
        }
        
        cell.configureKeyCell(key: getLinkVM.key)
        
        setBackgroundColorWithDesignToken(on: cell)
        
        return cell
    }
    
    private func removePasswordCell(forIndexPath indexPath: IndexPath) -> GetLinkDetailTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkDetailTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkDetailTableViewCell else {
            fatalError("Could not get GetLinkDetailTableViewCell")
        }
        
        cell.configureRemovePasswordCell()
        
        setBackgroundColorWithDesignToken(on: cell)
        
        return cell
    }
    
    private func switchOptionCell(forIndexPath indexPath: IndexPath, cellViewModel: GetLinkSwitchOptionCellViewModel) -> GetLinkSwitchOptionTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkSwitchOptionTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkSwitchOptionTableViewCell else {
            fatalError("Could not get GetLinkSwitchOptionTableViewCell")
        }
        
        cell.configure(viewModel: cellViewModel)
        setBackgroundColorWithDesignToken(on: cell)
        
        return cell
    }
    
    private func linkStringCell(forIndexPath indexPath: IndexPath, cellViewModel: GetLinkStringCellViewModel) -> GetLinkStringTableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: GetLinkStringTableViewCell.reuseIdentifier, for: indexPath) as? GetLinkStringTableViewCell else {
            fatalError("Could not get GetLinkStringTableViewCell")
        }
        cell.viewModel = cellViewModel
        setBackgroundColorWithDesignToken(on: cell)
        
        return cell
    }
    
    @MainActor
    private func executeCommand(_ command: GetLinkViewModelCommand) {
        switch command {
        case .processNodes:
            processNodes()
        case .configureView(let newTitle, let isMultiLink, let shareButtonTitle):
            title = newTitle
            configureMultiLink(isMultiLink: isMultiLink)
            shareBarButton.title = shareButtonTitle
        case .enableLinkActions:
            tableView.isUserInteractionEnabled = true
            navigationController?.setToolbarHidden(false, animated: true)
            setToolbarItems([shareBarButton, flexibleBarButton, copyLinkBarButton], animated: true)
        case .reloadSections(let sections):
            tableView.reloadSections(sections, with: .automatic)
        case .reloadRows(let indexPaths):
            tableView.reloadRows(at: indexPaths, with: .automatic)
        case .deleteSections(let sections):
            tableView.beginUpdates()
            tableView.deleteSections(sections, with: .none)
            tableView.endUpdates()
        case .insertSections(let sections):
            tableView.beginUpdates()
            tableView.insertSections(sections, with: .none)
            tableView.endUpdates()
        case .configureToolbar(let isDecryptionKeySeperate):
            configureToolbarItems(isDecryptionKeySeperate: isDecryptionKeySeperate)
        case .showHud(let messageType):
            switch messageType {
            case .status(let status):
                SVProgressHUD.show(withStatus: status)
            case .custom(let image, let status):
                SVProgressHUD.show(image, status: status)
            }
        case .dismissHud:
            SVProgressHUD.dismiss()
        case .addToPasteBoard(let value):
            UIPasteboard.general.string = value
        case .showShareActivity(let sender, let link, let key):
            showShareActivity(sender, textToShare: link) { [weak self] in
                guard let self else { return }
                if let key {
                    showIncompleteShareLinkAlert(title: Strings.Localizable.decryptionKey, message: Strings.Localizable.ThisLinkWasSharedWithoutADecryptionKey.doYouWantToShareItsKey.localizedCapitalized) {
                        self.showShareActivity(sender, textToShare: key, completion: nil)
                    }
                }
            }
        case .hideMultiLinkDescription:
            multilinkDescriptionView.isHidden = true
        case .showAlert(let alertModel):
            showAlert(alertModel: alertModel)
        case .dismiss:
            dismiss(animated: true, completion: nil)
        }
    }
    
    private func configureMultiLink(isMultiLink: Bool) {
        copyLinkBarButton.title = isMultiLink ? Strings.Localizable.copyAll : Strings.Localizable.copyLink
        if isMultiLink {
            multilinkDescriptionLabel.text = Strings.Localizable.optionsSuchAsSendDecryptionKeySeparatelySetExpiryDateOrPasswordsAreOnlyAvailableForSingleItems
            multilinkDescriptionView.isHidden = false
        } else {
            tableView.isUserInteractionEnabled = false
        }
    }
    
    private func updateHeaderViewForSingleItem(forHeader header: inout GenericHeaderFooterView, forSection sectionType: GetLinkTableViewSection) {
        switch sectionType {
        case .link:
            header.configure(title: Strings.Localizable.link, color: TokenColors.Text.secondary, topDistance: 17, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .key:
            header.configure(title: Strings.Localizable.key, color: TokenColors.Text.secondary, topDistance: 17, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .decryptKeySeparate:
            header.configure(title: nil, topDistance: 10.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .expiryDate:
            header.configure(title: nil, topDistance: 17.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .passwordProtection:
            header.configure(title: nil, topDistance: 10.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        case .linkAccessInfo:
            header.configure(title: nil, topDistance: 16.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        default:
            header.configure(title: nil, topDistance: 0.0, isTopSeparatorVisible: false, isBottomSeparatorVisible: true)
        }
    }
    
    private func updateHeaderViewForMultiAlbumlink(forHeader header: inout GenericHeaderFooterView, forSection section: Int) {
        header.titleLabel.textAlignment = .left
        header.configure(
            title: Strings.Localizable.link,
            topDistance: section == 0 ? 17.0 : 25.0, isTopSeparatorVisible: false,
            isBottomSeparatorVisible: true
        )
    }
    
    private func updateHeaderViewForAlbum(forHeader header: inout GenericHeaderFooterView, forSection section: Int) {
        guard let getLinkViewModel, let sectionType = getLinkViewModel.sectionType(forSection: section) else { return }
        
        if getLinkViewModel.isMultiLink {
            updateHeaderViewForMultiAlbumlink(forHeader: &header, forSection: section)
        } else {
            updateHeaderViewForSingleItem(forHeader: &header, forSection: sectionType)
        }
    }
    
    private func updateFooterViewForSingleItem(forFooter footer: inout GenericHeaderFooterView, forSection sectionType: GetLinkTableViewSection) {
        switch sectionType {
        case .decryptKeySeparate:
            let foregroundColor = TokenColors.Link.primary
            let attributedString = NSMutableAttributedString(string: Strings.Localizable.exportTheLinkAndDecryptionKeySeparately, attributes: [NSAttributedString.Key.foregroundColor: TokenColors.Text.secondary as Any])
            let learnMoreString = NSAttributedString(string: " " + Strings.Localizable.learnMore, attributes: [NSAttributedString.Key.foregroundColor: foregroundColor as Any])
            attributedString.append(learnMoreString)
            footer.titleLabel.numberOfLines = 0
            footer.titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(learnMoreTapped)))
            footer.titleLabel.isUserInteractionEnabled = true
            footer.configure(attributedTitle: attributedString, topDistance: 4.0, isTopSeparatorVisible: true, isBottomSeparatorVisible: false)
        case .expiryDate:
            if getLinkVM.expiryDate && !getLinkVM.selectDate && (getLinkVM.date != nil) {
                let attributedString = NSMutableAttributedString(string: Strings.Localizable.linkExpires(dateFormatter.localisedString(from: getLinkVM.date ?? Date())), attributes: [NSAttributedString.Key.foregroundColor: TokenColors.Text.secondary as Any])
                footer.configure(attributedTitle: attributedString, topDistance: 4.0, isTopSeparatorVisible: true, isBottomSeparatorVisible: false)
            } else {
                footer.configure(title: nil, topDistance: 0.0, isTopSeparatorVisible: true, isBottomSeparatorVisible: false)
            }
        case .link, .key, .info, .passwordProtection, .linkAccessInfo:
            footer.configure(title: nil, topDistance: 0.0, isTopSeparatorVisible: true, isBottomSeparatorVisible: false)
        }
    }
    
    private func updateFooterViewForMultiItem(forFooter footer: inout GenericHeaderFooterView, forSection section: Int) {
        footer.titleLabel.textAlignment = .center
        footer.configure(
            title: Strings.Localizable.tapToCopy,
            color: TokenColors.Text.secondary,
            topDistance: 4,
            isTopSeparatorVisible: true,
            isBottomSeparatorVisible: false
        )
    }
    
    private func updateFooterViewForAlbum(forFooter footer: inout GenericHeaderFooterView, forSection section: Int) {
        guard let getLinkViewModel, let sectionType = getLinkViewModel.sectionType(forSection: section) else { return }
        
        if getLinkViewModel.isMultiLink {
            updateFooterViewForMultiItem(forFooter: &footer, forSection: section)
        } else {
            updateFooterViewForSingleItem(forFooter: &footer, forSection: sectionType)
        }
    }
}

// MARK: - UITableViewDataSource

extension GetLinkViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if let getLinkViewModel {
            return getLinkViewModel.numberOfSections
        }
        if getLinkVM.isMultiLink {
            return getLinkVM.nodes.count + 1
        } else {
            return sections().count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let getLinkViewModel {
            return getLinkViewModel.numberOfRowsInSection(section)
        }
        if getLinkVM.isMultiLink {
            return section == 0 ? 1 : 2
        } else {
            switch sections()[section] {
            case .info, .decryptKeySeparate, .linkAccessInfo:
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
        if let getLinkViewModel {
            switch getLinkViewModel.cellViewModel(indexPath: indexPath) {
            case let cellViewModel as GetLinkAlbumInfoCellViewModel:
                return infoCell(forIndexPath: indexPath, cellViewModel: cellViewModel)
            case let cellViewModel as GetLinkSwitchOptionCellViewModel:
                return switchOptionCell(forIndexPath: indexPath, cellViewModel: cellViewModel)
            case let cellViewModel as GetLinkStringCellViewModel:
                return linkStringCell(forIndexPath: indexPath, cellViewModel: cellViewModel)
            case _ as GetLinkAccessInfoCellViewModel:
                return linkAccessInfoCell(forIndexPath: indexPath)
            default:
                return UITableViewCell()
            }
        }
        
        if getLinkVM.isMultiLink {
            if indexPath.section == 0 && indexPath.row == 0 {
                return linkAccessInfoCell(forIndexPath: indexPath)
            } else {
                if indexPath.row == 0 {
                    return infoCell(forIndexPath: indexPath)
                } else {
                    return linkCell(forIndexPath: indexPath)
                }
            }
        } else {
            switch sections()[indexPath.section] {
            case .info:
                return infoCell(forIndexPath: indexPath)
            case .linkAccessInfo:
                return linkAccessInfoCell(forIndexPath: indexPath)
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

// MARK: - UITableViewDelegate

extension GetLinkViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard var header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GenericHeaderFooterViewID") as? GenericHeaderFooterView else {
            return UIView(frame: .zero)
        }
        
        header.setPreferredBackgroundColor(TokenColors.Background.page)
        
        if getLinkViewModel != nil {
            updateHeaderViewForAlbum(forHeader: &header, forSection: section)
        } else if getLinkVM.isMultiLink {
            guard section > 0 else {
                let emptyHeaderView = UIView()
                emptyHeaderView.backgroundColor = .clear
                return emptyHeaderView
            }
            
            header.titleLabel.textAlignment = .left
            header.configure(
                title: Strings.Localizable.link,
                color: TokenColors.Text.secondary,
                topDistance: section == 1 ? 17.0 : 25.0,
                isTopSeparatorVisible: false, isBottomSeparatorVisible: true
            )
        } else if let sectionType = sections()[safe: section] {
            updateHeaderViewForSingleItem(forHeader: &header, forSection: sectionType)
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard var footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "GenericHeaderFooterViewID") as? GenericHeaderFooterView else {
            return UIView(frame: .zero)
        }
        
        footer.setPreferredBackgroundColor(TokenColors.Background.page)
        
        if getLinkViewModel != nil {
            updateFooterViewForAlbum(forFooter: &footer, forSection: section)
        } else if getLinkVM.isMultiLink {
            guard section > 0 else {
                return nil
            }
            
            updateFooterViewForMultiItem(forFooter: &footer, forSection: section)
        } else if let sectionType = sections()[safe: section] {
            updateFooterViewForSingleItem(forFooter: &footer, forSection: sectionType)
        }
        
        return footer
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let getLinkViewModel {
            getLinkViewModel.dispatch(.didSelectRow(indexPath: indexPath))
            return
        }
        if getLinkVM.isMultiLink {
            if indexPath.row == 1 {
                copyLinkToPasteboard(atIndex: indexPath.section-1, isFromLinkCellTap: true)
            }
        } else {
            switch sections()[indexPath.section] {
            case .info, .decryptKeySeparate, .linkAccessInfo:
                break
            case .expiryDate:
                switch expireDateRows()[indexPath.row] {
                case .activateExpiryDate, .pickExpiryDate:
                    break
                case .configureExpiryDate:
                    getLinkVM.selectDate = !getLinkVM.selectDate
                    guard let expiryDateSection = sections().firstIndex(of: .expiryDate) else { return }
                    tableView.reloadSections([expiryDateSection], with: .automatic)
                }
            case .passwordProtection:
                switch passwordProtectionRows()[indexPath.row] {
                case .configurePasword:
                    if justUpgradedToProAccount {
                        // Activity indicators are shown until the updated account details are received
                        return
                    }
                    
                    if MEGASdk.shared.mnz_isProAccount {
                        getLinkVM.trackSetPassword()
                        present(SetLinkPasswordViewController.instantiate(withDelegate: self), animated: true, completion: nil)
                    } else {
                        showUpgradeToProCustomModalAlert()
                    }
                }
            case .link:
                switch linkRows()[indexPath.row] {
                case .link:
                    copyLinkToPasteboard()
                case .password:
                    copyPasswordToPasteboard()
                case .removePassword:
                    getLinkVM.passwordProtect = false
                    getLinkVM.password = nil
                    getLinkVM.link = getLinkVM.nodes[0].publicLink ?? ""
                    getLinkVM.trackRemovePassword()
                    tableView.reloadData()
                }
            case .key:
                copyKeyToPasteBoard()
            }
            
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - MEGARequestDelegate

extension GetLinkViewController: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if request.type == .MEGARequestTypeAccountDetails {
            if error.type == .apiOk {
                if justUpgradedToProAccount {
                    // Reset temporal flag when the account details are received to allow using the PRO features
                    justUpgradedToProAccount = false
                    reloadProSections()
                    
                    removeDelegates()
                }
            }
        }
    }
}

// MARK: - SetLinkPasswordViewControllerDelegate

extension GetLinkViewController: SetLinkPasswordViewControllerDelegate {
    func setLinkPassword(_ setLinkPassword: SetLinkPasswordViewController, password: String) {
        setLinkPassword.dismissView()
        showCopySuccessSnackBar(with: Strings.Localizable.SharedItems.Link.linkUpdated)
        if let publicLink = getLinkVM.nodes[0].publicLink {
            getLinkVM.trackConfirmPassword()
            encrypt(link: publicLink, with: password)
        }
    }
    
    func setLinkPasswordCanceled(_ setLinkPassword: SetLinkPasswordViewController) {
        setLinkPassword.dismissView()
    }
}

// MARK: - MEGAPurchaseDelegate

extension GetLinkViewController: MEGAPurchaseDelegate {
    func successfulPurchase(_ megaPurchase: MEGAPurchase!) {
        justUpgradedToProAccount = true
        reloadProSections()
    }
}

// MARK: - MEGARestoreDelegate

extension GetLinkViewController: MEGARestoreDelegate {
    func successfulRestore(_ megaPurchase: MEGAPurchase!) {
        justUpgradedToProAccount = true
        reloadProSections()
    }
}

private extension GenericHeaderFooterView {
    func configure(
        title: String,
        color: UIColor,
        topDistance: CGFloat,
        isTopSeparatorVisible: Bool,
        isBottomSeparatorVisible: Bool
    ) {
        let attributedString = NSMutableAttributedString(string: title, attributes: [NSAttributedString.Key.foregroundColor: color as Any])
        configure(attributedTitle: attributedString, topDistance: topDistance, isTopSeparatorVisible: isTopSeparatorVisible, isBottomSeparatorVisible: isBottomSeparatorVisible)
    }
}
