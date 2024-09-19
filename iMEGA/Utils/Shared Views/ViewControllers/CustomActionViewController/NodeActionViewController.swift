import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGASwift

@objc protocol NodeActionViewControllerDelegate {
    // Method that handles selected node action for a single node. It may have an action specifically for single nodes. e.g Info, Versions
    // Don't remove this method.
    @objc optional func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any)
    // Method that handles selected node action for multiple nodes.
    @objc optional func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any)
}

@objc protocol NodeAccessoryActionDelegate {
    @objc optional func nodeAccessoryAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType)
}

class NodeActionViewController: ActionSheetViewController {
    private var nodes: [MEGANode]
    private var displayMode: DisplayMode
    private let viewModel = NodeActionViewModel(
        accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
        systemGeneratedNodeUseCase: SystemGeneratedNodeUseCase(
            systemGeneratedNodeRepository: SystemGeneratedNodeRepository.newRepo
        ),
        sensitiveNodeUseCase: SensitiveNodeUseCase(
            nodeRepository: NodeRepository.newRepo)
    )
    
    var sender: Any
    var delegate: any NodeActionViewControllerDelegate
    weak var accessoryActionDelegate: (any NodeAccessoryActionDelegate)?
    
    private var viewMode: ViewModePreferenceEntity?
    
