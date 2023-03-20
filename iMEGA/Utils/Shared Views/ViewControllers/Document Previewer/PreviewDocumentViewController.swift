//
//  PreviewDocumentViewController.swift
//  MEGA
//
//  Created by Meler Paine on 2023/3/18.
//  Copyright © 2023 MEGA. All rights reserved.
//

import UIKit
import PureLayout

@objc
class PreviewDocumentViewController: UIViewController, SearchInPdfViewControllerProtocol {
    
    // MARK: - public property
    
    @objc var node: MEGANode?
    @objc var nodeHandle: UInt64 = MEGAInvalidHandle
    @objc var api: MEGASdk?
    @objc var filePath: String?
    @objc var isLink: Bool = false
    @objc var fileLink: String?
    @objc var showUnknownEncodeHud: Bool = false
    @objc var chatId: MEGAHandle = ~UInt64.zero
    @objc var messageId: MEGAHandle = ~UInt64.zero
    
    // MARK: - private property
    
    private var previewDocumentTransfer: MEGATransfer?
    private var previewController: QLPreviewController?
    private var nodeFilePath: String?
    private var textContent: String?
    private var thumbnailCache: NSCache<NSNumber, UIImage> = NSCache()
    private var thumbnailsPopulated: Bool = false
    private var searchedItem: PDFSelection?
    private var sendLinkDelegate: SendLinkToChatsDelegate?
    private var openZipButton: UIButton?
    private var outlineView: PDFOutlineView?
    
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var closeBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var thumbnailBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var outlineBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var searchBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var exportFileBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var moreBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var importBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var downloadBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.node == nil && self.nodeHandle != MEGAInvalidHandle {
            self.node = MEGASdkManager.sharedMEGASdk().node(forHandle: self.nodeHandle)
        }
        
        
        self.configureNavigation()
        self.configureDocumentOutline()
        self.updateAppearance()
        
        self.closeBarButtonItem.title = NSLocalizedString("close", comment: "A button label.")
        self.moreBarButtonItem.accessibilityLabel = NSLocalizedString("more", comment: "Top menu option which opens more menu options in a context menu.")
        
