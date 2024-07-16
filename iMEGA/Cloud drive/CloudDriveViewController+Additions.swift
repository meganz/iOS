import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import SwiftUI

extension CloudDriveViewController {
    @PreferenceWrapper(key: .isSaveMediaCapturedToGalleryEnabled, defaultValue: false, useCase: PreferenceUseCase.default)
    static var isSaveMediaCapturedToGalleryEnabled: Bool
    
    var viewModeLocation: ViewModeLocation_ObjWrapper {
        // For scenarios such as showing CDVC from Recents, there's
        // no parent node, nodes are shown from recentActionBucket.
        // To handle this situation and similar ones we encode a generic view mode location.
        // In this mode there's no layout switching so it should not
        // cause problems. View mode will be read from user settings or default to list
        // Having this use a common interface will enable us to differentiate
        // in the future and gives more granular control in a central place
        if let node = parentNode {
            return .init(node: node)
        }
        // example usage: show CloudDrive node list from multiple recent nodes
        return .init(customLocation: CustomViewModeLocation.Generic)
    }
    
    @objc func determineViewMode() {
        guard
            let viewModeStore
        else { return }
        
        let viewMode = viewModeStore.viewMode(for: viewModeLocation)
        
        if viewMode == .list {
            initTable()
            shouldDetermineViewMode = false
        } else if viewMode == .thumbnail {
            initCollection()
            shouldDetermineViewMode = false
        }
    }
    
    private var sdk: MEGASdk {
        MEGASdk.shared
    }
    
