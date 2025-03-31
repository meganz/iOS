import Accounts
import ChatRepo
import Foundation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGASDKRepo
import MEGASwift

extension FolderLinkViewController {
    @objc func containsMediaFiles() -> Bool {
        nodesArray.toNodeEntities().contains {
            $0.mediaType != nil
        }
    }

    @objc func importFilesFromFolderLink() {
        if SAMKeychain.password(forService: "MEGA", account: "sessionV3") != nil {
            guard let navigationController =
                    UIStoryboard(
                        name: "Cloud",
                        bundle: nil
                    ).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
                  let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
                return
            }

            browserVC.browserAction = .importFromFolderLink

            if selectedNodesArray?.count != 0, let selectedNodesArray = selectedNodesArray as? [MEGANode] {
                browserVC.selectedNodesArray = selectedNodesArray
            } else if let parentNode = parentNode {
                browserVC.selectedNodesArray = [parentNode]
            }

            UIApplication.mnz_presentingViewController().present(navigationController, animated: true)
        } else {
            if let nodes = selectedNodesArray as? [MEGANode], nodes.isNotEmpty {
                MEGALinkManager.nodesFromLinkMutableArray.addObjects(from: nodes)
            } else if let parentNode = parentNode {
                MEGALinkManager.nodesFromLinkMutableArray.add(parentNode)
            }

            MEGALinkManager.selectedOption = .importFolderOrNodes

            navigationController?.pushViewController(OnboardingViewController.instantiateOnboarding(with: .default), animated: true)
        }
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
    }

    func showShareLink(from sender: UIBarButtonItem) {
        let link = linkEncryptedString ?? publicLinkString
        guard let link = link else { return }
        let activityVC = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = sender

        present(activityVC, animated: true)
    }

    func saveToPhotos(nodes: [NodeEntity]) {
        let saveMediaUseCase = SaveMediaToPhotosUseCase(
            downloadFileRepository: DownloadFileRepository(
                sdk: MEGASdk.shared,
                sharedFolderSdk: MEGASdk.sharedFolderLinkSdk
            ),
            fileCacheRepository: FileCacheRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            chatNodeRepository: ChatNodeRepository.newRepo,
            downloadChatRepository: DownloadChatRepository.newRepo
        )

        let permissionHandler = DevicePermissionsHandler.makeHandler()

        permissionHandler.photosPermissionWithCompletionHandler { granted in
            if granted {
                TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
                Task { @MainActor in
                    do {
                        try await saveMediaUseCase.saveToPhotos(nodes: nodes)
                    } catch {
                        if let errorEntity = error as? SaveMediaToPhotosErrorEntity, errorEntity != .cancelled {
                            await SVProgressHUD.dismiss()
                            SVProgressHUD.show(
                                UIImage.saveToPhotos,
                                status: error.localizedDescription
                            )
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
            title: parentNode?.name ?? "",
            subtitle: subTitle,
            traitCollection: traitCollection
        )
        
        navigationItem.titleView?.sizeToFit()
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
}

// MARK: - Ads
extension FolderLinkViewController: AdsSlotViewControllerProtocol {
    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        SingleItemAsyncSequence(
            item: AdsSlotConfig(adsSlot: .sharedLink, displayAds: true)
        ).eraseToAnyAsyncSequence()
    }
}
