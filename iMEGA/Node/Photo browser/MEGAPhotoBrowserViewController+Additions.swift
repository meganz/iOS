import Accounts
import FirebaseCrashlytics
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPhotos
import MEGASwift
import MEGASwiftUI
import MEGAVideoPlayer
import SwiftUI
import UIKit

extension MEGAPhotoBrowserViewController {
    @objc func makeViewModel() -> PhotoBrowserViewModel {
        let viewModel = PhotoBrowserViewModel(photoBrowserUseCase: PhotoBrowserUseCase(nodeRepository: NodeRepository.newRepo))
        viewModel.invokeCommand = { [weak self] in self?.executeCommand($0) }
        return viewModel
    }
    
    @objc func createNodeInfoViewModel(withNode node: MEGANode) -> NodeInfoViewModel {
        NodeInfoViewModel(
            withNode: node,
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            backupUseCase: BackupsUseCase(
                backupsRepository: BackupsRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            )
        )
    }
    
    func subtitle(fromDate date: Date) -> String {
        DateFormatter.fromTemplate("MMMM dd • HH:mm").localisedString(from: date)
    }
    
    @objc func backgroundColor() -> UIColor {
        TokenColors.Background.page
    }
    
    @objc func fullScreenBackgroundColor() -> UIColor {
        MEGAAssets.UIColor.pageBgColorDark
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

            if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .videoPlayerRevamp) {
                let playerViewModel = MEGAPlayerViewModel(
                    player: MEGAAVPlayer.liveValue(node: node)
                )
                let playerVC = MEGAPlayerViewController(
                    viewModel: playerViewModel
                )
                playerViewModel.moreAction = { [weak playerVC] playableNode in
                    guard let playerVC, let playableNode else { return }
                    NodeOpener(navigationController: nil)
                        .openNodeActions(
                            playableNode.nodeHandle,
                            presentingController: playerVC,
                            sender: playerVC
                        )
                }
                playerVC.modalPresentationStyle = .overFullScreen
                present(playerVC, animated: true)
            } else {
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
                    present(alertController, animated: true)

                    let error = NSError(
                        domain: "nz.mega.megaphotobrowserviewcontroller",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Unexpected error when open video from node: \(node.toNodeEntity())"]
                    )
                    Crashlytics.crashlytics().record(error: error)
                    return
                }

                controller.modalPresentationStyle = .overFullScreen
                present(controller, animated: true)
            }
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
    
    func configureMediaAttachment(inChatId chatId: HandleEntity, messages: [MEGAChatMessage]) {
        self.chatId = chatId
        self.messages = messages
    }
    
    @objc func forwardMessage(at index: Int) {
        let sendToNC = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as! UINavigationController
        let sendToVC = sendToNC.viewControllers.first as! SendToViewController
        sendToVC.sendMode = .forward
        sendToVC.messages = [messages[index]]
        sendToVC.sourceChatId = chatId
        sendToVC.completion = { _, _ in
            SVProgressHUD.showSuccess(withStatus: Strings.Localizable.Chat.forwardedMessage)
        }
        present(sendToNC, animated: true, completion: nil)
    }
    
    @objc var currentMessageId: ChatIdEntity {
        messages[dataProvider.currentIndex].messageId
    }

    var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    @objc func saveToPhotos(node: MEGANode) {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        switch displayMode {
        case .chatAttachment, .chatSharedFiles:
            SaveToPhotosCoordinator(
                messageDisplay: CustomProgressSVGErrorMessageDisplay(),
                isFolderLink: false)
            .saveToPhotosChatNode(
                handle: node.handle,
                messageId: self.currentMessageId,
                chatId: self.chatId
            )
        case .fileLink:
            guard let linkUrl = URL(string: self.publicLink) else { return }
            let fileLink = FileLinkEntity(linkURL: linkUrl)
            
            SaveToPhotosCoordinator(
                messageDisplay: CustomProgressSVGErrorMessageDisplay(),
                isFolderLink: true)
            .saveToPhotos(fileLink: fileLink)
            
        default:
            SaveToPhotosCoordinator(
                messageDisplay: MEGAPhotoBrowserErrorMessageDisplay(showSnackBar: { [weak self] message in
                    self?.showSnackBar(snackBar: SnackBar(message: message))
                }),
                isFolderLink: false)
            .saveToPhotos(nodes: [node.toNodeEntity()])
        }
    }
    
    @objc func downloadFileLink() {
        guard let linkUrl = URL(string: publicLink) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: self).start()
    }

    @objc func openSlideShow() {
        DIContainer.tracker.trackAnalyticsEvent(with: PlaySlideshowMenuToolbarEvent())
        SlideShowRouter(dataProvider: dataProvider, presenter: self).start()
    }
    
    @objc func isSlideShowEnabled() async -> Bool {
        switch displayMode {
        case .cloudDrive, .sharedItem, .albumLink, .nodeInsideFolderLink, .photosTimeline, .photosAlbum:
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
            presenter: self)
        .hideNodes([node.toNodeEntity()])
    }
        
    @objc func unhide(node: MEGANode) {
        HideFilesAndFoldersRouter(presenter: self)
            .unhideNodes([node.toNodeEntity()])
    }
    
    @objc func addToAlbum(node: MEGANode) {
        AddToCollectionRouter(
            presenter: self,
            mode: .album,
            selectedPhotos: [node.toNodeEntity()])
        .start()
    }
    
    @objc func addToCollection(node: MEGANode) {
        AddToCollectionRouter(
            presenter: self,
            mode: .collection,
            selectedPhotos: [node.toNodeEntity()])
        .start()
    }
    
    @objc func importNode(node: MEGANode) {
        ImportLinkRouter(
            isFolderLink: displayMode == .nodeInsideFolderLink,
            nodes: [node],
            presenter: self).start()
    }
}

