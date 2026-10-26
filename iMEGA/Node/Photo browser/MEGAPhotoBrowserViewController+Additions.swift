import Accounts
import ContentLibraries
import FirebaseCrashlytics
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGAAudioPlayer
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPhotos
import MEGARepo
import MEGASwift
import MEGASwiftUI
import MEGAVideoPlayer
import SwiftUI
import Transfer
import UIKit

extension MEGAPhotoBrowserViewController {
    @objc func makeViewModel() -> PhotoBrowserViewModel {
        makeViewModel(paginator: nil, fullListProvider: nil)
    }

    func makeViewModel(
        paginator: PhotoBrowserPaginator?,
        fullListProvider: PhotoBrowserFullListProvider?
    ) -> PhotoBrowserViewModel {
        let viewModel = PhotoBrowserViewModel(
            photoBrowserUseCase: PhotoBrowserUseCase(nodeRepository: NodeRepository.newRepo),
            paginator: paginator,
            fullListProvider: fullListProvider)
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
    
    /// The queue "previous / next" moves through: every video the browser's query reaches, so a
    /// paginated browser does not skip the ones it has not paged to.
    ///
    /// Falls back to the loaded window whenever the full list cannot stand in for it — including
    /// when the list no longer holds the node being played, which a deletion, a hide or a move out
    /// of the query can do. A queue without its own current item has nothing to step from.
    private func videoQueue(containing node: MEGANode) async -> [MEGANode] {
        let queue = await fullVideoQueue(containing: node) ?? loadedVideoQueue()

        // Nodes belonging to the folder-link SDK have to be authorized before they can be streamed,
        // otherwise their local link carries no node key and the HTTP server answers 404
        let authorized = queue.map { video in
            api == MEGASdk.sharedFolderLink ? (api.authorizeNode(video) ?? video) : video
        }
        return authorized.isEmpty ? [node] : authorized
    }

    /// Asked for only once the full list is out of the running: on a paginated browser the provider
    /// holds entities, so every read of `allPhotos` maps the whole window back to SDK nodes.
    private func loadedVideoQueue() -> [MEGANode] {
        dataProvider.allPhotos.filter { $0.isFile() && ($0.name ?? "").fileExtensionGroup.isVideo }
    }

    private func fullVideoQueue(containing node: MEGANode) async -> [MEGANode]? {
        guard let entities = await fullMediaList(of: .videos, containing: node.toNodeEntity()) else {
            return nil
        }
        let nodes = await megaNodes(for: entities, in: api)
        // Mapping drops what the SDK cannot resolve locally, which the check on the entities could
        // not see.
        return nodes.contains { $0.handle == node.handle } ? nodes : nil
    }

    /// Off the main actor: this is one `sdk.node(forHandle:)` per entity, and the full list is
    /// every video in the account rather than the browser's window.
    private nonisolated func megaNodes(for entities: [NodeEntity], in sdk: MEGASdk) async -> [MEGANode] {
        entities.toMEGANodes(in: sdk)
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

            if await isBlockedWhileOffline(node) { return }

            if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .videoPlayerRevamp) || DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosVideoPlayerRevamp) {
                let allVideoNodes = await videoQueue(containing: node)
                // Dismissed while the queue was being fetched: nothing left to present from.
                guard viewIfLoaded?.window != nil else { return }
                let playerViewModel = MEGAPlayerViewModel(
                    player: MEGAAVPlayer.liveValue(
                        for: node,
                        within: allVideoNodes,
                    )
                )
                let playerVC = MEGAPlayerViewController(
                    viewModel: playerViewModel,
                    pictureInPicturePresenter: { UIApplication.mnz_presentingViewController() }
                )
                playerViewModel.moreAction = { [weak self, weak playerVC] playableNode in
                    guard let self,
                          let playerVC,
                          let node = playableNode as? MEGANode else {
                        return
                    }

                    let delegate = offlineAware(self.playerNodeActionDelegate(presenter: playerVC))

                    let isBackUpNode = BackupsOCWrapper().isBackupNode(node)
                    let controller = NodeActionViewController(
                        node: node,
                        delegate: delegate,
                        displayMode: displayMode,
                        isInVersionsView: isPreviewingVersion(),
                        isBackupNode: isBackUpNode,
                        isFromSharedItem: isFromSharedItem,
                        sender: playerVC
                    )
                    controller.accessoryActionDelegate = defaultNodeAccessoryActionDelegate
                    playerVC.present(controller, animated: true)

                }
                playerViewModel.onPlaybackStarted = { MEGAAudioPlayerSession.beginInterruption() }
                playerViewModel.onPlaybackEnded = { MEGAAudioPlayerSession.endInterruption(shouldResume: true) }
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

                // IOS-11914: thread share-link context to the underlying MEGAAVViewController so the analytics fire knows the link type.
                if let avController = controller as? MEGAAVViewController {
                    switch displayMode {
                    case .fileLink:
                        avController.fileLink = publicLink
                    case .albumLink:
                        avController.isFromAlbumLink = true
                    default:
                        break
                    }
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
    
    /// The node-action delegate for the revamped player's `…` sheet
    private func playerNodeActionDelegate(presenter: UIViewController) -> any NodeActionViewControllerDelegate {
        if displayMode == .fileLink {
            return FileLinkActionViewControllerDelegate(link: publicLink, viewController: presenter)
        }
        return NodeActionViewControllerGenericDelegate(
            viewController: presenter,
            isNodeFromFolderLink: displayMode == .nodeInsideFolderLink,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: presenter)
        )
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
            
        case .nodeInsideFolderLink:
            SaveToPhotosCoordinator(
                messageDisplay: MEGAPhotoBrowserErrorMessageDisplay(showSnackBar: { [weak self] message in
                    self?.showSnackBar(snackBar: SnackBar(message: message))
                }),
                isFolderLink: true)
            .saveToPhotos(nodes: [node.toNodeEntity()])
            
        case .albumLink:
            SaveToPhotosCoordinator(
                messageDisplay: MEGAPhotoBrowserErrorMessageDisplay(showSnackBar: { [weak self] message in
                    self?.showSnackBar(snackBar: SnackBar(message: message))
                }),
                isFolderLink: false,
                nodeProvider: PublicAlbumNodeProvider.shared)
            .saveToPhotos(nodes: [node.toNodeEntity()])

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
        if #available(iOS 26.0, *) {
            viewModel.dispatch(.downloadFileLink(linkUrl))
        }
    }
    
