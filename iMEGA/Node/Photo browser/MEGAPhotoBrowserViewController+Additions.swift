import Accounts
import Combine
import FirebaseCrashlytics
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI
import UIKit

extension MEGAPhotoBrowserViewController {
    @objc func makeViewModel() -> PhotoBrowserViewModel {
        PhotoBrowserViewModel()
    }
    
    @objc func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        NodeInfoViewModel(
            withNode: node,
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            featureFlagProvider: DIContainer.featureFlagProvider)
    }
    
    func subtitle(fromDate date: Date) -> String {
        DateFormatter.fromTemplate("MMMM dd • HH:mm").localisedString(from: date)
    }
    
    @objc func backgroundColor() -> UIColor {
        MEGAAppColor.Black._000000.uiColor
    }
    
    @objc func freeUpSpace(
        onImageViewCache cache: NSCache<NSNumber, UIScrollView>,
        imageViewsZoomCache: NSCache<NSNumber, NSNumber>,
        scrollView: UIScrollView
    ) {
        SVProgressHUD.show()
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        cache.removeAllObjects()
        imageViewsZoomCache.removeAllObjects()
        SVProgressHUD.dismiss(withDelay: 0.5)
    }
    
    @objc func rootPresentingViewController() -> UIViewController? {
        var curPresentingVC = presentingViewController
        var prePresentingVC: UIViewController?
        
        while curPresentingVC != nil {
            prePresentingVC = curPresentingVC
            curPresentingVC = curPresentingVC?.presentingViewController
        }
        
        return prePresentingVC
    }
    
    @objc func playCurrentVideo() async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        if node.mnz_isPlayable() {
            guard !MEGAChatSdk.sharedChatSdk.mnz_existsActiveCall else {
                Helper.cannotPlayContentDuringACallAlert()
                return
            }
            
            guard let controller = node.mnz_viewControllerForNode(
                inFolderLink: displayMode == .nodeInsideFolderLink,
                fileLink: nil) else {
                let alertController = UIAlertController(
                    title: Strings.Localizable.unknownError,
                    message: Strings.Localizable.somethingWentWrong,
                    preferredStyle: .alert
                )
                let cancelAction = UIAlertAction(
                    title: Strings.Localizable.ok,
                    style: .cancel
                )
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true)
                
                let error = NSError.init(
                    domain: "nz.mega.megaphotobrowserviewcontroller",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Unexpected error when open video from node: \(node.toNodeEntity())"]
                )
                Crashlytics.crashlytics().record(error: error)
                return
            }
            
            controller.modalPresentationStyle = .overFullScreen
            present(controller, animated: true)
        } else {
            let controller = UIAlertController(
                title: Strings.Localizable.fileNotSupported,
                message: Strings.Localizable.messageFileNotSupported,
                preferredStyle: .alert
            )
            let cancelAction = UIAlertAction(
                title: Strings.Localizable.ok,
                style: .cancel,
                handler: { [weak self] _ in
                    guard let self else { return }
                    self.view.layoutIfNeeded()
                    self.reloadUI()
                }
            )
            controller.addAction(cancelAction)
            self.present(controller, animated: true)
        }
    }
    
    @objc func configureMediaAttachment(forMessageId messageId: HandleEntity, inChatId chatId: HandleEntity, messagesIds: [HandleEntity]) {
        self.chatId = chatId
        self.messageId = messageId
        self.messagesIds = messagesIds
    }
    
    var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    @objc func saveToPhotos(node: MEGANode) {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        
        permissionHandler.photosPermissionWithCompletionHandler {[weak self] granted in
            guard let self else { return }
            if granted {
                let saveMediaUseCase = dataProvider.makeSaveMediaToPhotosUseCase(for: displayMode)
                
                let completionBlock: (Result<Void, SaveMediaToPhotosErrorEntity>) -> Void = { result in
                    if case let .failure(error) = result, error != .cancelled {
                        SVProgressHUD.dismiss()
                        SVProgressHUD.show(
                            .saveToPhotos,
                            status: error.localizedDescription
                        )
                    }
                }
                
                switch self.displayMode {
                case .chatAttachment, .chatSharedFiles:
                    Task(priority: .userInitiated) {
                        do {
                            try await saveMediaUseCase.saveToPhotosChatNode(
                                handle: node.handle,
                                messageId: self.messageId,
                                chatId: self.chatId
                            )
                        } catch let error as SaveMediaToPhotosErrorEntity {
                            if error != .cancelled {
                                await SVProgressHUD.dismiss()
                                SVProgressHUD.show(
                                    .saveToPhotos,
                                    status: error.localizedDescription
                                )
                            }
                        }
                    }
                case .fileLink:
                    guard let linkUrl = URL(string: self.publicLink) else { return }
                    let fileLink = FileLinkEntity(linkURL: linkUrl)
                    saveMediaUseCase.saveToPhotos(fileLink: fileLink, completion: completionBlock)
                default:
                    Task { @MainActor in
                        do {
                            SnackBarRouter.shared.present(snackBar: SnackBar(message: Strings.Localizable.General.SaveToPhotos.started(1)))
                            try await saveMediaUseCase.saveToPhotos(nodes: [node.toNodeEntity()])
                        } catch let error as SaveMediaToPhotosErrorEntity where error == .fileDownloadInProgress {
                            SnackBarRouter.shared.dismissSnackBar(immediate: true)
                            SnackBarRouter.shared.present(snackBar: SnackBar(message: error.localizedDescription))
                        } catch let error as SaveMediaToPhotosErrorEntity where error != .cancelled {
                            await SVProgressHUD.dismiss()
                            SVProgressHUD.show(
                                .saveToPhotos,
                                status: error.localizedDescription
                            )
                        } catch {
                            MEGALogError("[MEGAPhotoBrowserViewController] Error saving media nodes: \(error)")
                        }
                    }
                }
            } else {
                PermissionAlertRouter
                    .makeRouter(deviceHandler: permissionHandler)
                    .alertPhotosPermission()
            }
        }
    }
    
    @objc func downloadFileLink() {
        guard let linkUrl = URL(string: publicLink) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }
    
    @objc func updateMessageId(to newIndex: UInt) {
        if messagesIds.isNotEmpty {
            guard let newMessageId = messagesIds[safe: Int(newIndex)] as? HandleEntity else { return }
            messageId = newMessageId
        }
    }

    @objc func openSlideShow() {
        DIContainer.tracker.trackAnalyticsEvent(with: PlaySlideshowMenuToolbarEvent())
        SlideShowRouter(dataProvider: dataProvider, presenter: self).start()
    }
    
    @objc func isSlideShowEnabled() async -> Bool {
        switch displayMode {
        case .cloudDrive, .sharedItem, .albumLink, .nodeInsideFolderLink:
            return await dataProvider.currentPhoto()?.name?.fileExtensionGroup.isImage == true
        default:
            return false
        }
    }
    
    @objc func activateSlideShowButton(barButtonItem: UIBarButtonItem?) {
        Task {
            if await isSlideShowEnabled() {
                barButtonItem?.image = UIImage(systemName: "play.rectangle")
                barButtonItem?.isEnabled = true
            } else {
                barButtonItem?.image = nil
                barButtonItem?.isEnabled = false
            }
        }
    }
    
    @objc func hideSlideShowButton(barButtonItem: UIBarButtonItem?) {
        barButtonItem?.image = nil
        barButtonItem?.isEnabled = false
    }
    
    @objc func viewNodeInFolder(_ node: MEGANode) {
        guard let parentNode = MEGASdk.sharedSdk.node(forHandle: node.parentHandle),
              parentNode.isFolder() else {
            return
        }
        openFolderNode(parentNode, isFromViewInFolder: true)
    }
    
    func openFolderNode(_ node: MEGANode, isFromViewInFolder: Bool) {
        
        let factory = CloudDriveViewControllerFactory.make()
        let vc = factory.build(
            parentNode: node.toNodeEntity(),
            config: .init(
                displayMode: displayMode(node: node, isFromViewInFolder: isFromViewInFolder),
                isFromViewInFolder: isFromViewInFolder
            )
        )
        if let vc {
            present(vc, animated: true)
        }
    }
    
    func displayMode(node: MEGANode, isFromViewInFolder: Bool) -> DisplayMode {
        if node.mnz_isInRubbishBin() && isFromViewInFolder {
            return .rubbishBin
        } else {
            return .cloudDrive
        }
    }
    
    @objc func clearNodeOnTransfers(_ node: MEGANode) {
        if let navController = presentingViewController as? MEGANavigationController,
           let transfersController = navController.viewControllers.last as? TransfersWidgetViewController {
            transfersController.clear(node)
        } else if let tabBarController = presentingViewController as? MainTabBarController,
                  let navController = tabBarController.selectedViewController as? MEGANavigationController,
                  let transfersController = navController.viewControllers.last as? TransfersWidgetViewController {
            transfersController.clear(node)
        }
    }
    
    @objc func showRemoveLinkWarning(_ node: MEGANode) {
        let router = ActionWarningViewRouter(
            presenter: self,
            nodes: [node.toNodeEntity()],
            actionType: .removeLink,
            onActionStart: {
                SVProgressHUD.show()
            }, 
            onActionFinish: {
                switch $0 {
                case .success(let message):
                    SVProgressHUD.showSuccess(withStatus: message)
                case .failure:
                    SVProgressHUD.dismiss()
                }
            }
        )
        router.start()
    }
    
    @objc func presentGetLink(for nodes: [MEGANode]) {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        GetLinkRouter(presenter: self,
                      nodes: nodes).start()
    }
    
    @objc func hide(node: MEGANode) {
        viewModel.trackHideNodeMenuEvent()
        
        HideFilesAndFoldersRouter(
            presenter: self,
            snackBarPresentation: .router(SnackBarRouter.shared))
        .hideNodes([node.toNodeEntity()])
    }
        
    @objc func unhide(node: MEGANode) {
        Task {
            let nodeActionUseCase = NodeActionUseCase(repo: NodeActionRepository.newRepo)
            _ = await nodeActionUseCase.unhide(nodes: [node].toNodeEntities())
        }
    }
}

