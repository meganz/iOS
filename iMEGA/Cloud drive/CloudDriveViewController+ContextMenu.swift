import CoreServices
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGASDKRepo
import UIKit

extension CloudDriveViewController: CloudDriveContextMenuDelegate {
    // MARK: - Context Menus configuration
    func contextMenuConfiguration(parentNode: MEGANode, parentAccessLevel: NodeAccessTypeEntity, isHidden: Bool?) -> CMConfigEntity {
        if parentNode.isFolder(),
           displayMode == .rubbishBin,
           parentNode.handle != MEGASdk.sharedSdk.rubbishNode?.handle {
            return CMConfigEntity(menuType: .menu(type: .rubbishBin),
                                  viewMode: currentViewModePreference,
                                  sortType: SortOrderType(megaSortOrderType: Helper.sortType(for: parentNode)).megaSortOrderType.toSortOrderEntity(),
                                  isRubbishBinFolder: true,
                                  isRestorable: parentNode.mnz_isRestorable())
        } else {
            let isIncomingSharedRootChild = parentAccessLevel != .owner && MEGASdk.sharedSdk.parentNode(for: parentNode) == nil
            return CMConfigEntity(menuType: .menu(type: .display),
                                  viewMode: currentViewModePreference,
                                  accessLevel: parentAccessLevel.toShareAccessLevel(),
                                  sortType: viewModel.sortOrder(for: currentViewModePreference).megaSortOrderType.toSortOrderEntity(),
                                  isAFolder: parentNode.type != .root,
                                  isRubbishBinFolder: displayMode == .rubbishBin,
                                  isViewInFolder: isFromViewInFolder,
                                  isIncomingShareChild: isIncomingSharedRootChild,
                                  isSelectHidden: viewModel.isSelectionHidden,
                                  isOutShare: parentNode.isOutShare(),
                                  isExported: parentNode.isExported(),
                                  showMediaDiscovery: shouldShowMediaDiscoveryContextMenuOption(),
                                  isHidden: isHidden)
        }
    }
    
    func uploadAddMenuConfiguration() -> CMConfigEntity? {
        CMConfigEntity(
            menuType: .menu(type: .uploadAdd),
            viewMode: currentViewModePreference)
    }
    
    @objc func configureContextMenuManagerIfNeeded() {
        guard contextMenuManager == nil else { return }
        contextMenuManager = ContextMenuManager(displayMenuDelegate: self,
                                                quickActionsMenuDelegate: self,
                                                uploadAddMenuDelegate: self,
                                                rubbishBinMenuDelegate: self,
                                                createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo))
    }
    
    @objc func setNavigationBarButtons() {
        Task { @MainActor in
            guard let parentNode = parentNode else { return }
            
            let parentAccessLevel = await NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ).nodeAccessLevelAsync(nodeHandle: parentNode.handle)
            
            let menuConfig = contextMenuConfiguration(
                parentNode: parentNode,
                parentAccessLevel: parentAccessLevel, 
                isHidden: await viewModel.isParentMarkedAsSensitive(forDisplayMode: displayMode, isFromSharedItem: isFromSharedItem)
            )
            configNavigationBarMenus(
                menuConfig: menuConfig,
                parentAccessLevel: parentAccessLevel
            )
        }
    }
    
    private func configNavigationBarMenus(
        menuConfig: CMConfigEntity,
        parentAccessLevel: NodeAccessTypeEntity
    ) {
        var contextBarButtonItemUpdated = false
        if let contextMenuManager,
           let updatedMenu = contextMenuManager.contextMenu(with: menuConfig),
           !UIMenu.match(lhs: contextBarButtonItem.menu, rhs: updatedMenu) {
            contextBarButtonItem = UIBarButtonItem(image: UIImage.moreNavigationBar,
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
                uploadAddBarButtonItem = UIBarButtonItem(image: UIImage.navigationbarAdd,
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
    }
    
    @objc func dismissController() {
        dismiss(animated: true)
    }
    
    // MARK: - CloudDriveContextMenuDelegate functions
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        switch action {
        case .select:
            toggle(editModeActive: true)
        case .thumbnailView:
            changeModeToThumbnail()
        case .listView:
            changeModeToListView()
        case .clearRubbishBin:
            
            UIApplication.mnz_visibleViewController()
                .present(makeCleanRubbishBinAlert(), animated: true, completion: nil)
            
        case .mediaDiscovery:
            changeModeToMediaDiscovery()
        default:
            break
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
            presentGetLink(for: [parentNode])
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
            let router = ActionWarningViewRouter(presenter: self, nodes: [parentNode.toNodeEntity()], actionType: .removeLink, onActionStart: {
                SVProgressHUD.show()
            }, onActionFinish: {
                switch $0 {
                case .success(let message):
                    SVProgressHUD.showSuccess(withStatus: message)
                case .failure:
                    SVProgressHUD.dismiss()
                }
            })
            router.start()
        case .hide:
            hide(nodes: [parentNode.toNodeEntity()])
        case .unhide:
            unhide(nodes: [parentNode.toNodeEntity()])
        default:
            break
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
            createTextFileAlert()
        case .chooseFromPhotos:
            showImagePickerFor(sourceType: .photoLibrary)
        case .capture:
            showMediaCapture()
        case .importFrom:
            showDocumentImporter()
        default:
            break
        }
    }
    
    func sortMenu(didSelect sortType: SortOrderType) {
        viewModel.dispatch(.updateSortType(sortType))
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.configureContextMenuManagerIfNeeded()
            
            guard let config = self.uploadAddMenuConfiguration(),
                  let actions = self.contextMenuManager?.actionSheetActions(with: config) else { return }
            
            let actionSheetVC = ActionSheetViewController(actions: actions, headerTitle: nil, dismissCompletion: nil, sender: nil)
            self.present(actionSheetVC, animated: true)
        }
        
    }
}

func makeCleanRubbishBinAlert() -> UIViewController {
    let alertController = UIAlertController(title: Strings.Localizable.emptyRubbishBinAlertTitle, message: nil, preferredStyle: .alert)
    
    alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
    alertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default) { _ in
        MEGASdk.sharedSdk.cleanRubbishBin()
    })
    
    return alertController
}