    @objc func downloadFromFolderLink(_ node: MEGANode) {
        let nodeEntity = node.toNodeEntity()
        DownloadLinkRouter(nodes: [nodeEntity], isFolderLink: true, presenter: self).start()
        viewModel.dispatch(.nodeDownloadStarted(nodeEntity))
    }

    @objc func openSlideShow() {
        DIContainer.tracker.trackAnalyticsEvent(with: PlaySlideshowMenuToolbarEvent())
        Task { @MainActor [weak self] in
            guard let self else { return }
            let photos = await fullMediaList(of: .images, containing: dataProvider.currentPhotoNodeEntity)
            // Dismissed while the query ran: there is nothing to present from any more.
            guard viewIfLoaded?.window != nil else { return }
            SlideShowRouter(dataProvider: dataProvider, presenter: self, photos: photos).start()
        }
    }

    /// The whole sequence of `mediaType`, for the consumers that cannot work from the loaded
    /// window. `nil` leaves the caller on the array it already has.
    ///
    /// Behind a progress indicator: on a paginated browser this is a query over the whole account,
    /// and the control the user pressed would otherwise sit there looking dead. The indicator
    /// comes down with the query either way — leaving the browser cancels it, so it never hangs
    /// over the screen the user moved on to.
    private func fullMediaList(
        of mediaType: MediaTimelineFilterEntity.MediaType,
        containing node: NodeEntity?
    ) async -> [NodeEntity]? {
        guard viewModel.loadsFullMediaList else { return nil }
        SVProgressHUD.show()
        defer { SVProgressHUD.dismiss() }
        guard let nodes = await viewModel.fullMediaList(of: mediaType),
              let node, nodes.contains(node)
        else { return nil }
        return nodes
    }
    
    @objc func isSlideShowEnabled() async -> Bool {
        switch displayMode {
        case .cloudDrive, .sharedItem, .albumLink, .nodeInsideFolderLink, .photosTimeline, .photosAlbum, .recents:
            return await dataProvider.currentPhoto()?.name?.fileExtensionGroup.isImage == true
        default:
            return false
        }
    }
    