extension MEGAPhotoBrowserViewController: MEGAPhotoBrowserPickerDelegate {
    public func updateCurrentIndex(to newIndex: UInt) {
        if dataProvider.shouldUpdateCurrentIndex(toIndex: Int(newIndex)) {
            dataProvider.updateCurrentIndexTo(Int(newIndex))
            needsReload = true
            updateMessageId(to: newIndex)
        }
    }
}

extension MEGAPhotoBrowserViewController {
    
    @objc func loadNode(for index: Int) {
        Task {
            guard let node = await dataProvider.photoNode(at: index) else {
                return
            }
            configureNode(intoImage: node, nodeIndex: UInt(index))
        }
    }
}

extension MEGAPhotoBrowserViewController {
    static func photoBrowser(currentPhoto: NodeEntity, 
                             allPhotos: [NodeEntity],
                             displayMode: DisplayMode = .cloudDrive,
                             isFromSharedItem: Bool = false) -> MEGAPhotoBrowserViewController {
        
        let sdk: MEGASdk
        let nodeProvider: any MEGANodeProviderProtocol
        switch displayMode {
        case .nodeInsideFolderLink:
            sdk = .sharedFolderLink
            nodeProvider = FolderLinkMEGANodeProvider(sdk: sdk)
        case .albumLink:
            sdk = .shared
            nodeProvider = PublicAlbumNodeProvider.shared
        default:
            sdk = .shared
            nodeProvider = DefaultMEGANodeProvider(sdk: sdk)
        }
        
        let browser = MEGAPhotoBrowserViewController.photoBrowser(
            with: PhotoBrowserDataProvider(
                currentPhoto: currentPhoto,
                allPhotos: allPhotos,
                sdk: sdk,
                nodeProvider: nodeProvider),
            api: sdk,
            displayMode: displayMode, 
            isFromSharedItem: isFromSharedItem
        )
        browser.needsReload = true
        return browser
    }
}

