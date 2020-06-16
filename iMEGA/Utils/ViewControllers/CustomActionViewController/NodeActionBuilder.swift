
final class NodeActionBuilder {
    
    private var displayMode: DisplayMode = .unknown
    private var accessLevel: MEGAShareType = .accessUnknown
    private var isMediaFile: Bool = false
    private var isFile: Bool = false
    private var isRestorable: Bool = false
    private var isPdf: Bool = false
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
    
    func setIsRestorable(_ isRestorable: Bool) -> NodeActionBuilder {
        self.isRestorable = isRestorable
        return self
    }
    
    func setIsPdf(_ isPdf: Bool) -> NodeActionBuilder {
        self.isPdf = isPdf
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
            nodeActions.append(NodeAction.sendToChatAction())
            nodeActions.append(NodeAction.selectAction())
            nodeActions.append(NodeAction.shareAction())
        } else if displayMode == .fileLink {
            nodeActions.append(NodeAction.importAction())
            nodeActions.append(NodeAction.sendToChatAction())
            if isMediaFile {
                nodeActions.append(NodeAction.saveToPhotosAction())
            }
            nodeActions.append(NodeAction.shareAction())
            if isPdf {
                nodeActions.append(NodeAction.thumbnailPdfAction())
            }
        } else if displayMode == .nodeInsideFolderLink {
            nodeActions.append(NodeAction.importAction())
            if isMediaFile {
                nodeActions.append(NodeAction.saveToPhotosAction())
            }
        } else if displayMode == .chatSharedFiles {
            nodeActions.append(NodeAction.forwardAction())
            if isMediaFile {
                nodeActions.append(NodeAction.saveToPhotosAction())
            }
            nodeActions.append(NodeAction.downloadAction())
            nodeActions.append(NodeAction.importAction())
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
                    nodeActions.append(NodeAction.fileInfoAction(isFile: isFile))
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
                    nodeActions.append(NodeAction.fileInfoAction(isFile: isFile))
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
                        nodeActions.append(NodeAction.moveToRubbishBinAction())
                    }
                }
                
            case .accessOwner:
                if displayMode == .cloudDrive || displayMode == .rubbishBin || displayMode == .nodeInfo || displayMode == .recents {
                    if displayMode != .nodeInfo {
                        nodeActions.append(NodeAction.fileInfoAction(isFile: isFile))
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
                    nodeActions.append(NodeAction.fileInfoAction(isFile: isFile))
                    if isMediaFile {
                        nodeActions.append(NodeAction.saveToPhotosAction())
                    }
                    nodeActions.append(NodeAction.downloadAction())
                    nodeActions.append(NodeAction.shareAction())
                } else {
                    nodeActions.append(NodeAction.fileInfoAction(isFile: isFile))
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