    @objc func download(_ node: MEGANode, isFolderLink: Bool) {
        CancellableTransferRouter(presenter: self, transfers: transferViewEntities(fromNodes: [node]), transferType: .download, isFolderLink: isFolderLink).start()
        
        // After start downloading as usual, try start background task support if possible.
        viewModel.dispatch(.nodeDownloadStarted(node.toNodeEntity()))
    }
    
    private func transferViewEntities(fromNodes nodes: [MEGANode]) -> [CancellableTransfer] {
        nodes.map {
            CancellableTransfer(
                handle: $0.handle,
                name: $0.name,
                appData: TransferMetaDataEntity.makeAvailableOffline.rawValue,
                priority: false,
                isFile: $0.isFile(),
                type: .download
            )
        }
    }
    
    @objc func activateSlideShowButton(barButtonItem: UIBarButtonItem?) {
        Task {
            if await isSlideShowEnabled() {
                barButtonItem?.image = UIImage(systemName: "play.rectangle")
                barButtonItem?.isEnabled = true
                
                if #available(iOS 26.0, *) {
                    barButtonItem?.hidesSharedBackground = false
                }
            } else {
                barButtonItem?.image = nil
                barButtonItem?.isEnabled = false
                
                if #available(iOS 26.0, *) {
                    barButtonItem?.hidesSharedBackground = true
                }
            }
        }
    }
    
    @objc func hideBarButton(barButtonItem: UIBarButtonItem?) {
        barButtonItem?.image = nil
        barButtonItem?.isEnabled = false
        if #available(iOS 26.0, *) {
            barButtonItem?.hidesSharedBackground = true
        }
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

    @objc func updateNavigationBar(_ navigationBar: UINavigationBar) {
        if #available(iOS 26.0, *) {
            AppearanceManager.setupLiquidGlassNavigationBar(navigationBar)
        } else {
            AppearanceManager.forceNavigationBarUpdate(navigationBar)
        }
    }

    @objc func updateNavigationAndStatusBarBackground(_ navigationBar: UINavigationBar, statusBar: UIView) {
        if #available(iOS 26.0, *) {
            statusBar.backgroundColor = .clear
            AppearanceManager.setupLiquidGlassNavigationBar(navigationBar)
        } else {
            statusBar.backgroundColor = UIColor.surface1Background()
            navigationBar.backgroundColor = UIColor.surface1Background()
        }
    }
    
    @objc func sendLinkToChat() {
        let credentialUseCase = CredentialUseCase(repo: CredentialRepository.newRepo)
        if credentialUseCase.hasSession() {
            sendLinkToChatWhenLogin()
        } else {
            MEGALinkManager.linkSavedString = !encryptedLink.isEmpty ? encryptedLink : publicLink
            MEGALinkManager.selectedOption = .sendNodeLinkToChat

            let onboardingVC = OnboardingUSPViewController()
            if let navigation = navigationController {
                navigation.pushViewController(onboardingVC, animated: true)
            } else {
                let navigation = MEGANavigationController(rootViewController: onboardingVC)
                navigation.addRightCancelButton()
                present(navigation, animated: true)
            }
        }
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
        // Both the photo and its cache key are resolved now, synchronously. Resolving by index after
        // the await would pick up whatever has moved into that slot meanwhile — a prepended page
        // shifts every index — and the image would land on the wrong page.
        let handle = dataProvider.handle(at: index)
        guard handle != .invalid, let cacheKey = dataProvider.cacheKey(at: index) else { return }
        Task {
            guard let node = await dataProvider.photoNode(forHandle: handle) else { return }
            configureNode(intoImage: node, cacheKey: cacheKey)
        }
    }
}

extension MEGAPhotoBrowserViewController {
    static func photoBrowser(currentPhoto: NodeEntity, 
                             allPhotos: [NodeEntity],
                             displayMode: DisplayMode,
                             isFromSharedItem: Bool = false) -> MEGAPhotoBrowserViewController {
        let (sdk, nodeProvider) = nodeAccess(for: displayMode)
        return photoBrowser(
            with: PhotoBrowserDataProvider(
                currentPhoto: currentPhoto,
                allPhotos: allPhotos,
                sdk: sdk,
                nodeProvider: nodeProvider),
            sdk: sdk,
            displayMode: displayMode,
            isFromSharedItem: isFromSharedItem,
            paginator: nil,
            fullListProvider: nil)
    }

