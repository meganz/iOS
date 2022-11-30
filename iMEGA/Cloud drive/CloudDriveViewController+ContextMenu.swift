import UIKit
import CoreServices
import MEGADomain

extension CloudDriveViewController: CloudDriveContextMenuDelegate {
    //MARK: - Context Menus configuration
    func contextMenuConfiguration() -> CMConfigEntity? {
        guard let parentNode = parentNode else { return nil }
        
        if parentNode.isFolder(),
           displayMode == .rubbishBin,
           parentNode.handle != MEGASdkManager.sharedMEGASdk().rubbishNode?.handle {
            return CMConfigEntity(menuType: .menu(type: .rubbishBin),
                                  isRubbishBinFolder: true,
                                  isRestorable: parentNode.mnz_isRestorable())
        } else {
            let parentNodeAccessLevel = MEGASdkManager.sharedMEGASdk().accessLevel(for: parentNode)
            let isIncomingSharedRootChild = parentNodeAccessLevel != .accessOwner && MEGASdkManager.sharedMEGASdk().parentNode(for: parentNode) == nil
           
            return CMConfigEntity(menuType: .menu(type: .display),
                                  viewMode: isListViewModeSelected() ? .list : .thumbnail,
                                  accessLevel: parentNodeAccessLevel.toShareAccessLevelEntity(),
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
        guard let menuConfig = contextMenuConfiguration() else { return }
        contextBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.moreNavigationBar.image,
                                                   menu: contextMenuManager?.contextMenu(with: menuConfig))
        if displayMode != .rubbishBin,
           displayMode != .backup,
           !isFromViewInFolder,
           let parentNode = parentNode,
           MEGASdkManager.sharedMEGASdk().accessLevel(for: parentNode) != .accessRead {
            guard let menuConfig = uploadAddMenuConfiguration() else { return }
            uploadAddBarButtonItem = UIBarButtonItem(image: Asset.Images.NavigationBar.add.image,
                                                         menu: contextMenuManager?.contextMenu(with: menuConfig))
            navigationItem.rightBarButtonItems = [contextBarButtonItem, uploadAddBarButtonItem]
        } else {
            navigationItem.rightBarButtonItems = [contextBarButtonItem]
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
    
    //MARK: - CloudDriveContextMenuDelegate functions
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
            if #available(iOS 14, *) {
                guard let parentNode = parentNode else { return }
                MediaDiscoveryRouter(viewController: self, parentNode: parentNode).start()
            }
        default: break
        }
        
        if #available(iOS 14, *), needToRefreshMenu {
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
            BackupNodesValidator(presenter: self, nodes: [parentNode.toNodeEntity()]).showWarningAlertIfNeeded() { [weak self] in
                self?.showShareFolderForNodes([parentNode])
            }
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
            parentNode.mnz_removeLink()
        }
        
        if #available(iOS 14, *), needToRefreshMenu {
            if displayMode == .backup {
                setBackupNavigationBarButtons()
            } else {
                setNavigationBarButtons()
            }
        }
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
            DevicePermissionsHelper.videoPermission { [weak self] granted in
                if granted {
                    DevicePermissionsHelper.photosPermission { granted in
                        if !granted {
                            UserDefaults.standard.set(false, forKey: "isSaveMediaCapturedToGalleryEnabled")
                        }
                        
                        self?.showImagePicker(for: .camera)
                    }
                } else {
                    DevicePermissionsHelper.alertVideoPermission(completionHandler: nil)
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
        if #available(iOS 14, *) {
            if displayMode == .backup {
                setBackupNavigationBarButtons()
            } else {
                setNavigationBarButtons()
            }
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
