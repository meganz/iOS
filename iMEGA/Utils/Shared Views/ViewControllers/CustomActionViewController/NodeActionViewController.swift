import MEGAData
import MEGADomain
import MEGASwift
import UIKit

@objc protocol NodeActionViewControllerDelegate {
    // Method that handles selected node action for a single node. It may have an action specifically for single nodes. e.g Info, Versions
    // Don't remove this method.
    @objc optional func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any)
    // Method that handles selected node action for multiple nodes.
    @objc optional func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any)
}

class NodeActionViewController: ActionSheetViewController {
    private var nodes: [MEGANode]
    private var displayMode: DisplayMode
    private let viewModel = NodeActionViewModel(nodeUseCase: NodeUseCase(nodeDataRepository: NodeDataRepository.newRepo, nodeValidationRepository: NodeValidationRepository.newRepo))
    
    var sender: Any
    var delegate: NodeActionViewControllerDelegate
    
    private var viewMode: ViewModePreference?
    
    let nodeImageView = UIImageView.newAutoLayout()
    let titleLabel = UILabel.newAutoLayout()
    let subtitleLabel = UILabel.newAutoLayout()
    let downloadImageView = UIImageView.newAutoLayout()
    let separatorLineView = UIView.newAutoLayout()
    private var isUndecryptedFolder = false
    
    // MARK: - NodeActionViewController initializers
    
