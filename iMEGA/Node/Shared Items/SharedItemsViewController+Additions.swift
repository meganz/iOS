import ChatRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

extension SharedItemsViewController: ContactsViewControllerDelegate {
    @objc func shareFolder() {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            guard let nodes = selectedNodesMutableArray as? [MEGANode] else { return }
            viewModel.openShareFolderDialog(forNodes: nodes)
        }
    }
}

// MARK: - Unverified outgoing and incoming nodes
extension SharedItemsViewController {
    @objc func createSharedItemsViewModel() -> SharedItemsViewModel {
        SharedItemsViewModel(
            shareUseCase: ShareUseCase(
                shareRepository: ShareRepository.newRepo,
                filesSearchRepository: FilesSearchRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            mediaUseCase: MediaUseCase(
                fileSearchRepo: FilesSearchRepository.newRepo,
                videoMediaUseCase: VideoMediaUseCase(
                    videoMediaRepository: VideoMediaRepository.newRepo)),
            saveMediaToPhotosUseCase: SaveMediaToPhotosUseCase(
                downloadFileRepository: DownloadFileRepository.newRepo,
                fileCacheRepository: FileCacheRepository.newRepo,
                nodeRepository: NodeRepository.newRepo,
                chatNodeRepository: ChatNodeRepository.newRepo,
                downloadChatRepository: DownloadChatRepository.newRepo),
            moveToRubbishBinViewModel: MoveToRubbishBinViewModel(presenter: self)
        )
    }
    
    @objc func createNodeInfoViewModel(withNode node: MEGANode,
                                       isNodeUndecryptedFolder: Bool) -> NodeInfoViewModel {
        return NodeInfoViewModel(
            withNode: node,
            shareUseCase: ShareUseCase(
                shareRepository: ShareRepository.newRepo,
                filesSearchRepository: FilesSearchRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            nodeUseCase: NodeUseCase(
                nodeDataRepository: NodeDataRepository.newRepo,
                nodeValidationRepository: NodeValidationRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            backupUseCase: BackupsUseCase(
                backupsRepository: BackupsRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            ),
            isNodeUndecryptedFolder: isNodeUndecryptedFolder,
            shouldDisplayContactVerificationInfo: isContactVerificationEnabled() && incomingButton?.isSelected == true,
            completion: { [weak self] in
                self?.reloadUI()
            }
        )
    }
    
    @objc func indexPathFromSender(_ sender: UIButton) -> IndexPath? {
        let nonZeroPoint = CGPoint(x: 2, y: 2)
        let buttonPosition = sender.convert(nonZeroPoint, to: tableView)
        return tableView?.indexPathForRow(at: buttonPosition)
    }
    
    @objc func unverifiedIncomingSharedCellAtIndexPath(_ indexPath: IndexPath, node: MEGANode) -> SharedItemsTableViewCell {
        guard let cell = self.tableView?.dequeueReusableCell(withIdentifier: "sharedItemsTableViewCell", for: indexPath) as? SharedItemsTableViewCell else {
            return SharedItemsTableViewCell(style: .default, reuseIdentifier: "sharedItemsTableViewCell")
        }
        
        cell.delegate = self
        cell.thumbnailImageView.image = UIImage.mnz_incomingFolder()
        cell.nameLabel.textColor = UIColor.mnz_red()
        cell.nameLabel.text = node.isNodeKeyDecrypted() ? node.name : Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName
        cell.nodeHandle = node.handle
        cell.permissionsButton.setImage(UIImage.warningPermission, for: .normal)
        cell.permissionsButton.isHidden = false
        
        if let user = userContactFromShareAtIndexPath(indexPath) {
            cell.infoLabel.text = user.mnz_displayName ?? user.email
        } else {
            cell.infoLabel.text = ""
        }
        
        setupLabelAndFavourite(for: node, cell: cell)
        configureAccessibility(for: cell)
        return cell
    }

    @objc func unverifiedOutgoingSharedCellAtIndexPath(_ indexPath: IndexPath, node: MEGANode) -> SharedItemsTableViewCell {
        guard let cell = self.tableView?.dequeueReusableCell(withIdentifier: "sharedItemsTableViewCell", for: indexPath) as? SharedItemsTableViewCell else {
            return SharedItemsTableViewCell(style: .default, reuseIdentifier: "sharedItemsTableViewCell")
        }
        
        cell.delegate = self
        cell.thumbnailImageView.image = UIImage.mnz_outgoingFolder()
        cell.nodeHandle = node.handle
        cell.nameLabel.text = node.name
        cell.nameLabel.textColor = UIColor.mnz_red()
        cell.permissionsButton.setImage(UIImage.warningPermission, for: .normal)
        cell.permissionsButton.isHidden = false
        
        cell.infoLabel.text = ""
        if let user = userContactFromShareAtIndexPath(indexPath) {
            let userName: String = user.mnz_displayName ?? user.email ?? ""
            cell.infoLabel.text = Strings.Localizable.SharedItems.Tab.Outgoing.sharedToContact(userName)
        } else if let share = shareAtIndexPath(indexPath), let userEmail = share.user {
            cell.infoLabel.text = Strings.Localizable.SharedItems.Tab.Outgoing.sharedToContact(userEmail)
        }
        
        setupLabelAndFavourite(for: node, cell: cell)
        configureAccessibility(for: cell)
        return cell
    }

    @objc func configureCellDescription(_ cell: SharedItemsTableViewCell, for node: MEGANode) {
        cell.setNodeDescription(viewModel.isSearchUsingNodeDescriptionEnabled ? node.description : nil)
    }

    @objc func nodeCellAtIndexPath(_ indexPath: IndexPath, node: MEGANode) -> NodeTableViewCell {
        guard let cell = self.tableView?.dequeueReusableCell(withIdentifier: "nodeCell", for: indexPath) as? NodeTableViewCell else {
            return NodeTableViewCell(style: .default, reuseIdentifier: "nodeCell")
        }
        
        cell.configureCell(for: node, shouldApplySensitiveBehaviour: false, api: MEGASdk.shared)
        
        cell.moreButtonAction = { [weak self] moreButton in
            guard let moreButton else { return }
            self?.showNodeActions(moreButton)
        }
        
        return cell
    }
    
    func userContactFromShareAtIndexPath(_ indexPath: IndexPath) -> MEGAUser? {
        guard let share = shareAtIndexPath(indexPath) else { return nil }
        return MEGASdk.shared.contact(forEmail: share.user)
    }

    @objc func addInShareSearchBarIfNeeded() {
        let inShareSize = incomingShareList?.size ?? 0
        let unverifiedInShareSize = incomingUnverifiedShareList?.size ?? 0
        
        guard inShareSize > 0 || unverifiedInShareSize > 0 else {
            tableView?.tableHeaderView = nil
            return
        }
        addSearchBar()
    }
    
    @objc func searchUnverifiedNodes(key: String) {
        searchUnverifiedNodesArray.removeAllObjects()
        searchUnverifiedSharesArray.removeAllObjects()
        
        var nodes: [MEGANode]?
        var shares: [MEGAShare]?
        if outgoingButton?.isSelected == true {
            nodes = outgoingUnverifiedNodesMutableArray as? [MEGANode]
            shares = outgoingUnverifiedSharesMutableArray as? [MEGAShare]
        }
        
        if incomingButton?.isSelected == true {
            nodes = incomingUnverifiedNodesMutableArray as? [MEGANode]
            shares = incomingUnverifiedSharesMutableArray as? [MEGAShare]
        }

        guard let nodes, let shares else { return }
        guard key.isNotEmpty else {
            searchUnverifiedSharesArray.addObjects(from: shares)
            searchUnverifiedNodesArray.addObjects(from: nodes)
            return
        }
        
        nodes.indices.filter {
            nodes[$0].name?.lowercased().contains(key.lowercased()) == true
        }.forEach { index in
            searchUnverifiedSharesArray.add(shares[index])
            searchUnverifiedNodesArray.add(nodes[index])
        }
    }
    
    @objc func showCloudDriveFrom(node: MEGANode) {
        guard let navigationController else { return }
        let factory = CloudDriveViewControllerFactory.make(nc: navigationController)
        let nodeEntity = node.toNodeEntity()
        let isBackupNode = BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        ).isBackupNode(nodeEntity)
        
        let vc = factory.buildBare(
            parentNode: nodeEntity,
            config: .init(
                displayMode: isBackupNode ? .backup : .cloudDrive,
                isFromUnverifiedContactSharedFolder: shouldDisplayContactVerificationBannerForCloudDrive(node),
                isFromSharedItem: true
            )
        )
        guard let vc else { return }
        navigationController.pushViewController(vc, animated: true)
    }
    
    @objc func shareAtIndexPath(_ indexPath: IndexPath) -> MEGAShare? {
        guard indexPath.section == 0, linksButton?.isSelected == false else { return nil }
        
        if searchController.isActive {
            return searchUnverifiedSharesArray[indexPath.row] as? MEGAShare
        }
        
        if outgoingButton?.isSelected == true {
            return outgoingUnverifiedSharesMutableArray?[indexPath.row] as? MEGAShare
        }
        
        if incomingButton?.isSelected == true {
            return incomingUnverifiedSharesMutableArray?[indexPath.row] as? MEGAShare
        }
        
        return nil
    }
    
    @objc func shouldShowContactVerificationOnTap(forIndexPath indexPath: IndexPath, node: MEGANode) -> Bool {
        if incomingButton?.isSelected == true &&
            node.isNodeKeyDecrypted() {
            return false
        }
        
        guard indexPath.section == 0, let share = shareAtIndexPath(indexPath) else { return false }
        return !share.isVerified
    }

    @objc func numberOfSections() -> Int {
        guard linksButton?.isSelected == true else {
            return 2
        }
        return 1
    }
    
    @objc func configNavigationBarButtonItems() {
        let isEditing = tableView?.isEditing ?? false
        guard MEGAReachabilityManager.isReachableHUDIfNot() else {
            setNavigationBarButtonItemsEnabled(isEditing)
            return
        }
        
        guard !searchController.isActive else {
            var isEnabled = searchNodesArray.count > 0
            
            if incomingButton?.isSelected == true ||
                outgoingButton?.isSelected == true {
                isEnabled = isEnabled || searchUnverifiedNodesArray.count > 0
            }
            setNavigationBarButtonItemsEnabled(isEnabled || isEditing)
            return
        }
        
        var isEnabled = false
        if incomingButton?.isSelected == true {
            let inShareSize = incomingShareList?.size ?? 0
            let unverifiedInShareSize = incomingUnverifiedShareList?.size ?? 0
            isEnabled = inShareSize > 0 || unverifiedInShareSize > 0
        } else if outgoingButton?.isSelected == true {
            let outShareSize = outgoingShareList?.size ?? 0
            isEnabled = outShareSize > 0
        } else if linksButton?.isSelected == true {
            isEnabled = publicLinksArray.isNotEmpty
        }
        
        setNavigationBarButtonItemsEnabled(isEnabled || isEditing)
    }
    
    @objc func setNavigationBarButtonItemsEnabled(_ isEnabled: Bool) {
        self.editBarButtonItem?.isEnabled = isEnabled
    }
    
    private func shares(from shareList: MEGAShareList) -> [MEGAShare] {
        (0..<shareList.size).compactMap { index in
            guard let share = shareList.share(at: index) else { return nil }
            guard share.user != nil else { return nil }
            return share
        }
    }
    
    private func nodes(from shares: [MEGAShare]) -> [MEGANode] {
        shares.compactMap { share in
            MEGASdk.shared.node(forHandle: share.nodeHandle)
        }
    }
    
    private func badgeValue(_ count: Int) -> String {
        count == 0 ? "" : String(count)
    }
    
    @objc func addToUnverifiedOutShares(share: MEGAShare, node: MEGANode) {
        outgoingUnverifiedSharesMutableArray?.add(share)
        outgoingUnverifiedNodesMutableArray?.add(node)
    }
    
    @objc func configUnverifiedOutShareBadge() {
        let shareCount = outgoingUnverifiedSharesMutableArray?.count ?? 0
        outgoingButton?.setBadgeCount(value: badgeValue(shareCount))
    }
    
    @objc func incomingUnverifiedNodes() {
        let shareList = MEGASdk.shared.getUnverifiedInShares(sortOrderType)
        incomingUnverifiedShareList = shareList
        incomingUnverifiedSharesMutableArray?.removeAllObjects()
        incomingUnverifiedNodesMutableArray?.removeAllObjects()
        
        let shares = shares(from: shareList)
        incomingUnverifiedSharesMutableArray?.addObjects(from: shares)
        
        let nodes = nodes(from: shares)
        incomingUnverifiedNodesMutableArray?.addObjects(from: nodes)
        
        incomingButton?.setBadgeCount(value: badgeValue(shares.count))
         
        addInShareSearchBarIfNeeded()
    }
    
    @objc func updateToolbarItemsIfNeeded() {
        guard let toolbarItems = toolbar?.items, let saveToPhotosBarButtonItem, let nodes = selectedNodesMutableArray as? [MEGANode], nodes.isNotEmpty else { return }
        let areSelectedNodesMediaNodes = viewModel.areMediaNodes(nodes)
        let shouldUpdateToolbarItems = !areSelectedNodesMediaNodes && toolbarItems.contains(saveToPhotosBarButtonItem) ||
        areSelectedNodesMediaNodes && !toolbarItems.contains(saveToPhotosBarButtonItem)
        
        if shouldUpdateToolbarItems {
            configToolbarItemsForSharedItems()
        }
    }
    
    @objc func isSharedItemsRootNode(_ node: MEGANode) -> Bool {
        if incomingButton?.isSelected ?? false {
            return incomingNodesMutableArray.contains {($0 as? MEGANode)?.handle == node.handle}
        } else if outgoingButton?.isSelected ?? false {
            return outgoingNodesMutableArray.contains {($0 as? MEGANode)?.handle == node.handle}
        } else if linksButton?.isSelected ?? false {
            return publicLinksArray.contains {($0 as? MEGANode)?.handle == node.handle}
        }
        
        return false
    }
    
    @objc func showRemoveLinkWarning(_ nodes: [MEGANode]) {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            let router = ActionWarningViewRouter(presenter: self, nodes: nodes.toNodeEntities(), actionType: .removeLink, onActionStart: {
                SVProgressHUD.show()
            }, onActionFinish: { [weak self] result in
                self?.endEditingMode()
                switch result {
                case .success(let message):
                    SVProgressHUD.showSuccess(withStatus: message)
                case .failure:
                    SVProgressHUD.dismiss()
                }
            })
            router.start()
        }
    }
    
    @objc func saveSelectedNodesToPhotos() {
        guard let nodes = selectedNodesMutableArray as? [MEGANode], nodes.isNotEmpty else { return }
        Task { @MainActor in
            await self.viewModel.saveNodesToPhotos(nodes)
            self.endEditingMode()
        }
    }
    
    @objc func presentGetLink(for nodes: [MEGANode]) {
        guard MEGAReachabilityManager.isReachableHUDIfNot() else { return }
        GetLinkRouter(presenter: self,
                      nodes: nodes).start()
    }

    @objc func configureContactNotVerifiedImageVisibility(
        for cell: SharedItemsTableViewCell,
        with user: MEGAUser?,
        tab: SharedItemsTab
    ) {
        cell.contactVerifiedImageView.isHidden = !showContentVerified(for: cell, with: user, tab: tab)
    }
    
    @objc enum SharedItemsTab: Int {
        case incomingShares
        case outgoingShares
        case sharedLinks
    }
    
    private func showContentVerified(
        for cell: SharedItemsTableViewCell,
        with user: MEGAUser?,
        tab: SharedItemsTab
    ) -> Bool {
        guard
            tab == .incomingShares,
            isContactVerificationEnabled(),
            let user
        else {
            return false
        }
        
        return isContactVerified(user)
    }

    @objc func isContactVerified(_ user: MEGAUser) -> Bool {
        MEGASdk.shared.areCredentialsVerified(of: user)
    }

    @objc func isContactVerificationEnabled() -> Bool {
        MEGASdk.shared.isContactVerificationWarningEnabled
    }

    @objc func user(for node: MEGANode) -> MEGAUser? {
        guard let incomingShareList = incomingShareList else { return nil }

        for i in 0...incomingShareList.size {
            guard let share = incomingShareList.share(at: i), share.nodeHandle == node.handle else {
                continue
            }

            return MEGASdk.shared.contact(forEmail: share.user)
        }

        return nil
    }

    func shouldDisplayContactVerificationBannerForCloudDrive(_ node: MEGANode) -> Bool {
        var isUserVerified = false
        if let user = user(for: node) {
            isUserVerified = isContactVerified(user)
        }
        return isContactVerificationEnabled() && !isUserVerified && incomingButton?.isSelected == true
    }
    
    @objc func selectedCountTitle() -> String {
        guard let selectedCount = (selectedNodesMutableArray as? [MEGANode])?.count,
              selectedCount > 0 else {
            return Strings.Localizable.selectTitle
        }
        return Strings.Localizable.General.Format.itemsSelected(selectedCount)
    }
    
    @objc func configureButtons() {
        let buttonConfigurations: [(button: UIButton?, title: String)] = [
            (self.incomingButton, Strings.Localizable.incoming),
            (self.outgoingButton, Strings.Localizable.outgoing),
            (self.linksButton, Strings.Localizable.links)
        ]
        
        for (button, title) in buttonConfigurations {
            guard let button else { continue }
            
            var container = AttributeContainer()
            container.underlineStyle = .single
            
            button.configurationUpdateHandler = { configuredButton in
                let isSelected = configuredButton.state == .selected
                container.font = UIFont.preferredFont(style: .caption2, weight: isSelected ? .semibold : .regular)
                configuredButton.configuration?.attributedTitle = AttributedString(title, attributes: container)
            }
        }
    }
    
    @objc func updateAppearance() {
        self.tableView?.separatorColor = TokenColors.Border.strong
        self.view.backgroundColor = TokenColors.Background.page
        
        updateTabSelection()
    }
    
    @objc func backgroundColorWhenTrailingSwipe() -> UIColor {
        TokenColors.Support.error
    }
    
    @objc func tintColorForImage() -> UIColor {
        TokenColors.Icon.onColor
    }
    
    @objc func reloadAndScrollToTop() {
        Task {
            tableView?.reloadData()
            tableView?.layoutIfNeeded()
            tableView?.setContentOffset(.zero, animated: false)
        }
    }
}

// MARK: - SharedItemsTableViewCellDelegate
extension SharedItemsViewController: SharedItemsTableViewCellDelegate {
        
    func didTapInfoButton(sender: UIButton) {
        showNodeContextMenu(sender)
    }
}

// MARK: - Update toolbar items selected state
extension SharedItemsViewController {
    @objc func updateToolbarButtonsEnabled(_ enabled: Bool, selectedNodesArray: [MEGANode]) {
        ToolbarButtonsDisabler.disableConditionally(
            toolbarButtons: [
                downloadBarButtonItem,
                carbonCopyBarButtonItem,
                leaveShareBarButtonItem,
                shareLinkBarButtonItem,
                shareFolderBarButtonItem,
                removeShareBarButtonItem,
                removeLinkBarButtonItem,
                saveToPhotosBarButtonItem
            ],
            enabled: enabled,
            selectedNodesArray: selectedNodesArray.map { $0.toNodeEntity() }
        )
    }
}

extension SharedItemsViewController {
    @objc
    func setBackBarButton() {
        setMenuCapableBackButtonWith(menuTitle: Strings.Localizable.sharedItems)
    }
}

// MARK: - Ads
extension SharedItemsViewController: AdsSlotDisplayable {
    @objc func configureAds() {
        configureAdsVisibility()
    }
}
