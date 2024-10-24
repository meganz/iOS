import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import PDFKit
import UIKit
import VisionKit

enum DocScanExportFileType: String {
    case pdf = "PDF"
    case jpg = "JPG"
}

enum DocScanQuality: Float, CustomStringConvertible {
    case best = 0.95
    case medium = 0.8
    case low = 0.7
    
    var description: String {
        switch self {
        case .best:
            return Strings.Localizable.Media.Quality.best
        case .medium:
            return Strings.Localizable.Media.Quality.medium
        case .low:
            return Strings.Localizable.Media.Quality.low
        }
    }
    
    var imageSize: Int {
        switch self {
        case .best:
            return 3000
        case .medium:
            return 2500
        case .low:
            return 1500
        }
    }
}

class DocScannerSaveSettingTableViewController: UITableViewController {
    @objc var parentNode: MEGANode? {
        didSet {
            guard parentNode?.handle != parentNodeEntity?.handle else { return }
            
            parentNodeEntity = parentNode?.toNodeEntity()
        }
    }

    var parentNodeEntity: NodeEntity? {
        didSet {
            guard parentNodeEntity?.handle != parentNode?.handle else { return }

            if let parentNodeEntity {
                parentNode = MEGASdk.shared.node(forHandle: parentNodeEntity.handle)
            } else {
                parentNode = nil
            }
        }
    }

    @objc var docs: [UIImage]?
    var chatRoom: ChatRoomEntity?
    var charactersNotAllowed: Bool = false

    @IBOutlet weak var sendButton: UIBarButtonItem!
    
    var originalFileName = Strings.Localizable.CloudDrive.ScanDocument.defaultName(NSDate().mnz_formattedDefaultNameForMedia())
    var currentFileName: String?
    
    private struct TableViewConfiguration {
        static var numberOfSections: Int { Section.allCases.count }
        static let numberOfRowsInFirstSection = 1
        static let numberOfRowsInSecondSection = 2
        static let numberOfRowsInThirdSection = 2
        
        enum Section: Int, CaseIterable {
            case scannedDocumentPreview
            case settings
            case selectDestination
        }
    }
    
    struct keys {
        static let docScanExportFileTypeKey = "DocScanExportFileTypeKey"
        static let docScanQualityKey = "DocScanQualityKey"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateAppearance()
        title = Strings.Localizable.saveSettings
        
        currentFileName = originalFileName
        
        let fileType = UserDefaults.standard.string(forKey: keys.docScanExportFileTypeKey)
        let quality = UserDefaults.standard.string(forKey: keys.docScanQualityKey)
        if fileType == nil || docs?.count ?? 0 > 1 {
            UserDefaults.standard.set(DocScanExportFileType.pdf.rawValue, forKey: keys.docScanExportFileTypeKey)
        }
        if quality == nil {
            UserDefaults.standard.set(DocScanQuality.best.rawValue, forKey: keys.docScanQualityKey)
        }
        
        sendButton.title = Strings.Localizable.send
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if chatRoom != nil {
            navigationController?.setToolbarHidden(false, animated: false)
        } else {
            navigationController?.setToolbarHidden(true, animated: false)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
            
            tableView.reloadData()
        }
    }
    
    // MARK: - Private
    
