import CoreServices
import MEGAData
import MEGADomain
import MEGAPermissions
import UIKit

extension CloudDriveViewController: CloudDriveContextMenuDelegate {
    // MARK: - Context Menus configuration
    func contextMenuConfiguration(parentNode: MEGANode, parentAccessLevel: NodeAccessTypeEntity) -> CMConfigEntity {
        if parentNode.isFolder(),
           displayMode == .rubbishBin,
           parentNode.handle != MEGASdkManager.sharedMEGASdk().rubbishNode?.handle {
            return CMConfigEntity(menuType: .menu(type: .rubbishBin),
                                  viewMode: isListViewModeSelected() ? .list : .thumbnail,
                                  sortType: SortOrderType(megaSortOrderType: Helper.sortType(for: parentNode)).megaSortOrderType.toSortOrderEntity(),
                                  isRubbishBinFolder: true,
                                  isRestorable: parentNode.mnz_isRestorable())
        } else {
            let isIncomingSharedRootChild = parentAccessLevel != .owner && MEGASdkManager.sharedMEGASdk().parentNode(for: parentNode) == nil
            return CMConfigEntity(menuType: .menu(type: .display),
                                  viewMode: isListViewModeSelected() ? .list : .thumbnail,
                                  accessLevel: parentAccessLevel.toShareAccessLevel(),
                                  sortType: SortOrderType(megaSortOrderType: Helper.sortType(for: parentNode)).megaSortOrderType.toSortOrderEntity(),
                                  isAFolder: parentNode.type != .root,
                                  isRubbishBinFolder: displayMode == .rubbishBin,
                                  isViewInFolder: isFromViewInFolder,
                                  isIncomingShareChild: isIncomingSharedRootChild,
                                  isOutShare: parentNode.isOutShare(),
                                  isExported: parentNode.isExported(),
                                  showMediaDiscovery: shouldShowMediaDiscovery())
        }
    }
    
    func uploadAddMenuConfiguration() -> CMConfigEntity? {
        CMConfigEntity(menuType: .menu(type: .uploadAdd))
    }
    
    @objc func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(displayMenuDelegate: self,
                                                quickActionsMenuDelegate: self,
                                                uploadAddMenuDelegate: self,
                                                rubbishBinMenuDelegate: self,
                                                createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
    }
    
    @objc func setNavigationBarButtons() {
        Task { @MainActor in
            guard let parentNode = parentNode else { return }
            let nodeUseCase = NodeUseCase(nodeDataRepository: NodeDataRepository.newRepo, nodeValidationRepository: NodeValidationRepository.newRepo)
            let parentAccessLevel = await nodeUseCase.nodeAccessLevelAsync(nodeHandle: parentNode.handle)
            let menuConfig = contextMenuConfiguration(parentNode: parentNode, parentAccessLevel: parentAccessLevel)
            configNavigationBarMenus(menuConfig: menuConfig, parentAccessLevel: parentAccessLevel)
        }
    }
    
    private func configNavigationBarMenus(menuConfig: CMConfigEntity, parentAccessLevel: NodeAccessTypeEntity) {
        var contextBarButtonItemUpdated = false
        if let contextMenuManager,
           let updatedMenu = contextMenuManager.contextMenu(with: menuConfig),
           !UIMenu.match(lhs: contextBarButtonItem.menu, rhs: updatedMenu) {
            contextBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image,
                                                   menu: updatedMenu)
            contextBarButtonItemUpdated = true
        }
        
        if displayMode != .rubbishBin,
           displayMode != .backup,
           !isFromViewInFolder,
           parentAccessLevel != .read {
            guard let menuConfig = uploadAddMenuConfiguration() else { return }
            var uploadAddBarButtonItemUpdated = false
            
            if let contextMenuManager,
               let updatedUploadAddMenu = contextMenuManager.contextMenu(with: menuConfig),
               !UIMenu.match(lhs: uploadAddBarButtonItem.menu, rhs: updatedUploadAddMenu) {
                uploadAddBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.add.image,
                                                         menu: updatedUploadAddMenu)
                uploadAddBarButtonItemUpdated = true
            }
            
