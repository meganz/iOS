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

    private var isCloudDriveRevampEnabled: Bool {
        DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosCloudDriveRevamp)
    }

    @objc func isDecryptedFolder() -> Bool {
        parentNode?.isNodeKeyDecrypted() ?? false
    }
    
    private func isUndecryptedNodeSelected() -> Bool {
        let selectedNodes = selectedNodesArray as? [MEGANode] ?? []
        return selectedNodes.first(where: { !$0.isNodeKeyDecrypted() }) != nil
    }
    
    @objc func containsUndecryptedNode() -> Bool {
        nodesArray.first(where: { !$0.isNodeKeyDecrypted() }) != nil
    }
    
    @objc func isDecryptedFolderAndNoUndecryptedNodeSelected() -> Bool {
        isDecryptedFolder() && !isUndecryptedNodeSelected()
    }
    
    @objc func makeFolderLinkViewModel(link: String) -> FolderLinkViewModel {
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
            publicLink: link,
            folderLinkUseCase: FolderLinkUseCase(
                transferRepository: TransferRepository.newRepo,
                nodeRepository: NodeRepository.newRepo,
                requestStatesRepository: RequestStatesRepository.newRepo
            ),
            folderLinkFlowUseCase: FolderLinkFlowUseCase(),
            saveMediaUseCase: saveMediaUseCase,
            viewMode: isListViewModeSelected() ? .list : .thumbnail
        )
        
        viewModel.invokeCommand = { [weak self] in self?.executeCommand($0) }
        
        return viewModel
    }
    
    @objc func startMonitoringNodeUpdates() {
        viewModel.dispatch(.monitorNodeUpdates)
    }
    
    @objc func startLoadingFolderLink() {
        viewModel.dispatch(.startLoadingFolderLink)
    }
    
    @objc func confirmDecryptionKey(_ key: String) {
        viewModel.dispatch(.confirmDecryptionKey(key))
    }
    
    @objc func cancelConfirmingDecryptionKey() {
        viewModel.dispatch(.cancelConfirmingDecryptionKey)
    }
    
    @objc func containsMediaFiles() -> Bool {
        nodesArray.toNodeEntities().contains {
            $0.mediaType != nil
        }
    }

    @objc func configureImages() {
        selectAllBarButtonItem?.image = isCloudDriveRevampEnabled ? MEGAAssets.UIImage.checkStack : MEGAAssets.UIImage.selectAllItems
        moreBarButtonItem.image = MEGAAssets.UIImage.moreNavigationBar
    }
    
    func resetNodeActionSelectionAndImportFilesFromFolderLink() {
        let isEditing = navigationItem.rightBarButtonItem == editBarButtonItem
        if !isEditing {
            selectedNodesArray = []
        }
        importFilesFromFolderLink()
    }

    func importFilesFromFolderLink() {
        ImportLinkRouter(
            isFolderLink: true,
            nodes: targetNodes(),
            presenter: self) { [weak self] in
                self?.setEditMode(false)
            }
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
            guard let sendToChatNavigationController =
                    UIStoryboard(
                        name: "Chat",
                        bundle: nil
                    ).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
                  let sendToViewController = sendToChatNavigationController.viewControllers.first as? SendToViewController else {
                return
            }
            
            sendToViewController.sendMode = .fileAndFolderLink
            self.sendLinkDelegate = SendLinkToChatsDelegate(link: linkEncryptedString ?? publicLinkString ?? "")
            sendToViewController.sendToViewControllerDelegate = self.sendLinkDelegate
            
            present(sendToChatNavigationController, animated: true)
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
            title: parentNode?.nameAfterDecryptionCheck() ?? Strings.Localizable.folderLink,
            subtitle: subTitle,
            traitCollection: traitCollection
        )
        
        navigationItem.titleView?.sizeToFit()
    }
    
    @objc func
    configureToolbarButtons() {
        folderLinkToolbarConfigurator = FolderLinkToolbarConfigurator(
            importAction: { [weak self] button in
                self?.importButtonPressed(button)
            },
            downloadAction: { [weak self] button in
                self?.downloadButtonPressed(button)
            },
            saveToPhotosAction: { [weak self] button in
                self?.saveToPhotosButtonPressed(button)
            },
            shareLinkAction: { [weak self] button in
                self?.shareLinkButtonPressed(button)
            }
        )
        
        refreshToolbarButtonsStatus(isDecryptedFolder())
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
        resetNodeActionSelectionAndImportFilesFromFolderLink()
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
    
    private func isFromFolderLink(nodeHandle: HandleEntity) -> MEGANode? {
        nodesArray.first { $0.handle == nodeHandle }
    }
}

// MARK: - hide action buttons
extension FolderLinkViewController {
    @objc func hideActionButtons() {
        moreBarButtonItem.isHidden = true
        navigationController?.isToolbarHidden = true
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
            case .expired:
                showUnavailableLinkViewWithError(.expired)
            }
        case .rootFolderLinkLoaded:
            handleRootFolderLinkLoaded()
        case .invalidDecryptionKey:
            handleInvalidDecryptionKey()
        case .decryptionKeyRequired:
            showDecryptionAlert()
        case .fileAttributeUpdate(let handleEntity):
            handleFileAttributeUpdate(handleEntity)
        case .endEditingMode:
            setEditMode(false)
            refreshToolbarButtonsStatus(isDecryptedFolder())
        case .showSaveToPhotosError(let error):
            SVProgressHUD.show(
                MEGAAssets.UIImage.saveToPhotos,
                status: error
            )
        case .setViewMode(let viewMode):
            if isListViewModeSelected() && viewMode == .thumbnail || !isListViewModeSelected() && viewMode == .list {
                switchViewMode()
            }
        }
    }

    private func switchViewMode() {
        let isCurrentlyEditing = isListViewModeSelected() ? (self.flTableView?.tableView.isEditing ?? false) : (self.flCollectionView?.collectionView.allowsMultipleSelection ?? false)
        changeViewModePreference()
        setEditMode(isCurrentlyEditing)
    }
}

extension FolderLinkViewController {
    @objc func resetLayoutConstraintForLiquidGlass() {
        guard #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() else {
            return
        }
        
        edgesForExtendedLayout = [.bottom]
        extendedLayoutIncludesOpaqueBars = true
        
        if let containerViewBottomLayoutConstraint, containerViewBottomLayoutConstraint.isActive {
            containerViewBottomLayoutConstraint.isActive = false
            containerView?.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        }
    }
    
    @objc func clearBackBarButtonForLiquidGlass() {
        guard #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() else {
            return
        }
        clearBackBarButton()
    }
}