    @IBAction func sendAction(_ sender: Any) {
        
        guard isValidName() else {
            return
        }
        
        guard let chatRoom = chatRoom else {
            return
        }
        
        MyChatFilesFolderNodeAccess.shared.loadNode { myChatFilesFolderNode, error in
            guard error == nil, let myChatFilesFolderNode = myChatFilesFolderNode else {
                if let error = error {
                    MEGALogWarning("Could not load MyChatFiles target folder due to error \(error.localizedDescription)")
                }
                return
            }
            let paths = self.exportScannedDocs()
            paths.forEach { (path) in
                var appData = NSString().mnz_appData(toSaveCoordinates: path.mnz_coordinatesOfPhotoOrVideo() ?? "")
                appData = ((appData) as NSString).mnz_appDataToAttach(toChatID: chatRoom.chatId, asVoiceClip: false)
                ChatUploader.sharedInstance.upload(filepath: path,
                                                   appData: appData,
                                                   chatRoomId: chatRoom.chatId,
                                                   parentNode: myChatFilesFolderNode,
                                                   isSourceTemporary: true,
                                                   delegate: MEGAStartUploadTransferDelegate(completion: nil))
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    private func isValidName() -> Bool {
        guard var currentFileName = currentFileName else {
            return false
        }
        
        currentFileName = currentFileName.trimmingCharacters(in: .whitespaces)
        let containsInvalidChars = currentFileName.mnz_containsInvalidChars()
        let empty = currentFileName.mnz_isEmpty()
        if containsInvalidChars || empty {
            let element = self.view.subviews.first(where: { $0 is DocScannerFileNameTableCell })
            let cell = element as? DocScannerFileNameTableCell
            cell?.filenameTextField.becomeFirstResponder()
            return false
        } else {
            return true
        }
    }
    
    private func putOriginalNameIfTextFieldIsEmpty() {
        let element = self.view.subviews.first(where: { $0 is DocScannerFileNameTableCell })
        let filenameTVC = element as? DocScannerFileNameTableCell
        guard let isFileNameTextFieldEmpty = filenameTVC?.filenameTextField.text?.isEmpty else { return }
        if isFileNameTextFieldEmpty {
            filenameTVC?.filenameTextField.text = originalFileName
        }
        
        filenameTVC?.filenameTextField.resignFirstResponder()
    }
    
    private func updateAppearance() {
        tableView.backgroundColor = TokenColors.Background.page
        tableView.separatorColor = .mnz_separator()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if chatRoom != nil {
            return TableViewConfiguration.Section.allCases.dropFirst().count
        }
        return TableViewConfiguration.Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableViewConfiguration.Section(rawValue: section) {
        case .scannedDocumentPreview:
            return TableViewConfiguration.numberOfRowsInFirstSection
        case .settings:
            return TableViewConfiguration.numberOfRowsInSecondSection
        case .selectDestination:
            return TableViewConfiguration.numberOfRowsInThirdSection
        default:
            fatalError("please define a constant in struct TableViewConfiguration")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        let section = TableViewConfiguration.Section(rawValue: indexPath.section)
        if section == .scannedDocumentPreview {
            if let filenameCell = tableView.dequeueReusableCell(withIdentifier: DocScannerFileNameTableCell.reuseIdentifier, for: indexPath) as? DocScannerFileNameTableCell {
                let fileType = UserDefaults.standard.string(forKey: keys.docScanExportFileTypeKey)
                filenameCell.delegate = self
                filenameCell.configure(filename: originalFileName, fileType: fileType)
                cell = filenameCell
                
                if originalFileName != currentFileName {
                    filenameCell.filenameTextField.text = currentFileName
                }
                let containsInvalidChars = filenameCell.filenameTextField.text?.mnz_containsInvalidChars() ?? false
                filenameCell.filenameTextField.textColor = containsInvalidChars ? .systemRed : .label
            }
        } else if section == .settings {
            if let detailCell = tableView.dequeueReusableCell(withIdentifier: DocScannerDetailTableCell.reuseIdentifier, for: indexPath) as? DocScannerDetailTableCell,
                let cellType = DocScannerDetailTableCell.CellType(rawValue: indexPath.row) {
                detailCell.cellType = cellType
                if docs?.count ?? 0 > 1 && indexPath.row == 0 {
                    detailCell.accessoryType = .none
                }
                
                cell = detailCell
            }
        } else {
            if let actionCell = tableView.dequeueReusableCell(withIdentifier: DocScannerActionTableViewCell.reuseIdentifier, for: indexPath) as?  DocScannerActionTableViewCell,
                let cellType = DocScannerActionTableViewCell.CellType(rawValue: indexPath.row) {
                actionCell.cellType = cellType
                cell = actionCell
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch TableViewConfiguration.Section(rawValue: section) {
        case .scannedDocumentPreview:
            return charactersNotAllowed ? Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay) : Strings.Localizable.tapFileToRename
            
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let section = TableViewConfiguration.Section(rawValue: section)
        if section == .scannedDocumentPreview {
            let footer = view as! UITableViewHeaderFooterView
            footer.textLabel?.textAlignment = .center
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        titleForHeader(in: section)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        configureTableViewHeaderStyleWithSentenceCase(view, forSection: section)
    }
    
    private func configureTableViewHeaderStyleWithSentenceCase(_ view: UIView, forSection section: Int) {
        guard let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView else { return }
        tableViewHeaderFooterView.textLabel?.text = titleForHeader(in: section)
    }
    
    private func titleForHeader(in section: Int) -> String? {
        let section = TableViewConfiguration.Section(rawValue: section)
        switch section {
        case .settings:
            return Strings.Localizable.settingsTitle
        case .selectDestination:
            return Strings.Localizable.selectDestination
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = TableViewConfiguration.Section(rawValue: indexPath.section)
        if section == .settings {
            switch indexPath.row {
            case 0:
                if docs?.count ?? 0 < 2 {
                    let alert = UIAlertController(title: nil, message: Strings.Localizable.fileType, preferredStyle: .actionSheet)
                    let PDFAlertAction = UIAlertAction(title: "PDF", style: .default, handler: { _ in
                        UserDefaults.standard.set(DocScanExportFileType.pdf.rawValue, forKey: keys.docScanExportFileTypeKey)
                        tableView.reloadData()
                    })
                    alert.addAction(PDFAlertAction)
                    
                    let JPGAlertAction = UIAlertAction(title: "JPG", style: .default, handler: { _ in
                        UserDefaults.standard.set(DocScanExportFileType.jpg.rawValue, forKey: keys.docScanExportFileTypeKey)
                        tableView.reloadData()
                    })
                    alert.addAction(JPGAlertAction)
                    
                    if let popover = alert.popoverPresentationController {
                        popover.sourceView = tableView
                        popover.sourceRect = tableView.rectForRow(at: indexPath)
                    }
                    
                    alert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
                    
                    present(alert, animated: true, completion: nil)
                }
            case 1:
                let alert = UIAlertController(title: nil, message: Strings.Localizable.quality, preferredStyle: .actionSheet)
                let bestAlertAction = UIAlertAction(title: DocScanQuality.best.description, style: .default, handler: { _ in
                    UserDefaults.standard.set(DocScanQuality.best.rawValue, forKey: keys.docScanQualityKey)
                    tableView.reloadRows(at: [indexPath], with: .none)
                })
                alert.addAction(bestAlertAction)
                
                let mediumAlertAction = UIAlertAction(title: DocScanQuality.medium.description, style: .default, handler: { _ in
                    UserDefaults.standard.set(DocScanQuality.medium.rawValue, forKey: keys.docScanQualityKey)
                    tableView.reloadRows(at: [indexPath], with: .none)
                })
                alert.addAction(mediumAlertAction)
                
                let lowAlertAction = UIAlertAction(title: DocScanQuality.low.description, style: .default, handler: { _ in
                    UserDefaults.standard.set(DocScanQuality.low.rawValue, forKey: keys.docScanQualityKey)
                    tableView.reloadRows(at: [indexPath], with: .none)
                })
                alert.addAction(lowAlertAction)
                
                if let popover = alert.popoverPresentationController {
                    popover.sourceView = tableView
                    popover.sourceRect = tableView.rectForRow(at: indexPath)
                }
                
                alert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler: nil))
                
                present(alert, animated: true, completion: nil)
            default: break
            }
        } else if section == .selectDestination {
            guard isValidName() else {
                return
            }
            
            putOriginalNameIfTextFieldIsEmpty()
            
            switch indexPath.row {
            case 0:
                let storyboard = UIStoryboard(name: "Cloud", bundle: Bundle(for: BrowserViewController.self))
                if let browserVC = storyboard.instantiateViewController(withIdentifier: "BrowserViewControllerID") as? BrowserViewController {
                    browserVC.browserAction = .shareExtension
                    browserVC.parentNode = parentNode
                    browserVC.isChildBrowser = true
                    browserVC.browserViewControllerDelegate = self
                    navigationController?.setToolbarHidden(false, animated: true)
                    navigationController?.pushViewController(browserVC, animated: true)
                }
            case 1:
                let storyboard = UIStoryboard(name: "Chat", bundle: Bundle(for: SendToViewController.self))
                if let sendToViewController = storyboard.instantiateViewController(withIdentifier: "SendToViewControllerID") as? SendToViewController {
                    sendToViewController.sendToViewControllerDelegate = self
                    sendToViewController.sendMode = .shareExtension
                    navigationController?.pushViewController(sendToViewController, animated: true)
                }
            default: break
            }
            
        }
    }
}

extension DocScannerSaveSettingTableViewController: DocScannerFileInfoTableCellDelegate {
    func filenameChanged(_ newFilename: String) {
        currentFileName = newFilename
    }
    
    func containsCharactersNotAllowed() {
        if !charactersNotAllowed {
            charactersNotAllowed = true
            tableView.reloadSections(IndexSet.init(integer: 0), with: .none)
        }
    }
}

extension DocScannerSaveSettingTableViewController: BrowserViewControllerDelegate {
    func upload(toParentNode parentNode: MEGANode) {
        dismiss(animated: true) {
            let transfers = self.exportScannedDocs().map { CancellableTransfer(handle: .invalid, parentHandle: parentNode.handle, localFileURL: URL(fileURLWithPath: $0), name: nil, appData: NSString().mnz_appData(toSaveCoordinates: $0.mnz_coordinatesOfPhotoOrVideo() ?? ""), priority: false, isFile: true, type: .upload) }
            let collisionEntities = transfers.map { NameCollisionEntity(parentHandle: $0.parentHandle, name: $0.localFileURL?.lastPathComponent ?? "", isFile: $0.isFile, fileUrl: $0.localFileURL) }
            NameCollisionViewRouter(presenter: UIApplication.mnz_presentingViewController(), transfers: transfers, nodes: nil, collisions: collisionEntities, collisionType: .upload).start()
        }
    }
}

extension DocScannerSaveSettingTableViewController: SendToViewControllerDelegate {
    func send(_ viewController: SendToViewController, toChats chats: [MEGAChatListItem], andUsers users: [MEGAUser]) {
        MyChatFilesFolderNodeAccess.shared.loadNode { myChatFilesFolderNode, error in
            guard let myChatFilesFolderNode = myChatFilesFolderNode else {
                if let error = error {
                    MEGALogWarning("Could not load MyChatFiles target folder due to error \(error.localizedDescription)")
                }
                return
            }
            
            let paths = self.exportScannedDocs()
            var completionCounter = 0
            paths.forEach { (path) in
                let appData = NSString().mnz_appData(toSaveCoordinates: path.mnz_coordinatesOfPhotoOrVideo() ?? "")
                let startUploadTransferDelegate = MEGAStartUploadTransferDelegate { (transfer) in
                    guard let transferNodeHandle = transfer?.nodeHandle,
                          let nodeHandle = MEGASdk.shared.node(forHandle: transferNodeHandle)?.handle else { return }
                    
                    chats.forEach { chatRoom in
                        MEGAChatSdk.shared.attachNode(toChat: chatRoom.chatId, node: nodeHandle)
                    }
                    users.forEach { user in
                        if let chatRoom = MEGAChatSdk.shared.chatRoom(byUser: user.handle) {
                            MEGAChatSdk.shared.attachNode(toChat: chatRoom.chatId, node: nodeHandle)
                        } else {
                            MEGAChatSdk.shared.mnz_createChatRoom(userHandle: user.handle, completion: { (chatRoom) in
                                MEGAChatSdk.shared.attachNode(toChat: chatRoom.chatId, node: nodeHandle)
                            })
                        }
                    }
                    if completionCounter == paths.count - 1 {
                        let receiverCount = chats.count + users.count
                        let fileName = self.currentFileName ?? self.originalFileName
                        let message = Strings.Localizable.Share.Message.SendToChat.withOneFile(receiverCount)
                            .replacingOccurrences(of: "[A]", with: fileName)
                        SVProgressHUD.showSuccess(withStatus: message)
                    }
                    completionCounter += 1
                }
                MEGASdk.shared.startUploadForChat(withLocalPath: path, parent: myChatFilesFolderNode, appData: appData, isSourceTemporary: true, fileName: nil, delegate: startUploadTransferDelegate!)
            }
        }
        dismiss(animated: true, completion: nil)
    }
}

extension DocScannerSaveSettingTableViewController {
    private func exportScannedDocs() -> [String] {
        guard let storedExportFileTypeKey = UserDefaults.standard.string(forKey: keys.docScanExportFileTypeKey) else {
            MEGALogDebug("No stored value found for docScanExportFileTypeKey")
            return []
        }
        let fileType = DocScanExportFileType(rawValue: storedExportFileTypeKey)
        let scanQuality = DocScanQuality(rawValue: UserDefaults.standard.float(forKey: keys.docScanQualityKey)) ?? .best
        var tempPaths: [String] = []
        if fileType == .pdf {
            let pdfDoc = PDFDocument()
            docs?.enumerated().forEach {
                if let shrinkedImageData = $0.element.shrinkedImageData(docScanQuality: scanQuality),
                   let shrinkedImage = UIImage(data: shrinkedImageData),
                   let pdfPage = PDFPage(image: shrinkedImage) {
                    pdfDoc.insert(pdfPage, at: $0.offset)
                } else {
                    MEGALogDebug(String(format: "could not create PdfPage at index %d", $0.offset))
                }
            }
            
            if let data = pdfDoc.dataRepresentation() {
                let fileName = "\(currentFileName ?? originalFileName).pdf"
                let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
                do {
                    try data.write(to: URL(fileURLWithPath: tempPath), options: .atomic)
                    tempPaths.append(tempPath)
                } catch {
                    MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
                }
            } else {
                MEGALogDebug("Cannot convert pdf doc to data representation")
            }
        } else if fileType == .jpg {
            docs?.enumerated().forEach {
                if let data = $0.element.shrinkedImageData(docScanQuality: scanQuality) {
                    let fileName = (self.docs?.count ?? 1 > 1) ? "\(currentFileName ?? originalFileName) \($0.offset + 1).jpg" : "\(currentFileName ?? originalFileName).jpg"
                    let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
                    do {
                        try data.write(to: URL(fileURLWithPath: tempPath), options: .atomic)
                        tempPaths.append(tempPath)
                    } catch {
                        MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
                    }
                } else {
                    MEGALogDebug("Unable to fetch the stored DocScanQuality")
                }
            }
        }
        return tempPaths
    }
}
