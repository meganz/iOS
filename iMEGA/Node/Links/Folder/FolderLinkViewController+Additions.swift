import Accounts
import ChatRepo
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGASwift

extension FolderLinkViewController {
    @objc func makeFolderLinkViewModel() -> FolderLinkViewModel {
        let downloadFileRepository = DownloadFileRepository(
            sdk: MEGASdk.shared,
            sharedFolderSdk: MEGASdk.sharedFolderLink
        )
        let saveMediaUseCase = SaveMediaToPhotosUseCase(
            downloadFileRepository: downloadFileRepository,
            fileCacheRepository: FileCacheRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            chatNodeRepository: ChatNodeRepository.newRepo,
            downloadChatRepository: DownloadChatRepository.newRepo
        )
        let viewModel = FolderLinkViewModel(
            folderLinkUseCase: FolderLinkUseCase(
                transferRepository: TransferRepository.newRepo,
                nodeRepository: NodeRepository.newRepo,
                requestStatesRepository: RequestStatesRepository.newRepo
            ),
            saveMediaUseCase: saveMediaUseCase
        )
        
        viewModel.invokeCommand = { [weak self] in self?.executeCommand($0) }
        
        return viewModel
    }
    
    @objc func onViewDidLoad() {
        viewModel.dispatch(.onViewDidLoad)
    }
    
    @objc func containsMediaFiles() -> Bool {
        nodesArray.toNodeEntities().contains {
            $0.mediaType != nil
        }
    }

    func importFilesFromFolderLink() {
        ImportLinkRouter(
            isFolderLink: true,
            nodes: targetNodes(),
            presenter: self)
        .start()
    }
    
    func showMediaDiscovery() {
        var link = publicLinkString
        if let linkEncryptedString {
            link = linkEncryptedString
        }
        guard let parentNode, let link else { return }
        MediaDiscoveryRouter(viewController: self, parentNode: parentNode, folderLink: link).start()
    }

    func showActions(for node: MEGANode, from sender: UIButton) {
        let isBackupNode = BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        ).isBackupNode(node.toNodeEntity())

        let nodeActionViewController = NodeActionViewController(
            node: node,
            delegate: self,
            displayMode: .nodeInsideFolderLink,
            isIncoming: false,
            isBackupNode: isBackupNode,
            sender: sender
        )