            if contextBarButtonItemUpdated || uploadAddBarButtonItemUpdated || isEditingModeBeingDisabled {
                navigationItem.rightBarButtonItems = [contextBarButtonItem, uploadAddBarButtonItem]
                isEditingModeBeingDisabled = false
            }
        } else {
            if contextBarButtonItemUpdated || isEditingModeBeingDisabled {
                navigationItem.rightBarButtonItems = [contextBarButtonItem]
                isEditingModeBeingDisabled = false
            }
        }
        
        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.Localizable.close,
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(dismissController))
        }
    }
    
    @objc func dismissController() {
        dismiss(animated: true)
    }
    
    // MARK: - CloudDriveContextMenuDelegate functions
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        switch action {
        case .select:
            guard let enableEditing = cdTableView?.tableView?.isEditing ?? cdCollectionView?.collectionView?.allowsMultipleSelection else { return }
            setEditMode(!enableEditing)
        case .thumbnailView, .listView:
            if isListViewModeSelected() && action == .thumbnailView || !isListViewModeSelected() && action == .listView {
                changeViewModePreference()
            }
            
        case .clearRubbishBin:
            let alertController = UIAlertController(title: Strings.Localizable.emptyRubbishBinAlertTitle, message: nil, preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
            alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default) { _ in
                MEGASdkManager.sharedMEGASdk().cleanRubbishBin()
            })
            
            UIApplication.mnz_visibleViewController().present(alertController, animated: true, completion: nil)
        case .mediaDiscovery:
            guard let parentNode = parentNode else { return }
            MediaDiscoveryRouter(viewController: self, parentNode: parentNode).start()
        default: break
        }
        
        if needToRefreshMenu {
            if displayMode == .backup {
                setBackupNavigationBarButtons()
            } else {
                setNavigationBarButtons()
            }
        }
    }
    
    func quickActionsMenu(didSelect action: QuickActionEntity, needToRefreshMenu: Bool) {
        guard let parentNode = parentNode else { return }
        
        switch action {
        case .info:
            showNodeInfo(parentNode)
        case .download:
            download([parentNode])
        case .shareLink, .manageLink:
            presentGetLinkVC(for: [parentNode])
        case .shareFolder:
            viewModel.openShareFolderDialog(forNodes: [parentNode])
        case .rename:
            parentNode.mnz_renameNode(in: self) { [weak self] request in
                self?.navigationItem.title = request.name
            }
        case .leaveSharing:
            parentNode.mnz_leaveSharing(in: self) { [weak self] actionCompleted in
                if actionCompleted {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        case .copy:
            parentNode.mnz_copy(in: self)
        case .manageFolder:
            manageShare(parentNode)
        case .removeSharing:
            parentNode.mnz_removeSharing { [weak self] actionCompleted in
                if actionCompleted {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        case .removeLink:
            ActionWarningViewRouter(presenter: self, nodes: [parentNode.toNodeEntity()], actionType: .removeLink, onActionStart: {
                SVProgressHUD.show()
            }, onActionFinish: {
                switch $0 {
                case .success(let message):
                    SVProgressHUD.showSuccess(withStatus: message)
                case .failure:
                    SVProgressHUD.dismiss()
                }
            }).start()
        }
        
        if needToRefreshMenu {
            if displayMode == .backup {
                setBackupNavigationBarButtons()
            } else {
                setNavigationBarButtons()
            }
        }
    }
    
    var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    var permissionRouter: PermissionAlertRouter {
        .makeRouter(deviceHandler: permissionHandler)
    }
    
    func uploadAddMenu(didSelect action: UploadAddActionEntity) {
        switch action {
        case .scanDocument:
            presentScanDocument()
        case .newFolder:
            createNewFolderAction()
        case .newTextFile:
            guard let parentNode = parentNode else { return }
            CreateTextFileAlertViewRouter(presenter: navigationController, parentHandle: parentNode.handle).start()
        case .chooseFromPhotos:
            showImagePicker(for: .photoLibrary)
        case .capture:
            permissionHandler.requestVideoPermission { [weak self] videoPermissionGranted in
                guard let self else { return }
                if videoPermissionGranted {
                    permissionHandler.photosPermissionWithCompletionHandler {[weak self] photosPermissionGranted in
                        guard let self else { return }
                        if !photosPermissionGranted {
                            UserDefaults.standard.set(false, forKey: "isSaveMediaCapturedToGalleryEnabled")
                        }
                        
                        showImagePicker(for: .camera)
                    }
                } else {
                    permissionRouter.alertVideoPermission()
                }
            }
        case .importFrom:
            let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data, UTType.package], asCopy: true)
            documentPicker.delegate = self
            documentPicker.allowsMultipleSelection = true
            documentPicker.popoverPresentationController?.barButtonItem = contextBarButtonItem
            present(documentPicker, animated: true)
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        Helper.save(sortType.megaSortOrderType, for: parentNode)
        nodesSortTypeHasChanged()
        if displayMode == .backup {
            setBackupNavigationBarButtons()
        } else {
            setNavigationBarButtons()
        }
    }
    
    func rubbishBinMenu(didSelect action: RubbishBinActionEntity) {
        guard let parentNode = parentNode else { return }
        
        switch action {
        case .restore:
            parentNode.mnz_restore()
            navigationController?.popViewController(animated: true)
        case .info:
            showNodeInfo(parentNode)
        case .versions:
            parentNode.mnz_showVersions(in: self)
        case .remove:
            parentNode.mnz_remove(in: self) { [weak self] shouldRemove in
                if shouldRemove {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    @objc func presentUploadOptions() {
        if contextMenuManager == nil { configureContextMenuManager() }
        
        guard let config = uploadAddMenuConfiguration(),
              let actions = contextMenuManager?.actionSheetActions(with: config) else { return }
        
        let actionSheetVC = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
        present(actionSheetVC, animated: true)
    }
}