        if self.showUnknownEncodeHud {
            SVProgressHUD.showError(withStatus: NSLocalizedString("general.textEditor.hud.unknownEncode", comment: "Hud info message when read unknown encode file."))
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.filePath != nil {
            self.loadPreview()
        } else {
            
            let nodeFolderPath = NSTemporaryDirectory().append(pathComponent: self.node?.base64Handle ?? "")
            let nodeFilePath = nodeFolderPath.append(pathComponent: self.node?.name ?? "")
            self.nodeFilePath = nodeFilePath
            
            guard let _node = self.node else { return }
            do {
                try FileManager.default.createDirectory(atPath: nodeFolderPath, withIntermediateDirectories: true)
                MEGASdkManager.sharedMEGASdk().startDownloadNode(_node, localPath: nodeFilePath, fileName: nil, appData: nil, startFirst: false, cancelToken: nil, delegate: self)
            } catch {
                MEGALogError("Create directory at path failed with error: \(error.localizedDescription)")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if previewDocumentTransfer != nil {
            MEGASdkManager.sharedMEGASdk().cancelTransfer(previewDocumentTransfer!)
        }
        
        if !self.pdfView.isHidden {
            if let pageRef = self.pdfView.currentPage?.pageRef, let documentURL = self.pdfView.document?.documentURL {
                let page = pageRef.pageNumber
                let fingerprint = MEGASdkManager.sharedMEGASdk().fingerprint(forFilePath: documentURL.path)
                if page == 1 {
                    MEGAStore.shareInstance().deleteMediaDestination(withFingerprint: fingerprint ?? "")
                } else {
                    if fingerprint != nil && !fingerprint!.isEmpty {
                        MEGAStore.shareInstance().insertOrUpdateMediaDestination(withFingerprint: fingerprint!, destination: NSNumber(value: page), timescale: nil)
                    }
                }
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { context in
            self.previewController?.view.frame = self.view.bounds
            self.pdfView.scaleFactor = self.pdfView.scaleFactorForSizeToFit
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) &&
            self.navigationController != nil {
            AppearanceManager.forceNavigationBarUpdate(self.navigationController!.navigationBar, traitCollection: self.traitCollection)
            AppearanceManager.forceToolbarUpdate(self.navigationController!.toolbar, traitCollection: self.traitCollection)
            self.updateAppearance()
        }
    }
    
    // MARK: - Private
    
    func configureNavigation() {
        self.title = self.node?.name
        self.navigationItem.rightBarButtonItem = nil
        
        if self.node != nil {
            self.navigationItem.rightBarButtonItem = self.moreBarButtonItem
            self.imageView.image = NodeAssetsManager.shared.icon(for: self.node!)
        } else if (self.filePath as? NSString)?.pathExtension != nil {
            self.imageView.image = NodeAssetsManager.shared.image(for: (self.filePath! as NSString).pathExtension)
        }
        
        self.navigationController?.toolbar.backgroundColor = UIColor.mnz_mainBars(for: self.traitCollection)
    }
    
    func configureDocumentOutline() {
        let outlineView = PDFOutlineView(outline: [])
        self.outlineView = outlineView
        self.view .addSubview(outlineView)
        outlineView.translatesAutoresizingMaskIntoConstraints = false
        outlineView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
        outlineView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        outlineView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        outlineView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        hideOutlineView(true)
        outlineView.selectOutlineItemHandler = { outlineItem in
            if let document = self.pdfView.document, let page = document.page(at: (outlineItem.pageNumber - 1)) {
                self.pdfView.go(to: page)
            }
            self.hideOutlineView(true)
        }
    }
    
    func hideOutlineView(_ hide: Bool) {
        self.outlineView?.isHidden = hide
        if hide {
            self.outlineBarButtonItem.image = UIImage(systemName: "line.3.horizontal.circle")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(scale: .large))
        } else {
            self.outlineBarButtonItem.image = UIImage(systemName: "line.3.horizontal.circle.fill")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(scale: .large))
        }
    }
    
    func loadPreview() {
        let url = self.documentUrl()
        self.textContent = try? NSString(contentsOfFile: url.path, usedEncoding: nil) as String?
        if self.textContent != nil
            && url.path.mnz_isEditableTextFilePathExtension {
            loadTextView()
        } else if url.pathExtension == "pdf" {
            loadPdfKit(url)
        } else {
            loadQLController()
        }
    }
    
    func documentUrl() -> URL {
        if previewDocumentTransfer?.path != nil {
            return URL(fileURLWithPath: previewDocumentTransfer!.path)
        } else if self.node != nil && self.nodeFilePath != nil {
            return URL(fileURLWithPath: self.nodeFilePath!)
        } else {
            self.title = (self.filePath as? NSString)?.lastPathComponent
            return URL(fileURLWithPath: self.filePath ?? "")
        }
    }
    
    /// open neither text nor pdf file, such as Apple Numbers sheet file.
    func loadQLController() {
        self.activityIndicator.isHidden = true
        self.progressView.isHidden = true
        self.imageView.isHidden = true
        self.previewController = QLPreviewController()
        self.previewController!.delegate = self
        self.previewController!.dataSource = self
        self.previewController!.view.frame = self.view.bounds
        
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        var toolbarItems: [UIBarButtonItem] = []
        toolbarItems.append(contentsOf: [self.downloadBarButtonItem, flexibleItem])
        
        if MEGASdkManager.sharedMEGASdk().accessLevel(for: node!) == MEGAShareType.accessOwner {
            toolbarItems.append(self.exportFileBarButtonItem)
        } else {
            toolbarItems.append(self.importBarButtonItem)
        }
        self.toolbarItems = toolbarItems
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        self.view.addSubview(self.previewController!.view)
        
        if (self.filePath as? NSString)?.pathExtension.lowercased() == "zip" ||
            (self.nodeFilePath as? NSString)?.pathExtension.lowercased() == "zip" {
            createOpenZipButton()
        }
    }
    
    /// open text file from chat
    func loadTextView() {
        let textView = UITextView()
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        self.view.addSubview(textView)
        textView.autoPinEdgesToSuperviewSafeArea()
        textView.isEditable = false
        textView.text = self.textContent
    }
    
    /// import file from chat or sharing link
    func importNode() {
        if self.node == nil {
            return
        }
        
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            let navigationController = UIStoryboard(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as! MEGANavigationController
            self.present(navigationController, animated: true)
            
            if let browserVC = navigationController.viewControllers.first as? BrowserViewController,
               let node = self.node {
                browserVC.selectedNodesArray = [node]
                browserVC.browserAction = BrowserAction.import
            }
        }
    }
    
    func sendToChat() {
        if self.isLink == true && self.fileLink != nil {
            let navigationController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as! MEGANavigationController
            let sendToViewController = navigationController.viewControllers.first as? SendToViewController
            sendToViewController?.sendMode = SendMode.fileAndFolderLink
            self.sendLinkDelegate = SendLinkToChatsDelegate(link: self.fileLink!, navigationController: self.navigationController)
            sendToViewController?.sendToViewControllerDelegate = self.sendLinkDelegate
            self.present(navigationController, animated: true)
        } else {
            self.node?.mnz_sendToChat(in: self)
        }
    }
    
    
    func download() {
        if self.isLink == true && self.fileLink != nil {
            self.downloadFileLink()
        } else if self.chatId != ~UInt64.zero && self.messageId != ~UInt64.zero {
            CancellableTransferRouterOCWrapper().downloadChatNodes(self.node == nil ? [] : [self.node!], messageId: self.messageId, chatId: self.chatId, presenter: self)
        } else if self.node != nil {
            CancellableTransferRouterOCWrapper().downloadNodes([self.node!], presenter: self, isFolderLink: self.isLink)
        }
    }
    
    func updateAppearance() {
        self.view.backgroundColor = UIColor.mnz_background()
        self.openZipButton?.mnz_setupBasic(self.traitCollection)
    }
    
    func createOpenZipButton() {
        let openZipButton = UIButton.newAutoLayout()
        openZipButton.setTitle(NSLocalizedString("openButton", comment: "Button title to trigger the action of opening the file without downloading or opening it."),
                               for: .normal)
        openZipButton.mnz_setupBasic(self.traitCollection)
        self.view.addSubview(openZipButton)
        openZipButton.autoSetDimension(.width, toSize: 300)
        openZipButton.autoSetDimension(.height, toSize: 60)
        openZipButton.autoAlignAxis(toSuperviewAxis: .vertical)
        openZipButton.autoPinEdge(toSuperviewSafeArea: .bottom, withInset: UIDevice.current.iPad ? 32 : 16)
        openZipButton.addTarget(self, action: #selector(openZipInQLViewController), for: .touchUpInside)
        
        self.openZipButton = openZipButton
    }
    
    /// show system sharing view
    func presentActivityVC(_ activityItems: [Any], barButtonItem sender: UIBarButtonItem) {
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = sender
        
        self.present(activityVC, animated: true)
    }
        
    @IBAction func exportFileAction(_ sender: UIBarButtonItem) {
        if self.node != nil {
            // the file is in the cloud
            self.exportFile(from: self.node!, sender: sender)
        } else {
            // the file is from other place(share link or chat and download offline but not in the cloud)
            if self.filePath != nil {
                self.presentActivityVC([NSURL(fileURLWithPath: self.filePath!)], barButtonItem: sender)
            }
        }
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        TransfersWidgetViewController.sharedTransfer().resetToKeyWindow()
        
        self.dismiss(animated: true)
    }
    
    @IBAction func thumbnailTapped(_ sender: Any) {
        if self.outlineView?.isHidden == false {
            self.hideOutlineView(true)
            return
        }
        if self.collectionView.isHidden {
            if !self.thumbnailsPopulated {
                self.collectionView.reloadData()
                self.thumbnailsPopulated = true
            }
            self.collectionView.isHidden = false
            self.thumbnailBarButtonItem.image = UIImage(named: "pageView")
        } else {
            self.collectionView.isHidden = true
            self.thumbnailBarButtonItem.image = UIImage(named: "thumbnailsThin")
        }
    }
    
    @IBAction func outlineTapped(_ sender: Any) {
        self.hideOutlineView(!(self.outlineView?.isHidden ?? true))
    }
    
    @IBAction func actionsTapped(_ sender: UIBarButtonItem) {
        guard let node = self.node else { return }
        if MEGASdkManager.sharedMEGASdk().accessLevel(for: node) != MEGAShareType.accessUnknown {
            self.node = MEGASdkManager.sharedMEGASdk().node(forHandle: node.handle)
        }
        
        let displayMode = node.mnz_isInRubbishBin() ? DisplayMode.rubbishBin : DisplayMode.previewDocument
        let isBackupNode = MyBackupsOCWrapper().isBackupNode(node)
        let nodeActions = NodeActionViewController(node: node,
                                                   delegate: self,
                                                   isLink: self.isLink,
                                                   isPageView: self.collectionView.isHidden,
                                                   displayMode: displayMode,
                                                   isInVersionsView: self.isPreviewingVersion(),
                                                   isBackupNode: isBackupNode,
                                                   sender: sender)
        self.present(nodeActions, animated: true)
    }

    @IBAction func importAction(_ sender: Any) {
        self.importNode()
    }
    
    @IBAction func downloadAction(_ sender: Any) {
        self.download()
    }
    
    @objc func openZipInQLViewController() {
        guard let filePath = (self.nodeFilePath != nil ? self.nodeFilePath! : self.filePath) else { return }
        let previewController = MEGAQLPreviewController(filePath: filePath)
        self.dismiss(animated: true) {
            UIApplication.mnz_presentingViewController().present(previewController, animated:true)
        }
    }
    
    func isPreviewingVersion() -> Bool {
        if self.navigationController?.presentingViewController?.isKind(of: MEGANavigationController.self) == true {
            let viewcontrollers = self.navigationController?.presentingViewController?.children ?? []
            if viewcontrollers.last?.isKind(of: NodeVersionsViewController.self) == true {
                return true
            }
        }
        
        return false
    }
    
    // MARK: - SearchInPdfViewControllerProtocol
    
    func didSelectSearchResult(_ result: PDFSelection) {
        if !self.collectionView.isHidden {
            self.collectionView.isHidden = true
            self.thumbnailBarButtonItem.image = UIImage(named: "thumbnailsThin")
        }
        result.color = UIColor.systemYellow
        self.pdfView.setCurrentSelection(result, animate: true)
        self.pdfView.scaleFactor = self.pdfView.scaleFactorForSizeToFit
        if let page = result.pages.first {
            self.pdfView.go(to: page)
        }
    }
    
}

// MARK: - QLPreviewControllerDataSource

extension PreviewDocumentViewController: QLPreviewControllerDataSource {
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        if self.filePath != nil {
            return NSURL(fileURLWithPath: self.filePath!)
        } else {
            if previewDocumentTransfer?.path != nil {
                return NSURL(fileURLWithPath: previewDocumentTransfer!.path)
            } else {
                return NSURL(fileURLWithPath:self.nodeFilePath ?? "")
            }
        }
    }
    
}


// MARK: - QLPreviewControllerDelegate

extension PreviewDocumentViewController: QLPreviewControllerDelegate {
    
    func previewControllerWillDismiss(_ controller: QLPreviewController) {
        previewDocumentTransfer = nil
    }
    
    
}

// MARK: - MEGATransferDelegate

extension PreviewDocumentViewController: MEGATransferDelegate {
    
    func onTransferStart(_ api: MEGASdk, transfer: MEGATransfer) {
        previewDocumentTransfer = transfer
    }

    func onTransferUpdate(_ api: MEGASdk, transfer: MEGATransfer) {
        self.activityIndicator.stopAnimating()
        self.progressView.isHidden = false
        let percentage = transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue
        self.progressView.setProgress(percentage, animated: true)
    }

    func onTransferFinish(_ api: MEGASdk, transfer: MEGATransfer, error: MEGAError) {
        if error.type != MEGAErrorType.apiOk {
            return
        }
        
        if self.isViewLoaded && (self.view.window != nil) {
            self.loadPreview()
        }
    }
    
}

// MARK: - NodeActionViewControllerDelegate

extension PreviewDocumentViewController: NodeActionViewControllerDelegate {
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch action {
        case .exportFile:
            self.exportFileAction(sender as! UIBarButtonItem)
        case .download:
            self.download()
        case .info:
            let nodeInfoNavigation: MEGANavigationController = NodeInfoViewController.instantiate(withViewModel: self.createNodeInfoViewModel(withNode: node), delegate: self)
            self.present(nodeInfoNavigation, animated: true)
        case .favourite:
            let delegate: MEGAGenericRequestDelegate = MEGAGenericRequestDelegate(completion: { request, error in
                if error.type == MEGAErrorType.apiOk {
                    if request.numDetails == 1 {
                        QuickAccessWidgetManager().insertFavouriteItem(for: node)
                    } else {
                        QuickAccessWidgetManager().deleteFavouriteItem(for: node)
                    }
                }
            })
            MEGASdkManager.sharedMEGASdk().setNodeFavourite(node, favourite: !node.isFavourite, delegate: delegate)
        case .label:
            node.mnz_labelActionSheet(in: self)
        case .copy:
            node.mnz_copy(in: self)
        case .move:
            node.mnz_move(in: self)
        case .import:
            self.importNode()
        case .rename:
            node.mnz_renameNode(in: self) { request in
                self.title = request.name
            }
        case .moveToRubbishBin:
            node.mnz_askToMoveToTheRubbishBin(in: self)
        case .manageLink, .shareLink:
                if self.isLink == true && self.fileLink != nil {
                    self.presentActivityVC([self.fileLink!], barButtonItem: self.moreBarButtonItem)
                } else if MEGAReachabilityManager.isReachableHUDIfNot() {
                    CopyrightWarningViewController.presentGetLinkViewController(for: [node], in: UIApplication.mnz_presentingViewController())
                }
        case .removeLink:
            node.mnz_removeLink()
        case .sendToChat:
            self.sendToChat()
        case .pdfPageView, .pdfThumbnailView:
            self.thumbnailTapped(sender)
        case .search:
            self.searchTapped(sender)
        case .restore:
            self.dismiss(animated: true)
            node.mnz_restore()
        case .remove:
            node.mnz_remove(in: self, completion: nil)
        case .viewVersions:
            node.mnz_showVersions(in: self)
        default:
                break
        }
    }
    
}

// MARK: - NodeInfoViewControllerDelegate

extension PreviewDocumentViewController: NodeInfoViewControllerDelegate {
    