    /// Opens on a paginated sequence: the browser is handed the contiguous run around the tapped
    /// photo and grows it from its own cursors.
    ///
    /// Provider and paginator are both built from `context.nodes`, here and nowhere else. They
    /// count positions in the same array, and a provider built from anything else — the caller's
    /// own copy, say — would put the two index spaces out of step with nothing in either to notice.
    static func photoBrowser(currentPhoto: NodeEntity,
                             context: PhotoBrowserPaginationContext,
                             mediaTimelineUseCase: some MediaTimelineUseCaseProtocol,
                             displayMode: DisplayMode) -> MEGAPhotoBrowserViewController {
        let (sdk, nodeProvider) = nodeAccess(for: displayMode)
        return photoBrowser(
            with: PhotoBrowserDataProvider(
                currentPhoto: currentPhoto,
                allPhotos: context.nodes,
                sdk: sdk,
                nodeProvider: nodeProvider),
            sdk: sdk,
            displayMode: displayMode,
            isFromSharedItem: false,
            paginator: PhotoBrowserPaginator(context: context, useCase: mediaTimelineUseCase),
            fullListProvider: PhotoBrowserFullListProvider(context: context, useCase: mediaTimelineUseCase))
    }

    private static func photoBrowser(
        with dataProvider: PhotoBrowserDataProvider,
        sdk: MEGASdk,
        displayMode: DisplayMode,
        isFromSharedItem: Bool,
        paginator: PhotoBrowserPaginator?,
        fullListProvider: PhotoBrowserFullListProvider?
    ) -> MEGAPhotoBrowserViewController {
        let browser = MEGAPhotoBrowserViewController.photoBrowser(
            with: dataProvider,
            api: sdk,
            displayMode: displayMode,
            isFromSharedItem: isFromSharedItem
        )
        // Ahead of the lazy getter that would otherwise make one without it. Nothing has read the
        // view model at this point: the storyboard has only been instantiated.
        if let paginator {
            browser.viewModel = browser.makeViewModel(
                paginator: paginator,
                fullListProvider: fullListProvider)
        }
        browser.needsReload = true
        return browser
    }

    private static func nodeAccess(for displayMode: DisplayMode) -> (MEGASdk, any MEGANodeProviderProtocol) {
        switch displayMode {
        case .nodeInsideFolderLink:
            (.sharedFolderLink, FolderLinkMEGANodeProvider(sdk: .sharedFolderLink))
        case .albumLink:
            (.shared, PublicAlbumNodeProvider.shared)
        default:
            (.shared, DefaultMEGANodeProvider(sdk: .shared))
        }
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
            // A paginated browser holds only part of the sequence, so neither number can come from
            // the loaded array; `nil` means this entry point holds all of it, as today.
            let position = viewModel.titlePosition(forIndex: dataProvider.currentIndex)
                ?? (index: dataProvider.currentIndex + 1, total: dataProvider.count)
            let formattedText = Strings.Localizable.Media.Photo.Browser.indexOfTotalFiles(position.total)
            subtitle = formattedText.replacingOccurrences(
                of: "[A]",
                with: String(format: "%lu", position.index))
        }