        self.present(nodeActionViewController, animated: true)
    }

    func select() {
        let enableEditing = isListViewModeSelected() ? !(self.flTableView?.tableView.isEditing ?? false) : !(self.flCollectionView?.collectionView.allowsMultipleSelection ?? false)
        setEditMode(enableEditing)
    }

    func showSendToChat() {
        if SAMKeychain.password(forService: "MEGA", account: "sessionV3") != nil {
            guard let navigationController =
                    UIStoryboard(
                        name: "Chat",
                        bundle: nil
                    ).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
                  let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
                return
            }
            
            sendToViewController.sendMode = .fileAndFolderLink
            self.sendLinkDelegate = SendLinkToChatsDelegate(
                link: linkEncryptedString ?? publicLinkString ?? "",
                navigationController: navigationController
            )
            sendToViewController.sendToViewControllerDelegate = self.sendLinkDelegate
            
            self.navigationController?.pushViewController(sendToViewController, animated: true)
            viewModel.dispatch(.trackSendToChatFolderLink)
        } else {
            MEGALinkManager.linkSavedString = linkEncryptedString ?? publicLinkString ?? ""
            MEGALinkManager.selectedOption = .sendNodeLinkToChat

            navigationController?.pushViewController(
                OnboardingUSPViewController(), animated: true)
            viewModel.dispatch(.trackSendToChatFolderLinkNoAccountLogged)
        }
    }

    func showShareLink(from sender: UIBarButtonItem) {
        let link = linkEncryptedString ?? publicLinkString
        guard let link = link else { return }
        let activityVC = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = sender

        present(activityVC, animated: true)
    }

    func saveToPhotos(nodes: [NodeEntity]) {
        SaveToPhotosCoordinator
            .customProgressSVGErrorMessageDisplay(
                isFolderLink: true,
                configureProgress: {
                    TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                })
            .saveToPhotos(nodes: nodes)
    }
    
    @objc func selectedCountTitle() -> String {
        guard let selectedCount = selectedNodesArray?.count,
              selectedCount > 0 else {
            return Strings.Localizable.selectTitle
        }
        return Strings.Localizable.General.Format.itemsSelected(selectedCount)
    }
    
    @objc func updateAppearance() {
        view.backgroundColor = TokenColors.Background.page
        
        if let navController = navigationController {
            AppearanceManager.forceNavigationBarUpdate(navController.navigationBar)
            AppearanceManager.forceToolbarUpdate(navController.toolbar)
        }
        
        if navigationItem.titleView != nil, let titleViewSubtitle {
            setNavigationTitleView(subTitle: titleViewSubtitle)
        }
    }
    
    @objc func setNavigationTitleView(subTitle: String?) {
        navigationItem.titleView = UILabel.customNavigationBarLabel(
            title: parentNode?.name ?? Strings.Localizable.folderLink,
            subtitle: subTitle,
            traitCollection: traitCollection
        )
        
        navigationItem.titleView?.sizeToFit()
    }
    
    @objc func configureToolbarButtons() {
        folderLinkToolbarConfigurator = FolderLinkToolbarConfigurator(
            importAction: importButtonPressed,
            downloadAction: downloadButtonPressed,
            saveToPhotosAction: saveToPhotosButtonPressed,
            shareLinkAction: shareLinkButtonPressed
        )
        
        refreshToolbarButtonsStatus(true)
    }
    
    @objc func refreshToolbarButtonsStatus(_ enabled: Bool) {
        let selectedNodes = (selectedNodesArray as? [MEGANode]) ?? []
        let items = folderLinkToolbarConfigurator?.toolbarItems(
            allNodes: nodesArray,
            selectedNodes: selectedNodes
        ) ?? []
        
        setToolbarItems(items, animated: false)
        navigationController?.setToolbarHidden(items.isEmpty, animated: false)
        
        folderLinkToolbarConfigurator?.setToolbarButtonsEnabled(enabled)
    }
    
    @objc func updateToolbarItemsEnabled(_ enabled: Bool) {
        folderLinkToolbarConfigurator?.setToolbarButtonsEnabled(enabled)
    }
    
    private func targetNodes() -> [MEGANode] {
        if let selected = selectedNodesArray as? [MEGANode], !selected.isEmpty {
            return selected
        }
        return parentNode.map { [$0] } ?? []
    }
    
    func importButtonPressed(_ button: UIBarButtonItem) {
        importFilesFromFolderLink()
    }
    
    func downloadButtonPressed(_ button: UIBarButtonItem) {
        let nodes = targetNodes()
        guard !nodes.isEmpty else { return }
        download(nodes)
        setEditMode(false)
    }
    
    private var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    private var permissionRouter: some PermissionAlertRouting {
        PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler)
    }
    
    func saveToPhotosButtonPressed(_ button: UIBarButtonItem) {
        guard let nodeArray = isEditingModeEnabled() ? selectedNodesArray as? [MEGANode] : nodesArray else { return }
        
        permissionHandler.photosPermissionWithCompletionHandler { [weak self] granted in
            guard let self else { return }
            if granted {
                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                
                viewModel.dispatch(.saveToPhotos(nodeArray.toNodeEntities()))
            } else {
                permissionRouter.alertPhotosPermission()
            }
        }
    }
    
    func shareLinkButtonPressed(_ button: UIBarButtonItem) {
        guard let link = linkEncryptedString ?? publicLinkString else { return }

        let activityVC = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = button

        present(activityVC, animated: true)
    }
    
    // MARK: - Loading spinner
    
    @objc func setupSpinner() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc func startLoading() {
        activityIndicator.startAnimating()
    }
    
    @objc func stopLoading() {
        activityIndicator.stopAnimating()
    }
    
    private func isFromFolderLink(nodeHandle: HandleEntity) -> MEGANode? {
        nodesArray.first { $0.handle == nodeHandle }
    }
}

// MARK: - Ads
extension FolderLinkViewController: AdsSlotViewControllerProtocol {
    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        SingleItemAsyncSequence(
            item: AdsSlotConfig(displayAds: true)
        ).eraseToAnyAsyncSequence()
    }
}

extension FolderLinkViewController: ViewType {
    public func executeCommand(_ command: FolderLinkViewModel.Command) {
        switch command {
        case .nodeDownloadTransferFinish(let handleEntity):
            guard let node = isFromFolderLink(nodeHandle: handleEntity) else { return }
            didDownloadTransferFinish(node)
        case .nodesUpdate(let nodeEntities):
            guard
                let parentNodeEntity = parentNode?.toNodeEntity(),
                parentNodeEntity.shouldProcessOnNodeEntitiesUpdate(withChildNodes: nodesArray.map({ $0.toNodeEntity() }), updatedNodes: nodeEntities)
            else { return }
            reloadUI()
        case .linkUnavailable(let linkUnavailableReason):
            switch linkUnavailableReason {
            case .downETD:
                showUnavailableLinkViewWithError(.etdDown)
            case .userETDSuspension:
                showUnavailableLinkViewWithError(.userETDSuspension)
            case .copyrightSuspension:
                showUnavailableLinkViewWithError(.userCopyrightSuspension)
            case .generic:
                showUnavailableLinkViewWithError(.generic)
            }
        case .invalidDecryptionKey:
            handleInvalidDecryptionKey()
        case .decryptionKeyRequired:
            showDecryptionAlert()
        case .loginDone:
            handleLoginDone()
        case .fetchNodesDone(let validKey):
            handleFetchNodesDone(validKey)
        case .fetchNodesFailed:
            handleFetchNodesFailed()
        case .logoutDone:
            handleLogout()
        case .fileAttributeUpdate(let handleEntity):
            handleFileAttributeUpdate(handleEntity)
        case .fetchNodesStarted:
            startLoading()
        case .endEditingMode:
            setEditMode(false)
            refreshToolbarButtonsStatus(true)
        case .showSaveToPhotosError(let error):
            SVProgressHUD.show(
                MEGAAssets.UIImage.saveToPhotos,
                status: error
            )
        }
    }
}