    func nodeInfoViewController(_ nodeInfoViewController: NodeInfoViewController, presentParentNode node: MEGANode) {
        self.dismiss(animated: true) {
            node.navigateToParentAndPresent()
        }
    }
    
    @IBAction func searchTapped(_ sender: Any) {
        let searchInPdfNavigation = UIStoryboard(name: "DocumentPreviewer", bundle: nil).instantiateViewController(withIdentifier: "SearchInPdfNavigationID") as! UINavigationController
        guard let searchInPdfVC = searchInPdfNavigation.viewControllers.first as? SearchInPdfViewController else { return }
        searchInPdfVC.pdfDocument = self.pdfView.document
        searchInPdfVC.delegate = self
        self.present(searchInPdfNavigation, animated: true)
    }
    
    func loadPdfKit(_ url: URL) {
        guard self.pdfView.document == nil else { return }
        self.pdfView.isHidden = false
        self.pdfView.delegate = self
        self.activityIndicator.isHidden = true
        self.progressView.isHidden = true
        self.imageView.isHidden = true
        
        self.pdfView.document = PDFDocument(url: url)
        self.pdfView.autoScales = true
        self.pdfView.minScaleFactor = self.pdfView.scaleFactorForSizeToFit
        if let document = self.pdfView.document {
            self.outlineView?.outline = PDFOutlineItem.getOutline(document)
            self.outlineView?.reload()
        }
        
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        if self.node != nil {
            if self.node?.mnz_isInRubbishBin() == true {
                self.setToolbarItems([self.thumbnailBarButtonItem, flexibleItem, self.searchBarButtonItem], animated: true)
            } else {
                if self.pdfView.document?.outlineRoot != nil {
                    self.setToolbarItems([self.thumbnailBarButtonItem, flexibleItem, self.outlineBarButtonItem, flexibleItem, self.searchBarButtonItem, flexibleItem, (MEGASdkManager.sharedMEGASdk().accessLevel(for: self.node!) == MEGAShareType.accessOwner ? self.exportFileBarButtonItem : self.importBarButtonItem)], animated: true)
                } else {
                    self.setToolbarItems([self.thumbnailBarButtonItem, flexibleItem, self.searchBarButtonItem, flexibleItem, (MEGASdkManager.sharedMEGASdk().accessLevel(for: self.node!) == MEGAShareType.accessOwner ? self.exportFileBarButtonItem : self.importBarButtonItem)], animated: true)
                }
            }
        } else {
            self.setToolbarItems([self.thumbnailBarButtonItem, flexibleItem, self.searchBarButtonItem, flexibleItem, self.exportFileBarButtonItem], animated:true)
        }
        self.navigationController?.setToolbarHidden(false, animated: true)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapGesture(_:)))
        doubleTap.delegate = self
        doubleTap.numberOfTapsRequired = 2
        