        let isLiquidGlassSupported = if #available(iOS 26.0, *) {
            true
        } else {
            false
        }

        let rootView: NavigationTitleView?
        if let name = node.name {
            rootView = .init(title: name, subtitle: subtitle, isLiquidGlassSupported: isLiquidGlassSupported)
        } else if let subtitle {
            rootView = .init(title: subtitle, isLiquidGlassSupported: isLiquidGlassSupported)
        } else {
            rootView = nil
        }
             
        guard let rootView else {
            navigationItem.titleView = nil
            return
        }

        let titleViewContent: UIView
        if isLiquidGlassSupported {
            titleViewContent = rootView.toWrappedUIView(shouldEnableGlassEffect: true, padding: .init(top: TokenSpacing._3, leading: TokenSpacing._5, bottom: TokenSpacing._3, trailing: TokenSpacing._5))
        } else {
            let hostController = UIHostingController(rootView: rootView)
            guard let titleView = hostController.view else { return }
            titleView.backgroundColor = .clear
            titleViewContent = titleView
        }

        navigationItem.titleView = PhotoBrowserNavigationTitleContainerView(
            contentView: titleViewContent,
            maxWidthWhenIndicatorVisible: { [weak self] in self?.titleMaximumWidthForTransferIndicator() ?? 0 }
        )
    }

    fileprivate func titleMaximumWidthForTransferIndicator() -> CGFloat {
        let navBarWidth = navigationController?.navigationBar.bounds.width
            ?? (view.bounds.width > 0 ? view.bounds.width : (view.window ?? UIApplication.mnz_keyWindow())?.bounds.width ?? 0)
        return navBarWidth * NavigationTitleMetrics.maxWidthRatioWhenIndicatorVisible
    }
}

private enum NavigationTitleMetrics {
    /// Maximum fraction of the navigation bar width the title may occupy while the
    /// transfer indicator is visible. The remainder is reserved for the back button,
    /// the indicator, and any other right bar items.
    static let maxWidthRatioWhenIndicatorVisible: CGFloat = 0.55
}

private final class PhotoBrowserNavigationTitleContainerView: UIView {
    private let contentView: UIView
    private let maxWidthWhenIndicatorVisible: () -> CGFloat
    private var monitorTask: Task<Void, Never>?
    private var currentMaxWidth: CGFloat?

    init(contentView: UIView, maxWidthWhenIndicatorVisible: @escaping @MainActor () -> CGFloat) {
        self.contentView = contentView
        self.maxWidthWhenIndicatorVisible = maxWidthWhenIndicatorVisible
        super.init(frame: .zero)
        backgroundColor = .clear

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        applyCurrentVisibility()
        startMonitoring()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        monitorTask?.cancel()
    }

    override var intrinsicContentSize: CGSize {
        let measured = contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let width = currentMaxWidth.map { min(measured.width, $0) } ?? measured.width
        return CGSize(width: width, height: measured.height)
    }

    private func startMonitoring() {
        guard let publisher = SharedTransferIndicator.isVisiblePublisher else { return }
        monitorTask = Task { [weak self] in
            for await _ in publisher.values {
                guard !Task.isCancelled else { return }
                self?.applyCurrentVisibility()
            }
        }
    }

