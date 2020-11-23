
final class NodeActionBuilder {
    
    private var displayMode: DisplayMode = .unknown
    private var accessLevel: MEGAShareType = .accessUnknown
    private var isMediaFile: Bool = false
    private var isFile: Bool = false
    private var isFavourite: Bool = false
    private var label: MEGANodeLabel = .unknown
    private var isRestorable: Bool = false
    private var isPdf: Bool = false
    private var isLink: Bool = false
    private var isPageView: Bool = true
    private var isIncomingShareChildView: Bool = false
    private var isExported: Bool = false
    private var isOutShare: Bool = false
    private var isChildVersion: Bool = false
    
    func setDisplayMode(_ displayMode: DisplayMode) -> NodeActionBuilder {
        self.displayMode = displayMode
        return self
    }
    
    func setAccessLevel(_ accessLevel: MEGAShareType) -> NodeActionBuilder {
        self.accessLevel = accessLevel
        return self
    }
    
    func setIsMediaFile(_ isMediaFile: Bool) -> NodeActionBuilder {
        self.isMediaFile = isMediaFile
        return self
    }
    
    func setIsFile(_ isFile: Bool) -> NodeActionBuilder {
        self.isFile = isFile
        return self
    }
    
    func setIsFavourite(_ isFavourite: Bool) -> NodeActionBuilder {
        self.isFavourite = isFavourite
        return self
    }
    
    func setLabel(_ label: MEGANodeLabel) -> NodeActionBuilder {
        self.label = label
        return self
    }
    
    func setIsRestorable(_ isRestorable: Bool) -> NodeActionBuilder {
        self.isRestorable = isRestorable
        return self
    }
    
    func setIsPdf(_ isPdf: Bool) -> NodeActionBuilder {
        self.isPdf = isPdf
        return self
    }
    
    func setIsLink(_ isLink: Bool) -> NodeActionBuilder {
        self.isLink = isLink
        return self
    }
    
    func setIsPageView(_ isPageView: Bool) -> NodeActionBuilder {
        self.isPageView = isPageView
        return self
    }
    
    func setisIncomingShareChildView(_ isIncomingShareChildView: Bool) -> NodeActionBuilder {
        self.isIncomingShareChildView = isIncomingShareChildView
        return self
    }
    
    func setIsExported(_ isExported: Bool) -> NodeActionBuilder {
        self.isExported = isExported
        return self
    }
    
    func setIsOutshare(_ isOutShare: Bool) -> NodeActionBuilder {
        self.isOutShare = isOutShare
        return self
    }
    
    func setIsChildVersion(_ isChildVersion: Bool?) -> NodeActionBuilder {
        self.isChildVersion = isChildVersion ?? false
        return self
    }
    