        let defaultDoubleTapGesture = self.pdfView.mnz_firstTapGesture(withNumberOfTaps: 2)
        defaultDoubleTapGesture?.require(toFail: doubleTap)
        
        self.pdfView.addGestureRecognizer(doubleTap)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapGesture(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.delegate = self
        singleTap.require(toFail: doubleTap)
        self.pdfView.addGestureRecognizer(singleTap)
        
        let fingerprint = self.pdfView.document?.documentURL?.path == nil ? nil : MEGASdkManager.sharedMEGASdk().fingerprint(forFilePath: self.pdfView.document!.documentURL!.path)
        if fingerprint != nil && !fingerprint!.isEmpty {
            
            if let document = self.pdfView.document,
               let destinationPage: NSNumber = MEGAStore.shareInstance().fetchMediaDestination(withFingerprint: fingerprint!)?.destination,
               let page = document.page(at: Int(destinationPage.uintValue) - 1) {
                self.pdfView.go(to: page)
            }
        } else {
            self.pdfView.goToFirstPage(nil)
        }
    }
    
    @objc func doubleTapGesture(_ tapGestureRecognizer: UITapGestureRecognizer) {
        let newScale = CGFloat(self.pdfView.scaleFactor > 1.0 ? 1.0 : 2.0)
        UIView.animate(withDuration: 0.3) {
            if newScale > 1.0 {
                var tapPoint = tapGestureRecognizer.location(in: self.pdfView)
                if let currentPage = self.pdfView.currentPage {
                    tapPoint = self.pdfView.convert(tapPoint, to: currentPage)
                }
                
                var zoomRect = CGRect.zero
                zoomRect.size.width = self.pdfView.frame.size.width / newScale
                zoomRect.size.height = self.pdfView.frame.size.height / newScale
                zoomRect.origin.x = tapPoint.x - zoomRect.size.width / 2
                zoomRect.origin.y = tapPoint.y - zoomRect.size.height / 2
                self.pdfView.scaleFactor = newScale
                if let currentPage = self.pdfView.currentPage {
                    self.pdfView.go(to: zoomRect, on: currentPage)
                }
            } else {
                self.pdfView.scaleFactor = self.pdfView.scaleFactorForSizeToFit
            }
        }
    }
    