extension MEGAPhotoBrowserViewController {
    @objc func updateProviderNodeEntities(nodes: [MEGANode]) {
        DispatchQueue.main.async {
            self.dataProvider.convertToNodeEntities(from: nodes)
        }
    }
    
    @objc func reloadTitle() async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        let subtitle: String?
        switch displayMode {
        case .fileLink:
            subtitle = Strings.Localizable.fileLink
        case .chatAttachment where node.creationTime != nil:
            guard let creationTime = node.creationTime else {
                subtitle = nil
                break
            }
            subtitle = self.subtitle(fromDate: creationTime)
        default:
            let formattedText = Strings.Localizable.Media.Photo.Browser.indexOfTotalFiles(dataProvider.count)
            subtitle = formattedText.replacingOccurrences(
                of: "[A]",
                with: String(format: "%lu", dataProvider.currentIndex + 1))
        }
        
        let rootView: NavigationTitleView?
        if let name = node.name {
            rootView = .init(title: name, subtitle: subtitle)
        } else if let subtitle {
            rootView = .init(title: subtitle)
        } else {
            rootView = nil
        }
             
        guard let rootView else {
            navigationItem.titleView = nil
            return
        }
        
        let hostController = UIHostingController(rootView: rootView)
        let titleView = hostController.view
        titleView?.backgroundColor = .clear
        navigationItem.titleView = titleView
        navigationItem.titleView?.sizeToFit()
    }
}