extension MEGAPhotoBrowserViewController: MEGAPhotoBrowserPickerDelegate {
    public func updateCurrentIndex(to newIndex: UInt) {
        if dataProvider.shouldUpdateCurrentIndex(toIndex: Int(newIndex)) {
            dataProvider.updateCurrentIndexTo(Int(newIndex))
            needsReload = true
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
                             displayMode: DisplayMode,
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
    private func shouldUpdateNodes(_ nodeEntities: [NodeEntity]) -> Bool {
        guard nodeEntities.isNotEmpty else { return false }
        return nodeEntities.removedChangeTypeNodes().isNotEmpty ||
                nodeEntities.hasModifiedAttributes() ||
                nodeEntities.hasModifiedPublicLink() ||
                nodeEntities.hasModifiedFavourites()
    }
    
    /// Check if node updates require photos views to reload
    ///
    /// Node changes types containing anything other than `favourite`, `attributes` or `publicLink` will require reloading the image views again.
    private func shouldReloadUI(nodes: [NodeEntity]) -> Bool {
        guard nodes.isNotEmpty else { return false }
        return nodes.contains {
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
            ImportLinkRouter(
                isFolderLink: false,
                nodes: [node],
                presenter: self).start()
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
        case .chatAttachment, .chatSharedFiles:
            exportMessageFile(
                from: node,
                messageId: currentMessageId,
                chatId: chatId,
                sender: sender
            )
        default:
            exportFile(from: node, sender: sender)
        }
    }
    
    @objc func didPressCenterToolbarButton(_ sender: UIBarButtonItem) async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        switch displayMode {
        case .fileLink:
            saveToPhotos(node: node)
        case .sharedItem, .cloudDrive, .photosAlbum, .photosTimeline:
            openSlideShow()
        default:
            break
        }
    }
    
    @objc class func photoBrowserDataProvider(currentPhoto: MEGANode, mediaNodes: [MEGANode], sdk: MEGASdk) -> PhotoBrowserDataProvider {
        PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(), allPhotos: mediaNodes.toNodeEntities(), sdk: sdk, nodeProvider: DefaultMEGANodeProvider(sdk: sdk))
    }
    
    @objc class func photoBrowserDataProvider(currentIndex: Int, mediaNodes: [MEGANode], sdk: MEGASdk, displayMode: DisplayMode) -> PhotoBrowserDataProvider? {
        guard currentIndex < mediaNodes.count else {
            return nil
        }
        if displayMode == .chatAttachment {
            return PhotoBrowserDataProvider(currentPhoto: mediaNodes[currentIndex], allPhotos: mediaNodes, sdk: sdk)
        } else {
            return PhotoBrowserDataProvider(currentPhoto: mediaNodes[currentIndex].toNodeEntity(), allPhotos: mediaNodes.toNodeEntities(), sdk: sdk, nodeProvider: DefaultMEGANodeProvider(sdk: sdk))
        }
    }
}

// MARK: - Ads
extension MEGAPhotoBrowserViewController: AdsSlotViewControllerProtocol {
    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        SingleItemAsyncSequence(
            item: AdsSlotConfig(displayAds: true)
        ).eraseToAnyAsyncSequence()
    }
}

extension MEGAPhotoBrowserViewController: SnackBarLayoutCustomizable {
    var additionalSnackBarBottomInset: CGFloat {
        toolbar?.bounds.height ?? 0
    }
}

// MARK: - Displatch actions
extension MEGAPhotoBrowserViewController {
    @objc func onViewDidLoad() {
        viewModel.dispatch(.onViewDidLoad)
    }
    
    @objc func onViewWillAppear() {
        viewModel.dispatch(.onViewWillAppear)
    }
    
    @objc func onViewWillDisappear() {
        viewModel.dispatch(.onViewWillDisappear)
    }
}

// MARK: - Handle commands
extension MEGAPhotoBrowserViewController: ViewType {
    public func executeCommand(_ command: PhotoBrowserViewModel.Command) {
        switch command {
        case .nodesUpdate(let nodeEntities):
            guard shouldUpdateNodes(nodeEntities) else { return }
            let remainingNodesToUpdateCount = dataProvider.removePhotos(in: nodeEntities)
            
            if remainingNodesToUpdateCount == 0 {
                dismiss(animated: true)
            } else {
                dataProvider.updatePhotos(in: nodeEntities)
                if shouldReloadUI(nodes: nodeEntities) {
                    reloadUI()
                }
            }
        }
    }
}

private struct MEGAPhotoBrowserErrorMessageDisplay: SaveToPhotosMessageDisplay {
    private let showSnackBar: (String) -> Void
    
    init(showSnackBar: @escaping (String) -> Void) {
        self.showSnackBar = showSnackBar
    }
    
    func showProgress() {}
    
    func showError(_ error: any Error) {
        guard let error = error as? SaveMediaToPhotosErrorEntity else { return }
        
        if error == .fileDownloadInProgress {
           showSnackBar(error.localizedDescription)
        } else if error != .cancelled {
            SVProgressHUD.dismiss()
            SVProgressHUD.show(
                MEGAAssets.UIImage.saveToPhotos,
                status: error.localizedDescription
            )
        }
    }
}