    private func applyCurrentVisibility() {
        let newMaxWidth: CGFloat? = TransferIndicatorBarItemConfigurator.isIndicatorDisplayed ? maxWidthWhenIndicatorVisible() : nil
        guard currentMaxWidth != newMaxWidth else { return }
        currentMaxWidth = newMaxWidth
        invalidateIntrinsicContentSize()
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

// MARK: - Offline mode

extension MEGAPhotoBrowserViewController {

    /// Wraps a node action sheet delegate so the actions that need a connection prompt instead of
    /// running while offline
    private func offlineAware(
        _ delegate: some NodeActionViewControllerDelegate
    ) -> any NodeActionViewControllerDelegate {
        OfflineAwareNodeActionDelegate(
            wrapping: delegate,
            offlineActionGuard: OfflineActionGuard(
                isNewOfflineModeEnabled: DIContainer.featureFlagProvider.isNewOfflineModeEnabled
            )
        )
    }

    /// Warns instead of opening a player for a video with no local copy while offline
    private func isBlockedWhileOffline(_ node: MEGANode) async -> Bool {
        let openGuard = OfflineFileOpenGuard(
            isNewOfflineModeEnabled: DIContainer.featureFlagProvider.isNewOfflineModeEnabled,
            networkMonitorUseCase: NetworkMonitorUseCase(repo: NetworkMonitorRepository.newRepo),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
        )

        guard openGuard.isActive, await openGuard.shouldBlockOpening(node.toNodeEntity()) else { return false }

        showSnackBar(message: Strings.Localizable.CloudDrive.Offline.fileNotAvailableOffline)
        return true
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
            delegate: offlineAware(delegate),
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
            exportFile(from: node, sender: sender, isFolderLink: displayMode == .nodeInsideFolderLink)
        }
    }
    
    @objc func didPressCenterToolbarButton(_ sender: UIBarButtonItem) async {
        guard let node = await dataProvider.currentPhoto() else {
            return
        }
        
        switch displayMode {
        case .fileLink:
            saveToPhotos(node: node)
        case .sharedItem, .cloudDrive, .photosAlbum, .photosTimeline, .recents:
            openSlideShow()
        default:
            break
        }
    }

    @objc func configureBarButtonImages() {
        self.customActionsButton?.image = MEGAAssets.UIImage.moreHorizontal
        
        switch displayMode {
        case .fileLink:
            // Save to MEGA, matching the file link screen it was opened from.
            self.leftToolbarItem?.image = MEGALinkManager.isLinkRevampEnabled
                ? MEGAAssets.UIImage.uploadToCloud
                : MEGAAssets.UIImage.folderArrow
            self.centerToolbarItem?.image = MEGAAssets.UIImage.photosApp
        case .photosTimeline:
            // The picker hands its own index straight back as a browser index, so it cannot work
            // against a paginated range, and Android has dropped the entry altogether. Hidden for
            // the whole timeline rather than only the paginated one, so there is one behaviour.
            hideBarButton(barButtonItem: leftToolbarItem)
        default:
            self.leftToolbarItem?.image = MEGAAssets.UIImage.thumbnailsThin
        }
        // Matches `didPressRightToolbarButton`: only these modes do not export the file.
        self.rightToolbarItem?.image = switch displayMode {
        // Share link, matching the file link screen it was opened from.
        case .fileLink where MEGALinkManager.isLinkRevampEnabled: MEGAAssets.UIImage.link01
        case .fileLink, .albumLink, .nodeInsideFolderLink: MEGAAssets.UIImage.externalLink
        default: MEGAAssets.UIImage.downloadToDisk
        }

        self.saveToolbarItem.image = MEGAAssets.UIImage.photosApp
        self.importToolbarItem.image = MEGAAssets.UIImage.folderArrow
        self.forwardToolbarItem.image = MEGAAssets.UIImage.cornerUpLeft
        self.exportFileToolbarItem.image = MEGAAssets.UIImage.downloadToDisk
    }

    @objc class func photoBrowserDataProvider(currentPhoto: MEGANode, mediaNodes: [MEGANode], sdk: MEGASdk) -> PhotoBrowserDataProvider {
        PhotoBrowserDataProvider(currentPhoto: currentPhoto.toNodeEntity(), allPhotos: mediaNodes.toNodeEntities(), sdk: sdk, nodeProvider: DefaultMEGANodeProvider(sdk: sdk))
    }
    
    @objc class func photoBrowserDataProvider(currentIndex: Int, mediaNodes: [MEGANode], sdk: MEGASdk, displayMode: DisplayMode) -> PhotoBrowserDataProvider? {
        guard currentIndex < mediaNodes.count else {
            return nil
        }
        if displayMode == .chatAttachment {
            // By index, not by node: chat builds its list one entry per message, so the same node
            // can appear twice, and `MEGANode.isEqual:` matches on handle — looking the node up
            // would land on the first of the two and open the wrong message's attachment.
            return PhotoBrowserDataProvider(currentIndex: currentIndex, allPhotos: mediaNodes, sdk: sdk)
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

    @objc func didMoveToIndex(_ index: Int) {
        viewModel.dispatch(.didMoveToIndex(index))
    }

    @objc func didBeginScrolling() {
        viewModel.dispatch(.didBeginScrolling)
    }

    @objc func didSettleScrolling() {
        viewModel.dispatch(.didSettleScrolling)
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
        case .photosAppended(let nodes):
            let added = dataProvider.appendPhotos(nodes)
            didAppendPhotos(UInt(added))
            Task { await reloadTitle() }
        case .photosPrepended(let nodes):
            // Order matters: the provider grows and moves its current index first, then the scroll
            // view is shifted to match it. The view model holds pages back until the scroll view has
            // settled, so this never runs mid-deceleration.
            let inserted = dataProvider.prependPhotos(nodes)
            guard inserted > 0 else { return }
            didPrependPhotos(UInt(inserted))
            Task { await reloadTitle() }
        case .titleNeedsRefresh:
            Task { await reloadTitle() }
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