    @objc func singleTapGesture(_ tapGestureRecognizer: UITapGestureRecognizer) {
        if self.pdfView.currentSelection != nil {
            self.pdfView.clearSelection()
        } else {
            if self.navigationController?.isToolbarHidden == true {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.setToolbarHidden(false, animated: true)
            } else {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.setToolbarHidden(true, animated: true)
            }
        }
    }
}


// MARK: - UIGestureRecognizerDelegate

extension PreviewDocumentViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer.isKind(of: UITapGestureRecognizer.self) &&
            otherGestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) {
            return false
        }
        return true
    }
    
}

// MARK: - PDFViewDelegate

extension PreviewDocumentViewController: PDFViewDelegate {
    
    func pdfViewWillClick(onLink sender: PDFView, with url: URL) {
        MEGALinkManager.linkURL = url as URL
        MEGALinkManager.processLinkURL(url as URL)
    }
    
}

// MARK: - UICollectionViewDelegate

extension PreviewDocumentViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let pageRect = self.pdfView.document?.page(at:indexPath.item)?.pageRef?.getBoxRect(CGPDFBox.mediaBox) else {
            return CGSize.zero
        }
        let thumbnailWidth: CGFloat = (CGFloat(collectionView.frame.size.width) - collectionView.layoutMargins.right - collectionView.layoutMargins.left - 50) / CGFloat(3.0)
        let ratio: CGFloat = CGFloat(pageRect.size.width) / thumbnailWidth
        return CGSizeMake(thumbnailWidth, pageRect.size.height / ratio)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.pdfView.scaleFactor = self.pdfView.scaleFactorForSizeToFit
        if let page = self.pdfView.document?.page(at: indexPath.item) {
            self.pdfView.go(to: page)
        }
        
        self.thumbnailBarButtonItem.image = UIImage(named: "thumbnailsThin")
        self.collectionView.isHidden = true
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath) {
            let imageView: UIImageView = cell.viewWithTag(100) as! UIImageView
            let cachedImageKey = NSNumber(value: indexPath.item)
            let cachedImage = self.thumbnailCache.object(forKey: cachedImageKey)
            if cachedImage != nil {
                imageView.image = cachedImage
            } else {
                if let page = self.pdfView.document?.page(at: indexPath.item) {
                    let thumbnail = page.thumbnail(of: CGSize(width: 100, height: 100),
                                                   for: PDFDisplayBox.mediaBox)
                    imageView.image = thumbnail
                    self.thumbnailCache.setObject(thumbnail, forKey: cachedImageKey)
                }
            }
    }
    
}


// MARK: - UICollectionViewDataSource

extension PreviewDocumentViewController: UICollectionViewDataSource {
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return self.pdfView.document?.pageCount ?? 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailPageID", for: indexPath) as UICollectionViewCell
        let pageLabel = cell.viewWithTag(1) as! UILabel
        pageLabel.text = "\(indexPath.item + 1)"
        return cell
    }
    
}



extension PreviewDocumentViewController {
    
    @objc func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        return NodeInfoViewModel(withNode: node)
    }
    
    // download from a file sharing link
    @objc func downloadFileLink() {
        guard let fileLink = self.fileLink, let linkUrl = URL(string: fileLink) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }
    
}
