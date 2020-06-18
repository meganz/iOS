import UIKit
import PDFKit
import VisionKit

enum DocScanExportFileType: String {
    case pdf = "PDF"
    case jpg = "JPG"
}

enum DocScanQuality: Float, CustomStringConvertible {
    case best = 1
    case medium = 0.7
    case low = 0.5
    
    var description: String {
        switch self {
        case .best:
            return AMLocalizedString("best")
        case .medium:
            return AMLocalizedString("medium")
        case .low:
            return AMLocalizedString("low")
        }
    }
}

class DocScannerSaveSettingTableViewController: UITableViewController {
    @objc var parentNode: MEGANode?
    @objc var docs: [UIImage]?
    var fileName = "Scan \(NSDate().mnz_formattedDefaultNameForMedia())"
    
    private struct TableViewConfiguration {
        static let numberOfSections = 3
        static let numberOfRowsInFirstSection = 1
        static let numberOfRowsInSecondSection = 2
        static let numberOfRowsInThirdSection = 2
    }
    
    struct keys {
        static let docScanExportFileTypeKey = "DocScanExportFileTypeKey"
        static let docScanQualityKey = "DocScanQualityKey"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = AMLocalizedString("Save Settings", "Setting title for Doc scan view")
        let fileType = UserDefaults.standard.string(forKey: keys.docScanExportFileTypeKey)
        let quality = UserDefaults.standard.string(forKey: keys.docScanQualityKey)
        if fileType == nil || quality == nil  {
            UserDefaults.standard.set(DocScanExportFileType.pdf.rawValue, forKey: keys.docScanExportFileTypeKey)
            UserDefaults.standard.set(DocScanQuality.best.rawValue, forKey: keys.docScanQualityKey)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
                
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - Private
        
    private func updateAppearance() {
        tableView.backgroundColor = .mnz_backgroundGrouped(for: traitCollection)
        tableView.separatorColor = .mnz_separator(for: traitCollection)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableViewConfiguration.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return TableViewConfiguration.numberOfRowsInFirstSection
        case 1:
            return TableViewConfiguration.numberOfRowsInSecondSection
        case 2:
            return TableViewConfiguration.numberOfRowsInThirdSection
        default:
            fatalError("please define a constant in struct TableViewConfiguration")
        }
    }
        
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if indexPath.section == 0 {
            if let filenameCell = tableView.dequeueReusableCell(withIdentifier: DocScannerFileNameTableCell.reuseIdentifier, for: indexPath) as? DocScannerFileNameTableCell {
                let fileType = UserDefaults.standard.string(forKey: keys.docScanExportFileTypeKey)
                filenameCell.delegate = self
                filenameCell.configure(filename: fileName, fileType: fileType)
                cell = filenameCell
            }
        } else if indexPath.section == 1 {
            if let detailCell = tableView.dequeueReusableCell(withIdentifier: DocScannerDetailTableCell.reuseIdentifier, for: indexPath) as? DocScannerDetailTableCell,
                let cellType = DocScannerDetailTableCell.CellType(rawValue: indexPath.row) {
                detailCell.cellType = cellType
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
        switch section {
        case 0:
            return AMLocalizedString("tapFileToRename")
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if section == 0 {
            let footer = view as! UITableViewHeaderFooterView
            footer.textLabel?.textAlignment = .center
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return AMLocalizedString("settingsTitle")
        case 2:
            return AMLocalizedString("selectDestination")
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                let alert = UIAlertController(title: nil, message: AMLocalizedString("File Type", "file type title, used in changing the export format of scaned doc"), preferredStyle: .actionSheet)
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
                
                alert.addAction(UIAlertAction(title: AMLocalizedString("cancel"), style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            case 1:
                let alert = UIAlertController(title: nil, message:
                    AMLocalizedString("Quality", "Quality title, used in changing the export quality of scaned doc"), preferredStyle: .actionSheet)
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
                
                let lowAlertAction = UIAlertAction(title:  DocScanQuality.low.description, style: .default, handler: { _ in
                    UserDefaults.standard.set(DocScanQuality.low.rawValue, forKey: keys.docScanQualityKey)
                    tableView.reloadRows(at: [indexPath], with: .none)
                })
                alert.addAction(lowAlertAction)
                
                alert.addAction(UIAlertAction(title: AMLocalizedString("cancel"), style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
            default: break
            }
        } else if indexPath.section == 2 {
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
        guard !newFilename.isEmpty else {
            fileName = "Scan \(NSDate().mnz_formattedDefaultNameForMedia())"
            return
        }
        fileName = newFilename
    }
}

extension DocScannerSaveSettingTableViewController: BrowserViewControllerDelegate {
    func upload(toParentNode parentNode: MEGANode!) {
        guard let storedExportFileTypeKey = UserDefaults.standard.string(forKey: keys.docScanExportFileTypeKey) else {
            MEGALogDebug("No stored value found for docScanExportFileTypeKey")
            return
        }
        
        let fileType = DocScanExportFileType(rawValue: storedExportFileTypeKey)
        if fileType == .pdf {
            if #available(iOS 11.0, *) {
                let pdfDoc = PDFDocument()
                docs?.enumerated().forEach {
                    if let pdfPage = PDFPage(image: $0.element) {
                        pdfDoc.insert(pdfPage, at: $0.offset)
                    } else {
                        MEGALogDebug(String(format: "could not create PdfPage at index %d", $0.offset))
                    }
                }
                if let data = pdfDoc.dataRepresentation() {
                    let fileName = "\(self.fileName).pdf"
                    let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
                    do {
                        try data.write(to: URL(fileURLWithPath: tempPath), options: .atomic)
                        let appData = NSString().mnz_appData(toSaveCoordinates: tempPath.mnz_coordinatesOfPhotoOrVideo() ?? "")
                        MEGASdkManager.sharedMEGASdk()?.startUpload(withLocalPath: tempPath, parent: parentNode, appData: appData, isSourceTemporary: true)
                    } catch {
                        MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
                    }
                } else {
                    MEGALogDebug("Cannot convert pdf doc to data representation")
                }
            }
        } else if fileType == .jpg {
            docs?.enumerated().forEach {
                if let quality = DocScanQuality(rawValue: UserDefaults.standard.float(forKey: keys.docScanQualityKey)),
                    let data = $0.element.jpegData(compressionQuality: CGFloat(quality.rawValue)) {
                    let fileName: String
                    if self.docs?.count ?? 1 > 1 {
                        fileName = "\(self.fileName) \($0.offset).jpg"
                    } else {
                        fileName =  "\(self.fileName).jpg"
                    }
                    let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
                    do {
                        try data.write(to: URL(fileURLWithPath: tempPath), options: .atomic)
                        let appData = NSString().mnz_appData(toSaveCoordinates: tempPath.mnz_coordinatesOfPhotoOrVideo() ?? "")
                        MEGASdkManager.sharedMEGASdk()?.startUpload(withLocalPath: tempPath, parent: parentNode, appData: appData, isSourceTemporary: true)
                    } catch {
                        MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
                    }
                } else {
                    MEGALogDebug("Unable to fetch the stored DocScanQuality")
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }
}

extension DocScannerSaveSettingTableViewController: SendToViewControllerDelegate {
    func send(_ viewController: SendToViewController!, toChats chats: [MEGAChatListItem]!, andUsers users: [MEGAUser]!) {
        MEGASdkManager.sharedMEGASdk()?.getMyChatFilesFolder(completion: { (node) in
            if #available(iOS 11.0, *) {
                let fileType = DocScanExportFileType(rawValue: UserDefaults.standard.string(forKey: keys.docScanExportFileTypeKey)!)
                if fileType == .pdf {
                    let pdfDoc = PDFDocument()
                    self.docs?.enumerated().forEach {
                        if let pdfpage = PDFPage(image: $0.element) {
                            pdfDoc.insert(pdfpage, at: $0.offset)
                        }
                    }
                    let data = pdfDoc.dataRepresentation()
                    let fileName = "\(self.fileName).pdf"
                    let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
                    
                    do {
                        try data?.write(to: URL(fileURLWithPath: tempPath), options: .atomic)
                        let appData = NSString().mnz_appData(toSaveCoordinates: tempPath.mnz_coordinatesOfPhotoOrVideo() ?? "")
                        let startUploadTransferDelegate = MEGAStartUploadTransferDelegate { (transfer) in
                            let node = MEGASdkManager.sharedMEGASdk()?.node(forHandle: transfer!.nodeHandle)
                            chats.forEach { chatRoom in
                                MEGASdkManager.sharedMEGAChatSdk()?.attachNode(toChat: chatRoom.chatId, node: node!.handle)
                            }
                            users.forEach { user in
                                if let chatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(byUser: user.handle) {
                                    MEGASdkManager.sharedMEGAChatSdk()?.attachNode(toChat: chatRoom.chatId, node: node!.handle)
                                } else {
                                    MEGASdkManager.sharedMEGAChatSdk()?.mnz_createChatRoom(userHandle: user.handle, completion: { (chatRoom) in
                                        MEGASdkManager.sharedMEGAChatSdk()?.attachNode(toChat: chatRoom.chatId, node: node!.handle)
                                    })
                                }
                            }
                            SVProgressHUD.showSuccess(withStatus: AMLocalizedString("Shared successfully", "Success message shown when the user has successfully shared something"))
                        }
                        MEGASdkManager.sharedMEGASdk()?.startUploadForChat(withLocalPath: tempPath, parent: node, appData: appData, isSourceTemporary: true, delegate: startUploadTransferDelegate!)

                    } catch {
                        MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
                    }
                } else if fileType == .jpg {
                    var completionCounter = 0
                    self.docs?.enumerated().forEach {
                        if let quality = DocScanQuality(rawValue: UserDefaults.standard.float(forKey: keys.docScanQualityKey)),
                            let data = $0.element.jpegData(compressionQuality: CGFloat(quality.rawValue)) {
                            let fileName: String
                            if self.docs?.count ?? 1 > 1 {
                                fileName = "\(self.fileName) \($0.offset).jpg"
                            } else {
                                fileName =  "\(self.fileName).jpg"
                            }
                            let tempPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
                            do {
                                try data.write(to: URL(fileURLWithPath: tempPath), options: .atomic)
                                let appData = NSString().mnz_appData(toSaveCoordinates: tempPath.mnz_coordinatesOfPhotoOrVideo() ?? "")
                                let startUploadTransferDelegate = MEGAStartUploadTransferDelegate { (transfer) in
                                    let node = MEGASdkManager.sharedMEGASdk()?.node(forHandle: transfer!.nodeHandle)
                                    chats.forEach { chatRoom in
                                        MEGASdkManager.sharedMEGAChatSdk()?.attachNode(toChat: chatRoom.chatId, node: node!.handle)
                                    }
                                    users.forEach { user in
                                        if let chatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(byUser: user.handle) {
                                            MEGASdkManager.sharedMEGAChatSdk()?.attachNode(toChat: chatRoom.chatId, node: node!.handle)
                                        } else {
                                            MEGASdkManager.sharedMEGAChatSdk()?.mnz_createChatRoom(userHandle: user.handle, completion: { (chatRoom) in
                                                MEGASdkManager.sharedMEGAChatSdk()?.attachNode(toChat: chatRoom.chatId, node: node!.handle)
                                            })
                                        }
                                    }
                                    if completionCounter == self.docs!.count - 1 {
                                        SVProgressHUD.showSuccess(withStatus: AMLocalizedString("Shared successfully", "Success message shown when the user has successfully shared something"))
                                    }
                                    completionCounter = completionCounter + 1
                                }
                                MEGASdkManager.sharedMEGASdk()?.startUploadForChat(withLocalPath: tempPath, parent: node, appData: appData, isSourceTemporary: true, delegate: startUploadTransferDelegate!)
                            } catch {
                                MEGALogDebug("Could not write to file \(tempPath) with error \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        })
        dismiss(animated: true, completion: nil)
    }
}