    func build() -> [NodeAction] {
        
        var nodeActions = [NodeAction]()
        
        if isRestorable {
            nodeActions.append(NodeAction.restoreAction())
        }
        
        if displayMode == .folderLink {
            nodeActions.append(NodeAction.importAction())
            nodeActions.append(NodeAction.downloadAction())
            nodeActions.append(NodeAction.sendToChatAction())
            nodeActions.append(NodeAction.selectAction())
            nodeActions.append(NodeAction.shareAction())
        } else if displayMode == .fileLink {
            nodeActions.append(NodeAction.importAction())
            nodeActions.append(NodeAction.downloadAction())
            nodeActions.append(NodeAction.sendToChatAction())
            if isMediaFile {
                nodeActions.append(NodeAction.saveToPhotosAction())
            }
            nodeActions.append(NodeAction.shareAction())
        } else if displayMode == .nodeInsideFolderLink {
            nodeActions.append(NodeAction.importAction())
            nodeActions.append(NodeAction.downloadAction())
            if isMediaFile {
                nodeActions.append(NodeAction.saveToPhotosAction())
            }
        } else if displayMode == .previewDocument {
            if isLink {
                nodeActions.append(NodeAction.importAction())
            }
            nodeActions.append(NodeAction.downloadAction())
            nodeActions.append(NodeAction.sendToChatAction())
            if accessLevel == .accessOwner || isLink {
                nodeActions.append(NodeAction.shareAction())
            }
            if isPdf {
                nodeActions.append(NodeAction.searchAction())
                if isPageView {
                    nodeActions.append(NodeAction.pdfThumbnailViewAction())
                } else {
                    nodeActions.append(NodeAction.pdfPageViewAction())
                }
            }
        } else if displayMode == .chatSharedFiles {
            nodeActions.append(NodeAction.forwardAction())
            if isMediaFile {
                nodeActions.append(NodeAction.saveToPhotosAction())
            }
            nodeActions.append(NodeAction.downloadAction())
            nodeActions.append(NodeAction.importAction())
        } else if displayMode == .transfers {
            nodeActions.append(NodeAction.viewInFolderAction())
            nodeActions.append(NodeAction.getLinkAction())
            nodeActions.append(NodeAction.clearAction())
        } else if displayMode == .publicLinkTransfers {
            nodeActions.append(NodeAction.clearAction())
        } else if displayMode == .transfersFailed {
            nodeActions.append(NodeAction.retryAction())
            nodeActions.append(NodeAction.clearAction())
        } else {
            switch accessLevel {
            case .accessUnknown:
                nodeActions.append(NodeAction.importAction())
                if isMediaFile {
                    nodeActions.append(NodeAction.saveToPhotosAction())
                }
                nodeActions.append(NodeAction.downloadAction())
                
            case .accessRead, .accessReadWrite:
                if displayMode != .nodeInfo && displayMode != .nodeVersions {
                    nodeActions.append(NodeAction.infoAction())
                }
                if isMediaFile {
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
                    nodeActions.append(NodeAction.infoAction())
                    nodeActions.append(NodeAction.favouriteAction(isFavourite: isFavourite))
                    nodeActions.append(NodeAction.labelAction(label: label))
                }
                if isMediaFile {
                    nodeActions.append(NodeAction.saveToPhotosAction())
                }
                nodeActions.append(NodeAction.downloadAction())
                if displayMode == .nodeVersions {
                    if isChildVersion {
                        nodeActions.append(NodeAction.revertVersionAction())
                    }
                    nodeActions.append(NodeAction.removeAction())
                } else {
                    nodeActions.append(NodeAction.renameAction())
                    nodeActions.append(NodeAction.copyAction())
                    if isIncomingShareChildView {
                        nodeActions.append(NodeAction.leaveSharingAction())
                    } else {
                        nodeActions.append(NodeAction.moveAction())
                        nodeActions.append(NodeAction.moveToRubbishBinAction())
                    }
                }
                
            case .accessOwner:
                if displayMode == .cloudDrive || displayMode == .rubbishBin || displayMode == .nodeInfo || displayMode == .recents {
                    if displayMode != .nodeInfo {
                        nodeActions.append(NodeAction.infoAction())
                        nodeActions.append(NodeAction.favouriteAction(isFavourite: isFavourite))
                        nodeActions.append(NodeAction.labelAction(label: label))
                    }
                    if displayMode != .rubbishBin {
                        if isMediaFile {
                            nodeActions.append(NodeAction.saveToPhotosAction())
                        }
                        nodeActions.append(NodeAction.downloadAction())
                        if isExported {
                            nodeActions.append(NodeAction.manageLinkAction())
                            nodeActions.append(NodeAction.removeLinkAction())
                        } else {
                            nodeActions.append(NodeAction.getLinkAction())
                        }
                        if !isFile {
                            if isOutShare {
                                nodeActions.append(NodeAction.manageFolderAction())
                            } else {
                                nodeActions.append(NodeAction.shareFolderAction())
                            }
                        }
                        nodeActions.append(NodeAction.shareAction())
                    }
                    if isFile {
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
                    if isMediaFile {
                        nodeActions.append(NodeAction.saveToPhotosAction())
                    }
                    nodeActions.append(NodeAction.downloadAction())
                    if isChildVersion {
                        nodeActions.append(NodeAction.revertVersionAction())
                    }
                    nodeActions.append(NodeAction.removeAction())
                } else if displayMode == .chatAttachment {
                    nodeActions.append(NodeAction.infoAction())
                    if isMediaFile {
                        nodeActions.append(NodeAction.saveToPhotosAction())
                    }
                    nodeActions.append(NodeAction.downloadAction())
                    nodeActions.append(NodeAction.shareAction())
                } else {
                    nodeActions.append(NodeAction.infoAction())
                    nodeActions.append(NodeAction.favouriteAction(isFavourite: isFavourite))
                    nodeActions.append(NodeAction.labelAction(label: label))
                    if isMediaFile {
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
        return nodeActions
    }
}
