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

    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, displayMode: DisplayMode, isIncoming: Bool = false, sender: Any) {
        self.node = node
        self.delegate = delegate
        self.displayMode = displayMode
        self.isIncomingShareChildView = isIncoming
        self.sender = sender
        super.init(nibName: nil, bundle: nil)
        
        if UIDevice.current.iPadDevice {
            modalPresentationStyle = .popover
            popoverPresentationController?.delegate = self
            if let barButtonSender = sender as? UIBarButtonItem {
                popoverPresentationController?.barButtonItem = barButtonSender
            } else if let buttonSender = sender as? UIButton {
                popoverPresentationController?.sourceView = buttonSender
                popoverPresentationController?.sourceRect = CGRect(origin: .zero, size: CGSize(width: buttonSender.frame.width/2, height: buttonSender.frame.height/2))
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getActions()
        configureView()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let action = actions[indexPath.row] as? NodeAction else {
            return
        }
        dismiss(animated: true, completion: {
            self.delegate.nodeAction(self, didSelect: action.type, for: self.node, from: self.sender)
        })
    }
    
    func configureView() {
        headerView?.frame = CGRect(x: 0, y: 0, width: 320, height: 80)
        let imageView = UIImageView.newAutoLayout()
        imageView.mnz_setThumbnail(by: node)
        headerView?.addSubview(imageView)
        imageView.autoSetDimensions(to: CGSize(width: 40, height: 40))
        imageView.autoPinEdge(toSuperviewEdge: .leading, withInset: 8)
        imageView.autoAlignAxis(toSuperviewAxis: .horizontal)

        let title = UILabel.newAutoLayout()
        title.text = node.name
        title.font = .systemFont(ofSize: 15)
        headerView?.addSubview(title)

        title.autoPinEdge(.leading, to: .trailing, of: imageView, withOffset: 8)
        title.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        title.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: -8)

        let subtitle = UILabel.newAutoLayout()
        subtitle.textColor = .systemGray
        subtitle.font = .systemFont(ofSize: 12)
        headerView?.addSubview(subtitle)

        subtitle.autoPinEdge(.leading, to: .trailing, of: imageView, withOffset: 8)
        subtitle.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        subtitle.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: 8)

        let separatorLine = UIView.newAutoLayout()
        separatorLine.backgroundColor = tableView.separatorColor
        headerView?.addSubview(separatorLine)

        separatorLine.autoPinEdge(toSuperviewEdge: .leading)
        separatorLine.autoPinEdge(toSuperviewEdge: .trailing)
        separatorLine.autoPinEdge(toSuperviewEdge: .bottom)
        separatorLine.autoSetDimension(.height, toSize: 1/UIScreen.main.scale)
        
        if node.isFile() {
            subtitle.text = Helper.sizeAndDate(for: node, api: MEGASdkManager.sharedMEGASdk())
        } else {
            subtitle.text = Helper.filesAndFolders(inFolderNode: node, api: MEGASdkManager.sharedMEGASdk())
        }
    }
    
    private func getActions() {
        let accessType = MEGASdkManager.sharedMEGASdk().accessLevel(for: node)
        
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
            if node.isFile() {
                nodeActions.append(NodeAction.openAction())
            } else {
                nodeActions.append(NodeAction.selectAction())
                nodeActions.append(NodeAction.shareAction())
            }
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
        } else if displayMode == .chatSharedFiles {
            nodeActions.append(NodeAction.forwardAction())
            if canBeSavedToPhotos {
                nodeActions.append(NodeAction.saveToPhotosAction())
            }
            nodeActions.append(NodeAction.downloadAction())
            nodeActions.append(NodeAction.importAction())
        } else {
            switch accessType {
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
