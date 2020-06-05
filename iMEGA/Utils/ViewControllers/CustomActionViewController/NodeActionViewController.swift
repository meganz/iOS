import UIKit

@objc protocol NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) ->  ()
}

class NodeActionViewController: ActionSheetViewController {
    
    private var node: MEGANode
    private var delegate: NodeActionViewControllerDelegate
    private var displayMode: DisplayMode
    private var isIncomingShareChildView: Bool
    private var sender: Any
    
    private let titleLabel = UILabel.newAutoLayout()
    private let subtitleLabel = UILabel.newAutoLayout()
    private let separatorLineView = UIView.newAutoLayout()

    // MARK: - NodeActionViewController initializers

    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, displayMode: DisplayMode, isIncoming: Bool = false, sender: Any) {
        self.node = node
        self.delegate = delegate
        self.displayMode = displayMode
        self.isIncomingShareChildView = isIncoming
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        getActions()
        configureNodeHeaderView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
            }
        }
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        
        headerView?.backgroundColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection)
        titleLabel.textColor = UIColor.mnz_label()
        subtitleLabel.textColor = UIColor.mnz_subtitles(for: traitCollection)
        separatorLineView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
    }
    
    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let action = actions[indexPath.row] as? NodeAction else {
            return
        }
        dismiss(animated: true, completion: {
            self.delegate.nodeAction(self, didSelect: action.type, for: self.node, from: self.sender)
        })
    }
    
    // MARK: - Private

    private func configureNodeHeaderView() {
        
        headerView?.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80)

        let nodeImageView = UIImageView.newAutoLayout()
        headerView?.addSubview(nodeImageView)
        nodeImageView.autoSetDimensions(to: CGSize(width: 40, height: 40))
        nodeImageView.autoPinEdge(toSuperviewSafeArea: .leading, withInset: 8)
        nodeImageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        nodeImageView.mnz_setThumbnail(by: node)

        headerView?.addSubview(titleLabel)
        titleLabel.autoPinEdge(.leading, to: .trailing, of: nodeImageView, withOffset: 8)
        titleLabel.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        titleLabel.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: -10)
        titleLabel.text = node.name
        titleLabel.font = .systemFont(ofSize: 15)
        
        headerView?.addSubview(subtitleLabel)
        subtitleLabel.autoPinEdge(.leading, to: .trailing, of: nodeImageView, withOffset: 8)
        subtitleLabel.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        subtitleLabel.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: 10)
        subtitleLabel.font = .systemFont(ofSize: 12)
        guard let sharedMEGASdk = displayMode == .folderLink || displayMode == .nodeInsideFolderLink ? MEGASdkManager.sharedMEGASdkFolder() : MEGASdkManager.sharedMEGASdk() else {
            return
        }
        if node.isFile() {
            subtitleLabel.text = Helper.sizeAndDate(for: node, api: sharedMEGASdk)
        } else {
            subtitleLabel.text = Helper.filesAndFolders(inFolderNode: node, api: sharedMEGASdk)
        }
        
        headerView?.addSubview(separatorLineView)
        separatorLineView.autoPinEdge(toSuperviewEdge: .leading)
        separatorLineView.autoPinEdge(toSuperviewEdge: .trailing)
        separatorLineView.autoPinEdge(toSuperviewEdge: .bottom)
        separatorLineView.autoSetDimension(.height, toSize: 1/UIScreen.main.scale)
    }
    
    private func getActions() {
        let canBeSavedToPhotos = node.isFile() && (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension && node.mnz_isPlayable())
        var nodeActions = [NodeAction]()
        
        if self.node.mnz_isRestorable() {
            nodeActions.append(NodeAction.restoreAction())
        }
        
        if displayMode == .folderLink {
            nodeActions.append(NodeAction.importAction())
            nodeActions.append(NodeAction.sendToChatAction())
            if canBeSavedToPhotos {
                nodeActions.append(NodeAction.saveToPhotosAction())
            }
            nodeActions.append(NodeAction.selectAction())
            nodeActions.append(NodeAction.shareAction())
        } else if displayMode == .fileLink {
            nodeActions.append(NodeAction.importAction())
            nodeActions.append(NodeAction.sendToChatAction())
            if canBeSavedToPhotos {
                nodeActions.append(NodeAction.saveToPhotosAction())
            }
            nodeActions.append(NodeAction.shareAction())
            if NSString(string: node.name).pathExtension.lowercased() == "pdf" {
                nodeActions.append(NodeAction.thumbnailPdfAction())
            }
        } else if displayMode == .nodeInsideFolderLink {
            nodeActions.append(NodeAction.importAction())
            if canBeSavedToPhotos {
                nodeActions.append(NodeAction.saveToPhotosAction())
            }
            if node.isFile() {
                nodeActions.append(NodeAction.openAction())
            }
        } else if displayMode == .chatSharedFiles {
            nodeActions.append(NodeAction.forwardAction())
            if canBeSavedToPhotos {
                nodeActions.append(NodeAction.saveToPhotosAction())
            }
            nodeActions.append(NodeAction.downloadAction())
            nodeActions.append(NodeAction.importAction())
        } else {
            switch MEGASdkManager.sharedMEGASdk().accessLevel(for: node) {
            case .accessUnknown:
                nodeActions.append(NodeAction.importAction())
                if canBeSavedToPhotos {
                    nodeActions.append(NodeAction.saveToPhotosAction())
                }
                nodeActions.append(NodeAction.downloadAction())
                
            case .accessRead, .accessReadWrite:
                if displayMode != .nodeInfo && displayMode != .nodeVersions {
                    nodeActions.append(NodeAction.fileInfoAction(isFile: node.isFile()))
                }
                if canBeSavedToPhotos {
                    nodeActions.append(NodeAction.saveToPhotosAction())
                }
                nodeActions.append(NodeAction.downloadAction())
                if displayMode != .nodeVersions {
                    nodeActions.append(NodeAction.copyAction())
                    if isIncomingShareChildView {
                        nodeActions.append(NodeAction.leaveSharingAction())
                    }
                }
                
            case .accessFull:
                if displayMode != .nodeInfo && displayMode != .nodeVersions {
                    nodeActions.append(NodeAction.fileInfoAction(isFile: node.isFile()))
                }
                if canBeSavedToPhotos {
                    nodeActions.append(NodeAction.saveToPhotosAction())
                }
                nodeActions.append(NodeAction.downloadAction())
                if displayMode == .nodeVersions {
                    if let parentNode = MEGASdkManager.sharedMEGASdk().node(forHandle: node.parentHandle), parentNode.isFile() {
                        nodeActions.append(NodeAction.revertVersionAction())
                    }
                    nodeActions.append(NodeAction.removeAction())
                } else {
                    nodeActions.append(NodeAction.renameAction())
                    nodeActions.append(NodeAction.copyAction())
                    if isIncomingShareChildView {
                        nodeActions.append(NodeAction.leaveSharingAction())
                    } else {
                        nodeActions.append(NodeAction.moveToRubbishBinAction())
                    }
                }
                
            case .accessOwner:
                if displayMode == .cloudDrive || displayMode == .rubbishBin || displayMode == .nodeInfo || displayMode == .recents {
                    if displayMode != .nodeInfo {
                        nodeActions.append(NodeAction.fileInfoAction(isFile: node.isFile()))
                    }
                    if displayMode != .rubbishBin {
                        if canBeSavedToPhotos {
                            nodeActions.append(NodeAction.saveToPhotosAction())
                        }
                        nodeActions.append(NodeAction.downloadAction())
                        if node.isExported() {
                            nodeActions.append(NodeAction.manageLinkAction())
                            nodeActions.append(NodeAction.removeLinkAction())
                        } else {
                            nodeActions.append(NodeAction.getLinkAction())
                        }
                        if node.isFolder() {
                            if node.isOutShare() {
                                nodeActions.append(NodeAction.manageFolderAction())
                            } else {
                                nodeActions.append(NodeAction.shareFolderAction())
                            }
                        }
                        nodeActions.append(NodeAction.shareAction())
                    }
                    if node.isFile() {
                        nodeActions.append(NodeAction.sendToChatAction())
                    }
                    nodeActions.append(NodeAction.renameAction())
                    nodeActions.append(NodeAction.moveAction())
                    nodeActions.append(NodeAction.copyAction())
                    if isIncomingShareChildView {
                        nodeActions.append(NodeAction.leaveSharingAction())
                    }
                    if displayMode == .cloudDrive || displayMode == .nodeInfo || displayMode == .recents {
                        nodeActions.append(NodeAction.moveToRubbishBinAction())
                    } else {
                        nodeActions.append(NodeAction.removeAction())
                    }
                } else if displayMode == .nodeVersions {
                    if canBeSavedToPhotos {
                        nodeActions.append(NodeAction.saveToPhotosAction())
                    }
                    nodeActions.append(NodeAction.downloadAction())
                    if let parentNode = MEGASdkManager.sharedMEGASdk().node(forHandle: node.parentHandle), parentNode.isFile() {
                        nodeActions.append(NodeAction.revertVersionAction())
                    }
                    nodeActions.append(NodeAction.removeAction())
                } else if displayMode == .chatAttachment {
                    nodeActions.append(NodeAction.fileInfoAction(isFile: node.isFile()))
                    if canBeSavedToPhotos {
                        nodeActions.append(NodeAction.saveToPhotosAction())
                    }
                    nodeActions.append(NodeAction.downloadAction())
                    nodeActions.append(NodeAction.shareAction())
                } else {
                    nodeActions.append(NodeAction.fileInfoAction(isFile: node.isFile()))
                    if canBeSavedToPhotos {
                        nodeActions.append(NodeAction.saveToPhotosAction())
                    }
                    nodeActions.append(NodeAction.downloadAction())
                    nodeActions.append(NodeAction.manageFolderAction())
                    nodeActions.append(NodeAction.shareAction())
                    nodeActions.append(NodeAction.renameAction())
                    nodeActions.append(NodeAction.copyAction())
                    nodeActions.append(NodeAction.removeSharingAction())
                }
                
            default:
                break
            }
        }
        actions = nodeActions
    }
}