// MARK: - OnNodesUpdate
extension MEGAPhotoBrowserViewController {
    @objc func handleNodeUpdates(fromNodes nodeList: MEGANodeList?) {
        guard let nodeList, shouldUpdateNodes(nodes: nodeList) else { return }
        
        Task { [weak self] in
            guard let self else { return }
            let remainingNodesToUpdateCount = await dataProvider.removePhotos(in: nodeList)
            
            if remainingNodesToUpdateCount == 0 {
                dismiss(animated: true)
            } else {
                dataProvider.updatePhotos(in: nodeList)
                if shouldReloadUI(nodes: nodeList) {
                    reloadUI()
                }
            }
        }
    }
    
    private func shouldUpdateNodes(nodes: MEGANodeList) -> Bool {
        let nodeEntities = nodes.toNodeEntities()
        guard nodeEntities.isNotEmpty else { return false }
        return nodeEntities.removedChangeTypeNodes().isNotEmpty ||
                nodeEntities.hasModifiedAttributes() ||
                nodeEntities.hasModifiedPublicLink() ||
                nodeEntities.hasModifiedFavourites()
    }
    
    /// Check if node updates require photos views to reload
    ///
    /// Node changes types containing anything other than `favourite`, `attributes` or `publicLink` will require reloading the image views again.
    private func shouldReloadUI(nodes: MEGANodeList) -> Bool {
        let nodeEntities = nodes.toNodeEntities()
        guard nodeEntities.isNotEmpty else { return false }
        return nodeEntities.contains {
            $0.changeTypes.subtracting([.favourite, .attributes, .publicLink]).isNotEmpty
        }
    }
}

// MARK: - IBActions
extension MEGAPhotoBrowserViewController {
    
    @objc func didPressActionsButton(_ sender: UIBarButtonItem, delegate: (any NodeActionViewControllerDelegate)?) async {
        guard let node = await dataProvider.currentPhoto(),
              let delegate else {
            return
        }
        
        let isBackUpNode = BackupsOCWrapper().isBackupNode(node)
        let controller = NodeActionViewController(
            node: node,
            delegate: delegate,
            displayMode: displayMode,
            isInVersionsView: isPreviewingVersion(),
            isBackupNode: isBackUpNode,
            isFromSharedItem: self.isFromSharedItem,
            sender: sender
        )
        controller.accessoryActionDelegate = defaultNodeAccessoryActionDelegate
        
        present(controller, animated: true)
    }
    
    @objc func didPressLeftToolbarButton(_ sender: UIBarButtonItem) async {
        
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        switch displayMode {
        case .fileLink:
            node.mnz_fileLinkImport(from: self, isFolderLink: false)
        default:
            didPressAllMediasButton(sender)
        }
    }
    
    @objc func didPressRightToolbarButton(_ sender: UIBarButtonItem) async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        switch displayMode {
        case .fileLink:
            shareFileLink()
        case .albumLink, .nodeInsideFolderLink:
            openSlideShow()
        default:
            exportFile(from: node, sender: sender)
        }
    }
    
    @objc func didPressExportFile(_ sender: UIBarButtonItem) async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        switch displayMode {
        case .fileLink:
            exportFile(from: node, sender: sender)
        default:
            exportMessageFile(from: node, messageId: messageId, chatId: chatId, sender: sender)
        }
    }
    
    @objc func didPressCenterToolbarButton(_ sender: UIBarButtonItem) async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        switch displayMode {
        case .fileLink:
            saveToPhotos(node: node)
        case .sharedItem, .cloudDrive:
            openSlideShow()
        default:
            break
        }
    }
}

// MARK: - Ads
extension MEGAPhotoBrowserViewController: AdsSlotViewControllerProtocol {
    public var adsSlotPublisher: AnyPublisher<AdsSlotConfig?, Never> {
        Just(
            AdsSlotConfig(
                adsSlot: .sharedLink,
                displayAds: true,
                isAdsCookieEnabled: calculateAdCookieStatus
            )
        ).eraseToAnyPublisher()
    }
    
    private func calculateAdCookieStatus() async -> Bool {
        do {
            let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo)
            let bitmap = try await cookieSettingsUseCase.cookieSettings()
            
            let cookiesBitmap = CookiesBitmap(rawValue: bitmap)
            return cookiesBitmap.contains(.ads) && cookiesBitmap.contains(.adsCheckCookie)
        } catch {
            return false
        }
    }
}