    let nodeImageView = UIImageView()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(style: .subheadline, weight: .medium)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    lazy var downloadImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var separatorLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = TokenColors.Border.strong
        return view
    }()
    
    private var isUndecryptedFolder = false
    @MainActor private var loadActions: (() async -> Void)?
    
    // MARK: - NodeActionViewController initializers
    
    convenience init?(
        node: HandleEntity,
        delegate: some NodeActionViewControllerDelegate,
        displayMode: DisplayMode,
        isIncoming: Bool = false,
        isBackupNode: Bool,
        isFromSharedItem: Bool = false,
        sender: Any) {
            guard let node = MEGASdk.shared.node(forHandle: node) else { return nil }
            self.init(
                node: node,
                delegate: delegate,
                displayMode: displayMode,
                isIncoming: isIncoming,
                isBackupNode: isBackupNode,
                isFromSharedItem: isFromSharedItem,
                sender: sender
            )
        }
    
    init?(
        nodeHandle: HandleEntity,
        delegate: some NodeActionViewControllerDelegate,
        displayMode: DisplayMode,
        isBackupNode: Bool = false,
        sender: Any) {
        
        guard let node = MEGASdk.shared.node(forHandle: nodeHandle) else { return nil }
        self.nodes = [node]
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.actions = NodeActionBuilder()
            .setDisplayMode(displayMode)
            .setAccessLevel(MEGASdk.shared.accessLevel(for: node))
            .setIsBackupNode(isBackupNode)
            .build()
    }
    
    init(nodes: [MEGANode], delegate: some NodeActionViewControllerDelegate, displayMode: DisplayMode, isIncoming: Bool = false, containsABackupNode: Bool = false, isFromSharedItem: Bool = false, sender: Any) {
        self.nodes = nodes
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        loadActions = { [self] in
            var selectionType: NodeSelectionType = .filesAndFolders
            let fileNodes = nodes.filter { $0.isFile() }
            if fileNodes.isEmpty {
                selectionType = .folders
            } else if fileNodes.count == nodes.count {
                selectionType = .files
            }
            
            let mediaUseCase = MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo, videoMediaUseCase: VideoMediaUseCase(videoMediaRepository: VideoMediaRepository.newRepo))
            let areMediaFiles = nodes.allSatisfy { mediaUseCase.isPlayableMediaFile($0.toNodeEntity()) }
            
            let nodesCount = nodes.count
            let linkedNodeCount = nodes.publicLinkedNodes().count
            let containsDisputedFiles = nodes.filter { $0.isTakenDown() }.count > 0
            let actions = NodeActionBuilder()
                .setDisplayMode(displayMode)
                .setIsTakedown(containsDisputedFiles)
                .setNodeSelectionType(selectionType, selectedNodeCount: nodesCount)
                .setLinkedNodeCount(linkedNodeCount)
                .setIsAllLinkedNode(linkedNodeCount == nodesCount)
                .setIsFavourite(displayMode == .photosFavouriteAlbum)
                .setIsBackupNode(containsABackupNode)
                .setAreMediaFiles(areMediaFiles)
                .setIsHiddenNodesFeatureEnabled(DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes))
                .setIsHidden(await viewModel.isHidden(
                    nodes.toNodeEntities(), isFromSharedItem: isFromSharedItem, containsBackupNode: containsABackupNode))
                .setHasValidProOrUnexpiredBusinessAccount(viewModel.hasValidProOrUnexpiredBusinessAccount)
                .multiselectBuild()
            
            update(actions: actions, sender: sender)
        }
    }

    @objc init(node: MEGANode, delegate: any NodeActionViewControllerDelegate, displayMode: DisplayMode, isIncoming: Bool = false, isBackupNode: Bool, isFromSharedItem: Bool = false, sender: Any) {
        self.nodes = [node]
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.setupActions(node: node,
                          displayMode: displayMode,
                          isIncoming: isIncoming,
                          isBackupNode: isBackupNode,
                          isFromSharedItem: isFromSharedItem)
    }
    
    @objc init(node: MEGANode, delegate: any NodeActionViewControllerDelegate, displayMode: DisplayMode, isIncoming: Bool = false, isBackupNode: Bool, sharedFolder: MEGAShare, shouldShowVerifyContact: Bool, sender: Any) {
        self.nodes = [node]
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        self.isUndecryptedFolder = isIncoming && shouldShowVerifyContact
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.setupActions(node: node,
                          displayMode: displayMode,
                          isIncoming: isIncoming,
                          isBackupNode: isBackupNode,
                          sharedFolder: sharedFolder,
                          shouldShowVerifyContact: shouldShowVerifyContact)
    }
    
    @objc init(node: MEGANode, delegate: any NodeActionViewControllerDelegate, displayMode: DisplayMode, isInVersionsView: Bool, isBackupNode: Bool, isFromSharedItem: Bool = false, sender: Any) {
        self.nodes = [node]
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.setupActions(node: node,
                          displayMode: displayMode,
                          isInVersionsView: isInVersionsView,
                          isBackupNode: isBackupNode,
                          isFromSharedItem: isFromSharedItem)
    }
    
    @objc init(node: MEGANode, delegate: any NodeActionViewControllerDelegate, displayMode: DisplayMode, viewMode: ViewModePreferenceEntity,
               isBackupNode: Bool, containsMediaFiles: Bool, sender: Any) {
        self.nodes = [node]
        self.displayMode = displayMode
        self.delegate = delegate
        self.viewMode = viewMode
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.actions = NodeActionBuilder()
            .setDisplayMode(displayMode)
            .setViewMode(viewMode)
            .setIsBackupNode(isBackupNode)
            .setContainsMediaFiles(containsMediaFiles)
            .build()
    }
    
    @objc init(node: MEGANode, delegate: any NodeActionViewControllerDelegate, isLink: Bool = false, displayMode: DisplayMode, isInVersionsView: Bool = false, isBackupNode: Bool, isFromSharedItem: Bool = false, sender: Any) {
        self.nodes = [node]
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        loadActions = { [self] in
            let actions = NodeActionBuilder()
                .setDisplayMode(self.displayMode)
                .setIsPdf(node.name?.pathExtension == "pdf")
                .setIsLink(isLink)
                .setAccessLevel(MEGASdk.shared.accessLevel(for: node))
                .setIsRestorable(isBackupNode ? false : node.mnz_isRestorable())
                .setVersionCount(node.mnz_numberOfVersions() - 1)
                .setIsChildVersion(MEGASdk.shared.node(forHandle: node.parentHandle)?.isFile())
                .setIsInVersionsView(isInVersionsView)
                .setIsBackupNode(isBackupNode)
                .setIsExported(node.isExported())
                .setIsHiddenNodesFeatureEnabled(DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes))
                .setIsHidden(await viewModel.isHidden(
                    [node.toNodeEntity()], isFromSharedItem: isFromSharedItem, containsBackupNode: isBackupNode))
                .setHasValidProOrUnexpiredBusinessAccount(viewModel.hasValidProOrUnexpiredBusinessAccount)
                .build()
            
            update(actions: actions, sender: sender)
        }
    }
    
    @objc func addAction(_ action: BaseAction) {
        self.actions.append(action)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNodeHeaderView()
        tableView.register(NodeActionTableViewCell.self,
                           forCellReuseIdentifier: String(describing: NodeActionTableViewCell.self))
        updateAppearance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Node Action Items
        if let loadActions {
            Task {
                await loadActions()
                self.loadActions = nil
            }
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        
        headerView?.backgroundColor = TokenColors.Background.surface2
        if nodes.count == 1, let node = nodes.first, node.isTakenDown() {
            titleLabel.attributedText = node.attributedTakenDownName()
            titleLabel.textColor = TokenColors.Text.error
        } else {
            titleLabel.textColor = TokenColors.Text.primary
        }
        subtitleLabel.textColor = TokenColors.Text.secondary
        separatorLineView.backgroundColor = UIColor.mnz_separator()
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes),
              let action = actions[safe: indexPath.row] as? NodeAction,
              let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NodeActionTableViewCell.self),
                                                       for: indexPath) as? NodeActionTableViewCell else {
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
        cell.configureCell(action: action)
        cell.accessoryTappedHandler = { [weak self] in
            self?.accessoryTapped(type: action.type)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let action = actions[indexPath.row] as? NodeAction else {
            return
        }
        dismiss(animated: true, completion: { [weak self] in
            guard let self else { return }
            if nodes.count == 1, let node = nodes.first {
                delegate.nodeAction?(self, didSelect: action.type, for: node, from: sender)
            } else {
                delegate.nodeAction?(self, didSelect: action.type, forNodes: nodes, from: sender)
            }
        })
    }
    
    // MARK: - Private
    
    private func configureNodeHeaderView() {
        guard nodes.count == 1, let node = nodes.first else {
            return
        }
        
        headerView?.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80)
        
        headerView?.addSubview(nodeImageView)
        nodeImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nodeImageView.widthAnchor.constraint(equalToConstant: 40),
            nodeImageView.heightAnchor.constraint(equalToConstant: 40),
            nodeImageView.leadingAnchor.constraint(equalTo: headerView!.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            nodeImageView.centerYAnchor.constraint(equalTo: headerView!.centerYAnchor)
        ])
        nodeImageView.mnz_setThumbnail(by: node)
        Task { await configureSensitivity(for: node.toNodeEntity()) }
        
        headerView?.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: nodeImageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: headerView!.trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: headerView!.centerYAnchor, constant: -10)
        ])
        
        titleLabel.text = isUndecryptedFolder ? Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName : node.name
        
        headerView?.addSubview(subtitleLabel)
        subtitleLabel.leadingAnchor.constraint(equalTo: nodeImageView.trailingAnchor, constant: 8).isActive = true
        
        if node.isFile() && MEGAStore.shareInstance().offlineNode(with: node) != nil {
            headerView?.addSubview(downloadImageView)
            NSLayoutConstraint.activate([
                downloadImageView.widthAnchor.constraint(equalToConstant: 12),
                downloadImageView.heightAnchor.constraint(equalToConstant: 12),
                downloadImageView.centerYAnchor.constraint(equalTo: headerView!.centerYAnchor, constant: 10),
                downloadImageView.leadingAnchor.constraint(equalTo: subtitleLabel.trailingAnchor, constant: 4),
                downloadImageView.trailingAnchor.constraint(lessThanOrEqualTo: headerView!.safeAreaLayoutGuide.trailingAnchor, constant: -10)
            ])
            
            downloadImageView.image = UIImage.downloaded
        } else {
            subtitleLabel.trailingAnchor.constraint(equalTo: headerView!.trailingAnchor, constant: -8).isActive = true
        }
        
        subtitleLabel.centerYAnchor.constraint(equalTo: headerView!.centerYAnchor, constant: 10).isActive = true
                
        if node.isFile() {
            subtitleLabel.text = sizeAndModicationDate(node.toNodeEntity())
        } else {
            subtitleLabel.text = getFilesAndFolders(node.toNodeEntity())
        }
        
        headerView?.addSubview(separatorLineView)
        NSLayoutConstraint.activate([
            separatorLineView.leadingAnchor.constraint(equalTo: headerView!.leadingAnchor),
            separatorLineView.trailingAnchor.constraint(equalTo: headerView!.trailingAnchor),
            separatorLineView.bottomAnchor.constraint(equalTo: headerView!.bottomAnchor),
            separatorLineView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
        ])
    }
    
    private func sizeAndModicationDate(_ nodeModel: NodeEntity) -> String {
        let modificationTime = nodeModel.modificationTime as NSDate
        let modificationTimeString: String = modificationTime.mnz_formattedDateMediumTimeShortStyle()
        
        return sizeForFile(nodeModel) + " • " + modificationTimeString
    }
    
    private func sizeForFile(_ nodeModel: NodeEntity) -> String {
        return String.memoryStyleString(fromByteCount: Int64(nodeModel.size))
    }
    
    private func getFilesAndFolders(_ nodeModel: NodeEntity) -> String {
        let nodeUseCase = NodeUseCase(nodeDataRepository: NodeDataRepository.newRepo, nodeValidationRepository: NodeValidationRepository.newRepo, nodeRepository: NodeRepository.newRepo)
        let numberOfFilesAndFolders = nodeUseCase.getFilesAndFolders(nodeHandle: nodeModel.handle)
        let numberOfFiles = numberOfFilesAndFolders.0
        let numberOfFolders = numberOfFilesAndFolders.1
        let numberOfFilesAndFoldersString = NSString.mnz_string(byFiles: numberOfFiles, andFolders: numberOfFolders)
        return numberOfFilesAndFoldersString
    }
    
    private func setupActions(node: MEGANode, displayMode: DisplayMode, isIncoming: Bool = false, isInVersionsView: Bool = false, isBackupNode: Bool, sharedFolder: MEGAShare = MEGAShare(), shouldShowVerifyContact: Bool = false, isFromSharedItem: Bool = false) {
        loadActions = { [self] in
            let isImageOrVideoFile = node.name?.fileExtensionGroup.isVisualMedia == true
            let isMediaFile = node.isFile() && isImageOrVideoFile && node.mnz_isPlayable()
            let isEditableTextFile = node.isFile() && node.name?.fileExtensionGroup.isEditableText == true
            let isTakedown = node.isTakenDown()
            let isVerifyContact = displayMode == .sharedItem &&
            shouldShowVerifyContact &&
            !sharedFolder.isVerified
            let sharedFolderContact = MEGASdk.shared.contact(forEmail: sharedFolder.user)
            
            let actions = NodeActionBuilder()
                .setDisplayMode(displayMode)
                .setAccessLevel(MEGASdk.shared.accessLevel(for: node))
                .setIsMediaFile(isMediaFile)
                .setIsEditableTextFile(isEditableTextFile)
                .setIsFile(node.isFile())
                .setVersionCount(node.mnz_numberOfVersions() - 1)
                .setIsFavourite(node.isFavourite)
                .setLabel(node.label)
                .setIsBackupNode(isBackupNode)
                .setIsRestorable(isBackupNode ? false : node.mnz_isRestorable())
                .setIsPdf(node.name?.pathExtension == "pdf")
                .setisIncomingShareChildView(isIncoming)
                .setIsExported(node.isExported())
                .setIsOutshare(node.isOutShare())
                .setIsChildVersion(MEGASdk.shared.node(forHandle: node.parentHandle)?.isFile())
                .setIsInVersionsView(isInVersionsView)
                .setIsTakedown(isTakedown)
                .setIsVerifyContact(isVerifyContact,
                                    sharedFolderReceiverEmail: sharedFolder.user ?? "",
                                    sharedFolderContact: sharedFolderContact)
                .setIsHiddenNodesFeatureEnabled(DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes))
                .setIsHidden(await viewModel.isHidden(
                    nodes.toNodeEntities(), isFromSharedItem: isFromSharedItem, containsBackupNode: isBackupNode))
                .setHasValidProOrUnexpiredBusinessAccount(viewModel.hasValidProOrUnexpiredBusinessAccount)
                .build()
            
            update(actions: actions, sender: self.sender)
        }
    }
    
    private func configureSensitivity(for node: NodeEntity) async {
        guard await viewModel.isSensitive(node: node) else { return }
        if node.hasThumbnail {
            nodeImageView.addBlurToView(style: .systemUltraThinMaterial)
        } else {
            nodeImageView.alpha = 0.5
        }
        
        titleLabel.alpha = 0.5
        subtitleLabel.alpha = 0.5
    }
    
    private func accessoryTapped(type: MegaNodeActionType) {
        accessoryActionDelegate?.nodeAccessoryAction?(self, didSelect: type)
    }
}