    @objc func createCloudDriveViewModel() -> CloudDriveViewModel {
        let preferenceUseCase = PreferenceUseCase.default
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        let systemGeneratedNodeUseCase = SystemGeneratedNodeUseCase(
            systemGeneratedNodeRepository: SystemGeneratedNodeRepository.newRepo
        )
        let nodeUseCase = NodeUseCase(
            nodeDataRepository: NodeDataRepository.newRepo,
            nodeValidationRepository: NodeValidationRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
        let nodeSensitivityChecker = NodeSensitivityChecker(
            featureFlagProvider: DIContainer.featureFlagProvider,
            accountUseCase: accountUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            nodeUseCase: nodeUseCase
        )
        return CloudDriveViewModel(
            parentNode: parentNode,
            shareUseCase: ShareUseCase(repo: ShareRepository.newRepo, filesSearchRepository: FilesSearchRepository.newRepo),
            sortOrderPreferenceUseCase: SortOrderPreferenceUseCase(
                preferenceUseCase: preferenceUseCase,
                sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo),
            preferenceUseCase: preferenceUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            accountUseCase: accountUseCase,
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo),
            nodeUseCase: nodeUseCase,
            tracker: DIContainer.tracker,
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: self), 
            nodeSensitivityChecker: nodeSensitivityChecker
        )
    }
    
    private func updatedParentNodeIfBelongs(_ nodeList: MEGANodeList) -> MEGANode? {
        nodeList
            .toNodeArray()
            .compactMap {
                if $0.handle == parentNode?.handle { return $0 }
                return nil
            }.first
    }
    
    @IBAction func actionsTouchUpInside(_ sender: UIBarButtonItem) {
        guard let nodes = selectedNodesArray as? [MEGANode] else {
            return
        }
        
        let nodeActionsViewController = NodeActionViewController(nodes: nodes, delegate: self, displayMode: displayMode, isIncoming: isIncomingShareChildView, containsABackupNode: displayMode == .backup, isFromSharedItem: isFromSharedItem, sender: sender)
        present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    @objc func showBrowserNavigation(for nodes: [MEGANode], action: BrowserAction) {
        guard let navigationController = storyboard?.instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController, let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
            return
        }
        
        browserVC.browserViewControllerDelegate = self
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = action
        
        present(navigationController, animated: true)
    }
    
    @objc func toggle(editModeActive: Bool) {
        viewModel.dispatch(.updateEditModeActive(editModeActive))
    }
    
    @IBAction func editTapped(_ sender: UIBarButtonItem) {
        toggle(editModeActive: false)
    }
    
    @objc func showShareFolderForNodes(_ nodes: [MEGANode]) {
        guard let navigationController =
                UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? MEGANavigationController, let contactsVC = navigationController.viewControllers.first as? ContactsViewController else {
            return
        }
        
        contactsVC.contactsViewControllerDelegate = self
        contactsVC.nodesArray = nodes
        contactsVC.contactsMode = .shareFoldersWith
        
        present(navigationController, animated: true)
    }
    
    @objc func showSendToChat(_ nodes: [MEGANode]) {
        guard let navigationController =
                UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController, let sendToViewController = navigationController.viewControllers.first as? SendToViewController else {
            return
        }
        
        sendToViewController.nodes = nodes
        sendToViewController.sendMode = .cloud
        
        present(navigationController, animated: true)
    }
    
    @objc func prepareToMoveNodes(_ nodes: [MEGANode]) {
        showBrowserNavigation(for: nodes, action: .move)
    }
    
    func createTextFileAlert() {
        guard let parentNode = parentNode else { return }
        CreateTextFileAlertViewRouter(presenter: navigationController, parentHandle: parentNode.handle).start()
    }
    
    private func shareType(for nodes: [MEGANode]) -> MEGAShareType {
        var currentNodeShareType: MEGAShareType = .accessUnknown
        
        nodes.forEach { node in
            currentNodeShareType = sdk.accessLevel(for: node)
            
            if currentNodeShareType == .accessRead && currentNodeShareType.rawValue < shareType.rawValue {
                return
            }
            
            if (currentNodeShareType == .accessReadWrite && currentNodeShareType.rawValue < shareType.rawValue) ||
                (currentNodeShareType == .accessFull && currentNodeShareType.rawValue < shareType.rawValue) {
                shareType = currentNodeShareType
            }
        }
        
        return shareType
    }
    
    @objc func toolbarActions(nodeArray: [MEGANode]?) {
        guard let nodeArray = nodeArray, !nodeArray.isEmpty else {
            return
        }
        let isBackupNode = displayMode == .backup
        shareType = isBackupNode ? .accessRead : shareType(for: nodeArray)
        
        toolbarActions(for: shareType, isBackupNode: isBackupNode)
    }
    
    /// Update the local version of parent node, and return true if the parents
    /// - Parameter updatedNodeList: List of updated nodes
    /// - Returns: True, if the parent node has changed, else false
    @objc func updateParentNodeIfNeeded(_ updatedNodeList: MEGANodeList) -> Bool {
        guard let updatedParentNode = updatedParentNodeIfBelongs(updatedNodeList) else { return false}
        self.parentNode = updatedParentNode
        viewModel.dispatch(.updateParentNode(updatedParentNode))
        return true
    }
    
    @objc func sortNodes(_ nodes: [MEGANode], sortBy order: MEGASortOrderType) -> [MEGANode] {
        let sortOrder = SortOrderType(megaSortOrderType: order)
        let folderNodes = nodes.filter { $0.isFolder() }.sort(by: sortOrder)
        let fileNodes = nodes.filter { $0.isFile() }.sort(by: sortOrder)
        return folderNodes + fileNodes
    }
    
    @objc func newFolderNameAlertTitle(invalidChars containsInvalidChars: Bool) -> String {
        guard containsInvalidChars else {
            return Strings.Localizable.newFolder
        }
        return Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay)
    }
    
    @objc func showNodeActionsForNode(_ node: MEGANode, isIncoming: Bool, isBackupNode: Bool, sender: Any) {
        let nodeActions = NodeActionViewController(node: node, delegate: self, displayMode: displayMode, isIncoming: isIncoming, isBackupNode: isBackupNode, isFromSharedItem: isFromSharedItem, sender: sender)
        present(nodeActions, animated: true)
    }
    
    @objc func showCustomActionsForNode(_ node: MEGANode, sender: Any) {
        switch displayMode {
        case .backup:
            showCustomActionsForBackupNode(node, sender: sender)
        case .rubbishBin:
            let isSyncDebrisNode = RubbishBinUseCase(rubbishBinRepository: RubbishBinRepository.newRepo).isSyncDebrisNode(node.toNodeEntity())
            showNodeActionsForNode(node, isIncoming: isIncomingShareChildView, isBackupNode: isSyncDebrisNode, sender: sender)
        default:
            showNodeActionsForNode(node, isIncoming: isIncomingShareChildView, isBackupNode: false, sender: sender)
        }
    }
    
    @objc func updateNavigationBarTitle() {
        let navigationTitle = CloudDriveNavigationTitleBuilder.build(
            parentNode: parentNode?.toNodeEntity(),
            isEditModeActive: viewModel.editModeActive,
            displayMode: displayMode,
            selectedNodesArrayCount: selectedNodesArray?.count ?? 0,
            nodes: nodes?.toNodeListEntity(),
            backupsUseCase: BackupsUseCase(
                backupsRepository: BackupsRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            )
        )

        navigationItem.title = navigationTitle
        setMenuCapableBackButtonWith(menuTitle: navigationTitle)
    }

    @objc func updateToolbarButtonsEnabled(_ enabled: Bool, selectedNodesArray: [MEGANode]) {
        let enableIfNotDisputed = !selectedNodesArray.contains(where: { $0.isTakenDown() }) && enabled
        
        downloadBarButtonItem?.isEnabled = enableIfNotDisputed
        shareLinkBarButtonItem?.isEnabled = enableIfNotDisputed
        moveBarButtonItem?.isEnabled = enableIfNotDisputed
        carbonCopyBarButtonItem?.isEnabled = enableIfNotDisputed
        deleteBarButtonItem?.isEnabled = enabled
        restoreBarButtonItem?.isEnabled = enableIfNotDisputed
        actionsBarButtonItem?.isEnabled = enabled
        
        if self.displayMode == DisplayMode.rubbishBin && enabled {
            for node in selectedNodesArray where !node.mnz_isRestorable() {
                restoreBarButtonItem?.isEnabled = false
                break
            }
        }
    }
    
    func showImagePickerFor(sourceType: UIImagePickerController.SourceType) {
        if sourceType == .camera {
            guard let imagePickerController = MEGAImagePickerController(
                toUploadWithParentNode: parentNode,
                sourceType: sourceType
            ) else { return }
            present(imagePickerController, animated: true)
        } else {
            permissionHandler.photosPermissionWithCompletionHandler {[weak self] granted in
                guard let self else { return }
                if granted {
                    self.loadPhotoAlbumBrowser()
                } else {
                    self.permissionRouter.alertPhotosPermission()
                }
            }
        }
    }
    
    func showMediaCapture() {
        permissionHandler.requestVideoPermission { [weak self] videoPermissionGranted in
            guard let self else { return }
            if videoPermissionGranted {
                permissionHandler.photosPermissionWithCompletionHandler {[weak self] photosPermissionGranted in
                    guard let self else { return }
                    if !photosPermissionGranted {
                        Self.isSaveMediaCapturedToGalleryEnabled = false
                    }
                    showImagePickerFor(sourceType: .camera)
                }
            } else {
                permissionRouter.alertVideoPermission()
            }
        }
    }
    
    func showDocumentImporter() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data, UTType.package], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        documentPicker.popoverPresentationController?.barButtonItem = contextBarButtonItem
        present(documentPicker, animated: true)
    }
    
    @objc func findIndexPath(for node: MEGANode, source: [MEGANode]) -> IndexPath {
        let section = sectionIndex(for: node, source: source)
        let item = itemIndex(for: node, source: source)
        return IndexPath(item: item, section: section)
    }
    
    private func sectionIndex(for node: MEGANode, source: [MEGANode]) -> Int {
        return node.isFolder() ? 0 : 1
    }
    
    private func itemIndex(for node: MEGANode, source: [MEGANode]) -> Int {
        guard source.isNotEmpty else {
            return 0
        }
        
        let isOnlyFiles = isAllNodeIsFileType(in: source)
        let isOnlyFolders = isAllNodeIsFolderType(in: source)
        let hasFilesAndFolders = !isOnlyFiles && !isOnlyFolders
        
        if isOnlyFiles || isOnlyFolders {
            return source.firstIndex { $0.handle == node.handle } ?? 0
        }
        
        if hasFilesAndFolders {
            if node.isFolder() {
                return source.firstIndex { $0.handle == node.handle } ?? 0
            } else {
                return findItemIndexForFileNode(for: node, source: source)
            }
        }
        
        return 0
    }
    
    private func findItemIndexForFileNode(for node: MEGANode, source: [MEGANode]) -> Int {
        let potentialIndex = source.firstIndex { $0.handle == node.handle } ?? 0
        let folderNodeCount = source.filter { $0.isFolder() }.count
        let normalizedFileNodeIndex = potentialIndex - folderNodeCount
        return normalizedFileNodeIndex
    }
    
    private func isAllNodeIsFileType(in source: [MEGANode]) -> Bool {
        source.allSatisfy { $0.isFile() }
    }
    
    private func isAllNodeIsFolderType(in source: [MEGANode]) -> Bool {
        source.allSatisfy { $0.isFolder() }
    }
    
    @objc func mapNodeListToArray(_ nodeList: MEGANodeList) -> NSArray {
        guard nodeList.size > 0 else {
            return []
        }
        
        let tempNodes = NSMutableArray(capacity: nodeList.size)
        for i in 0..<nodeList.size {
            if let node = nodeList.node(at: i) {
                tempNodes.add(node)
            }
        }
        
        guard let immutableNodes = tempNodes.copy() as? NSArray else {
            return []
        }
        return immutableNodes
    }
    
    @objc func presentGetLink(for nodes: [MEGANode]) {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        GetLinkRouter(presenter: self,
                      nodes: nodes).start()
    }
    
    @objc func configureWarningBanner() {
        if !isFromUnverifiedContactSharedFolder && warningViewModel == nil {
            warningBannerView.isHidden = true
        } else {
            if isFromUnverifiedContactSharedFolder {
                warningViewModel = WarningViewModel(
                    warningType: .contactNotVerifiedSharedFolder(
                        parentNode?.name ?? ""
                    )
                )
            }
            
            setupWarningBanner()
        }
    }

    private func setupWarningBanner() {
        guard let warningViewModel else {
            warningBannerView.isHidden = true
            return
        }
        let hostingController = UIHostingController(rootView: WarningView(viewModel: warningViewModel))
        
        warningBannerView.isHidden = false

        guard let hostingView = hostingController.view else { return }

        warningBannerView.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: warningBannerView.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: warningBannerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: warningBannerView.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: warningBannerView.bottomAnchor)
        ])
        
        warningViewModel.onHeightChange = { [weak self] newHeight in
            self?.warningBannerViewHeight?.constant = newHeight
            self?.warningBannerView.layoutIfNeeded()
        }
    }
    
    @objc func showUpgradePlanView() {
        UpgradeAccountRouter().presentUpgradeTVC()
    }
    
    @objc func setUpInvokeCommands() {
        viewModel.invokeCommand = { [weak self] command in
            
            guard let self else { return }
            
            switch command {
            case .enterSelectionMode:
                setEditMode(true)
            case .exitSelectionMode:
                setEditMode(false)
            case .reloadNavigationBarItems:
                setNavigationBarButtons()
            case .updateSortedData:
                sortTypeHasChanged()
            }
        }
    }
    
    func sortTypeHasChanged() {
        
        nodesSortTypeHasChanged()
        
        switch currentViewModePreference {
        case .perFolder, .list, .thumbnail:
            break
        case .mediaDiscovery:
            // Need to update sort type, as feature manages its own dataset
            let sortOrder = viewModel.sortOrder(for: .mediaDiscovery)
            mdViewController?.update(sortOrder: sortOrder)
        }
        
        if displayMode == .backup {
            setBackupNavigationBarButtons()
        } else {
            setNavigationBarButtons()
        }
    }
    
    private static func searchResultsNodes(from searchNodesArray: NSMutableArray?) -> [MEGANode] {
        var nodes = [MEGANode]()
        guard let searchNodesArray else {
            return nodes
        }
        // this is done with for loop, as lightweight ObjC generics do not port to Swift when used on NSMutableArray
        for node in searchNodesArray {
            if let megaNode = node as? MEGANode {
                nodes.append(megaNode)
            }
        }
        return nodes
    }
    
    private func nodeIsVisualMedia(_ node: MEGANode) -> Bool {
        node.name?.fileExtensionGroup.isVisualMedia == true
    }
    
    // provide all currently displayed nodes
    // - used when showing image browser, to be able to scroll through visual media (this should pass in only search results when search active)
    // - used when showing audio player
    // no node filtering (based on type) should be done at this stage
    private func allNodesForOpening(node: MEGANode) -> [MEGANode] {
        if nodeIsVisualMedia(node) {
            return searchResultsAwareAllNodesForOpeningVisualMedia()
        }
        
        return self.nodes?.mnz_nodesArrayFromNodeList() ?? []
    }
    
    // when opening visual media (image browser), we are passing in
    // only nodes available in the list, respecting searching results
    func searchResultsAwareAllNodesForOpeningVisualMedia() -> [MEGANode] {
        if  let searchController,
            searchController.isActive,
            searchController.searchBar.text?.mnz_isEmpty() == false {
            return Self.searchResultsNodes(from: self.searchNodesArray)
        } else {
            return self.nodes?.mnz_nodesArrayFromNodeList() ?? []
        }
    }
 
    @objc public func didSelectNode(_ node: MEGANode) {
        guard let navigationController else { return }
        
        let router = HomeScreenFactory().makeRouter(
            navController: navigationController,
            tracker: DIContainer.tracker
        )
        router.didTapNode(
            nodeHandle: node.handle,
            allNodeHandles: allNodesForOpening(node: node).map { $0.handle },
            displayMode: displayMode.carriedOverDisplayMode, 
            isFromSharedItem: isFromSharedItem,
            warningViewModel: warningViewModel
        )
    }
    
    @objc func makeSearchWithFilterOperation(searchText: String,
                                             parentHandle: MEGAHandle,
                                             excludeSensitive: Bool,
                                             cancelToken: MEGACancelToken,
                                             completion: @escaping (_ results: MEGANodeList?, _ isCanceled: Bool) -> Void
    ) -> SearchWithFilterOperation {
        let filter = makeSearchFilter(searchText: searchText,
                                      parentHandle: parentHandle,
                                      excludeSensitive: excludeSensitive)
        return SearchWithFilterOperation(sdk: .shared,
                                         filter: filter,
                                         page: nil,
                                         recursive: true,
                                         sortOrder: Helper.sortType(for: parentHandle),
                                         cancelToken: cancelToken,
                                         completion: completion)
    }
    
    private func makeSearchFilter(searchText: String, parentHandle: MEGAHandle, excludeSensitive: Bool) -> MEGASearchFilter {
        MEGASearchFilter(
            term: searchText,
            parentNodeHandle: parentHandle,
            nodeType: .unknown,
            category: .unknown,
            sensitiveFilter: excludeSensitive ? MEGASearchFilterSensitiveOption.nonSensitiveOnly : .disabled,
            favouriteFilter: .disabled,
            creationTimeFrame: nil,
            modificationTimeFrame: nil
        )
    }
    
    @objc func updateSensitivitySettingOnNextSearch() {
        viewModel.dispatch(.resetSensitivitySetting)
    }
    
    @objc func nodesForDisplayMode() async -> MEGANodeList? {
        switch displayMode {
        case .cloudDrive, .rubbishBin, .backup:
            await viewModel.nodesForDisplayMode(displayMode, sortOrder: Helper.sortType(for: parentNode))
        case .recents:
            recentActionBucket?.nodesList
        default:
            nil
        }
    }
}

// MARK: - Ads
extension CloudDriveViewController {
    @objc func configureAdsVisibility() {
        guard let mainTabBar = UIApplication.mainTabBarRootViewController() as? MainTabBarController else { return }
        mainTabBar.configureAdsVisibility()
    }
}

// MARK: - Node Info
extension CloudDriveViewController {
    @objc func showNodeInfo(_ node: MEGANode) {
        let router = NodeInfoRouter(navigationController: navigationController, contacstUseCase: ContactsUseCase(repository: ContactsRepository.newRepo))
        router.showInformation(for: node)
    }
}