    convenience init?(
        node: HandleEntity,
        delegate: NodeActionViewControllerDelegate,
        displayMode: DisplayMode,
        isIncoming: Bool = false,
        isBackupNode: Bool,
        sender: Any) {
            guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: node) else { return nil }
            self.init(node: node, delegate: delegate, displayMode: displayMode, isIncoming: isIncoming, isBackupNode: isBackupNode, sender: sender)
        }
    
    init?(
        nodeHandle: HandleEntity,
        delegate: NodeActionViewControllerDelegate,
        displayMode: DisplayMode,
        isBackupNode: Bool = false,
        sender: Any) {
        
        guard let node = MEGASdkManager.sharedMEGASdk().node(forHandle: nodeHandle) else { return nil }
        self.nodes = [node]
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.actions = NodeActionBuilder()
            .setDisplayMode(displayMode)
            .setAccessLevel(MEGASdkManager.sharedMEGASdk().accessLevel(for: node))
            .setIsBackupNode(isBackupNode)
            .build()
    }
    
    init(nodes: [MEGANode], delegate: NodeActionViewControllerDelegate, displayMode: DisplayMode, isIncoming: Bool = false, containsABackupNode: Bool = false, sender: Any) {
        self.nodes = nodes
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
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
        actions = NodeActionBuilder()
            .setDisplayMode(displayMode)
            .setIsTakedown(containsDisputedFiles)
            .setNodeSelectionType(selectionType, selectedNodeCount: nodesCount)
            .setLinkedNodeCount(linkedNodeCount)
            .setIsAllLinkedNode(linkedNodeCount == nodesCount)
            .setIsFavourite(displayMode == .photosFavouriteAlbum)
            .setIsBackupNode(containsABackupNode)
            .setAreMediaFiles(areMediaFiles)
            .multiselectBuild()
    }

    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, displayMode: DisplayMode, isIncoming: Bool = false, isBackupNode: Bool, sender: Any) {
        self.nodes = [node]
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.setupActions(node: node,
                          displayMode: displayMode,
                          isIncoming: isIncoming,
                          isBackupNode: isBackupNode)
    }
    
    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, displayMode: DisplayMode, isIncoming: Bool = false, isBackupNode: Bool, sharedFolder: MEGAShare, shouldShowVerifyContact: Bool, sender: Any) {
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
    
    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, displayMode: DisplayMode, isInVersionsView: Bool, isBackupNode: Bool, sender: Any) {
        self.nodes = [node]
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.setupActions(node: node,
                          displayMode: displayMode,
                          isInVersionsView: isInVersionsView,
                          isBackupNode: isBackupNode)
    }
    
    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, displayMode: DisplayMode, viewMode: ViewModePreference,
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
    
    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, isLink: Bool = false, displayMode: DisplayMode, isInVersionsView: Bool = false, isBackupNode: Bool, sender: Any) {
        self.nodes = [node]
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.actions = NodeActionBuilder()
            .setDisplayMode(self.displayMode)
            .setIsPdf(node.name?.pathExtension == "pdf")
            .setIsLink(isLink)
            .setAccessLevel(MEGASdkManager.sharedMEGASdk().accessLevel(for: node))
            .setIsRestorable(isBackupNode ? false : node.mnz_isRestorable())
            .setVersionCount(node.mnz_numberOfVersions() - 1)
            .setIsChildVersion(MEGASdkManager.sharedMEGASdk().node(forHandle: node.parentHandle)?.isFile())
            .setIsInVersionsView(isInVersionsView)
            .setIsBackupNode(isBackupNode)
            .setIsExported(node.isExported())
            .build()
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
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        
        headerView?.backgroundColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection)
        if nodes.count == 1, let node = nodes.first, node.isTakenDown() {
            titleLabel.attributedText = node.attributedTakenDownName()
            titleLabel.textColor = UIColor.mnz_red(for: traitCollection)
        } else {
            titleLabel.textColor = UIColor.mnz_label()
        }
        subtitleLabel.textColor = UIColor.mnz_subtitles(for: traitCollection)
        separatorLineView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let action = actions[indexPath.row] as? NodeAction else {
            return
        }
        dismiss(animated: true, completion: {
            if self.nodes.count == 1, let node = self.nodes.first {
                self.delegate.nodeAction?(self, didSelect: action.type, for: node, from: self.sender)
            } else {
                self.delegate.nodeAction?(self, didSelect: action.type, forNodes: self.nodes, from: self.sender)
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
        nodeImageView.autoSetDimensions(to: CGSize(width: 40, height: 40))
        nodeImageView.autoPinEdge(toSuperviewSafeArea: .leading, withInset: 8)
        nodeImageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        nodeImageView.mnz_setThumbnail(by: node)
        
        headerView?.addSubview(titleLabel)
        titleLabel.autoPinEdge(.leading, to: .trailing, of: nodeImageView, withOffset: 8)
        titleLabel.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        titleLabel.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: -10)
        titleLabel.text = isUndecryptedFolder ? Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName : node.name
        titleLabel.font = .preferredFont(style: .subheadline, weight: .medium)
        titleLabel.adjustsFontForContentSizeCategory = true
        
        headerView?.addSubview(subtitleLabel)
        subtitleLabel.autoPinEdge(.leading, to: .trailing, of: nodeImageView, withOffset: 8)
        
        if node.isFile() && MEGAStore.shareInstance().offlineNode(with: node) != nil {
            headerView?.addSubview(downloadImageView)
            downloadImageView.autoSetDimensions(to: CGSize(width: 12, height: 12))
            downloadImageView.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: 10)
            downloadImageView.autoPinEdge(.leading, to: .trailing, of: subtitleLabel, withOffset: 4)
            downloadImageView.autoPinEdge(toSuperviewSafeArea: .trailing, withInset: 10, relation: .greaterThanOrEqual)
            downloadImageView.image = Asset.Images.Generic.downloaded.image
        } else {
            subtitleLabel.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        }
        
        subtitleLabel.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: 10)
        subtitleLabel.font = .preferredFont(forTextStyle: .caption1)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        
        let sharedMEGASdk = displayMode == .folderLink || displayMode == .nodeInsideFolderLink ? MEGASdkManager.sharedMEGASdkFolder() : MEGASdkManager.sharedMEGASdk()
        if node.isFile() {
            subtitleLabel.text = Helper.sizeAndModicationDate(for: node, api: sharedMEGASdk)
        } else {
            subtitleLabel.text = Helper.filesAndFolders(inFolderNode: node, api: sharedMEGASdk)
        }
        
        headerView?.addSubview(separatorLineView)
        separatorLineView.autoPinEdge(toSuperviewEdge: .leading)
        separatorLineView.autoPinEdge(toSuperviewEdge: .trailing)
        separatorLineView.autoPinEdge(toSuperviewEdge: .bottom)
        separatorLineView.autoSetDimension(.height, toSize: 1/UIScreen.main.scale)
        separatorLineView.backgroundColor = tableView.separatorColor
    }
    
    private func setupActions(node: MEGANode, displayMode: DisplayMode, isIncoming: Bool = false, isInVersionsView: Bool = false, isBackupNode: Bool, sharedFolder: MEGAShare = MEGAShare(), shouldShowVerifyContact: Bool = false) {
        let isImageOrVideoFile = node.name?.mnz_isVisualMediaPathExtension == true
        let isMediaFile = node.isFile() && isImageOrVideoFile && node.mnz_isPlayable()
        let isEditableTextFile = node.isFile() && node.name?.fileExtensionGroup.isEditableText == true
        let isTakedown = node.isTakenDown()
        let isVerifyContact = displayMode == .sharedItem &&
                            shouldShowVerifyContact &&
                            !sharedFolder.isVerified
        let sharedFolderContact = MEGASdk.shared.contact(forEmail: sharedFolder.user)
        
        self.actions = NodeActionBuilder()
            .setDisplayMode(displayMode)
            .setAccessLevel(MEGASdkManager.sharedMEGASdk().accessLevel(for: node))
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
            .setIsChildVersion(MEGASdkManager.sharedMEGASdk().node(forHandle: node.parentHandle)?.isFile())
            .setIsInVersionsView(isInVersionsView)
            .setIsTakedown(isTakedown)
            .setIsVerifyContact(isVerifyContact,
                                sharedFolderReceiverEmail: sharedFolder.user ?? "",
                                sharedFolderContact: sharedFolderContact)
            .build()
    }
}
