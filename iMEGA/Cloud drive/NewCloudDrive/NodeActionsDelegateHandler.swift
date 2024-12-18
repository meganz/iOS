import MEGADomain

final class NodeActionsDelegateHandler: NodeActionViewControllerDelegate {
    
    var download: ([NodeEntity]) -> Void
    var browserAction: (_ action: BrowserActionEntity, _ nodes: [NodeEntity]) -> Void
    var moveToRubbishBin: ([NodeEntity]) -> Void
    var exportFiles: (_ nodes: [NodeEntity], _ sender: Any) -> Void
    var shareFolders: ([NodeEntity]) -> Void
    var shareOrManageLink: ([NodeEntity]) -> Void
    var sendToChat: ([NodeEntity]) -> Void
    var removeLink: ([NodeEntity]) -> Void
    var removeFromRubbishBin: ([NodeEntity]) -> Void
    var saveToPhotos: ([NodeEntity]) -> Void
    var showNodeInfo: (NodeEntity) -> Void
    var toggleNodeFavourite: (NodeEntity) -> Void
    var assignLabel: (NodeEntity) -> Void
    var leaveSharing: (NodeEntity) -> Void
    var rename: (_ node: NodeEntity, _ nameChanged: @escaping () -> Void) -> Void
    var removeSharing: (NodeEntity) -> Void
    var viewVersions: (NodeEntity) -> Void
    var restore: ([NodeEntity]) -> Void
    var manageShare: (NodeEntity) -> Void
    var shareFolder: (NodeEntity) -> Void
    var editTextFile: (NodeEntity) -> Void
    var disputeTakedown: (NodeEntity) -> Void
    var hide: ([NodeEntity]) -> Void
    var unhide: ([NodeEntity]) -> Void
    var addToAlbum: ([NodeEntity]) -> Void
    var addTo: ([NodeEntity]) -> Void
    
    // This closure could be used to implement finishing up and disabling edit mode
    // when each node action was finished, to be implemented in [SAO-190]
    var toggleEditMode: (_ editModeActive: Bool) -> Void
    
    init(
        download: @escaping ([NodeEntity]) -> Void,
        browserAction: @escaping (_ action: BrowserActionEntity, _ nodes: [NodeEntity]) -> Void,
        moveToRubbishBin: @escaping ([NodeEntity]) -> Void,
        exportFiles: @escaping (_ nodes: [NodeEntity], _ sender: Any) -> Void,
        shareFolders: @escaping ([NodeEntity]) -> Void,
        shareOrManageLink: @escaping ([NodeEntity]) -> Void,
        sendToChat: @escaping ([NodeEntity]) -> Void,
        removeLink: @escaping ([NodeEntity]) -> Void,
        removeFromRubbishBin: @escaping ([NodeEntity]) -> Void,
        saveToPhotos: @escaping ([NodeEntity]) -> Void,
        showNodeInfo: @escaping (NodeEntity) -> Void,
        toggleNodeFavourite: @escaping (NodeEntity) -> Void,
        assignLabel: @escaping (NodeEntity) -> Void,
        leaveSharing: @escaping (NodeEntity) -> Void,
        rename: @escaping (_ node: NodeEntity, _ nameChanged: @escaping () -> Void) -> Void,
        removeSharing: @escaping (NodeEntity) -> Void,
        viewVersions: @escaping (NodeEntity) -> Void,
        restore: @escaping ([NodeEntity]) -> Void,
        manageShare: @escaping (NodeEntity) -> Void,
        shareFolder: @escaping (NodeEntity) -> Void,
        editTextFile: @escaping (NodeEntity) -> Void,
        disputeTakedown: @escaping (NodeEntity) -> Void,
        hide: @escaping ([NodeEntity]) -> Void,
        unhide: @escaping ([NodeEntity]) -> Void,
        addToAlbum: @escaping ([NodeEntity]) -> Void,
        addTo: @escaping ([NodeEntity]) -> Void,
        toggleEditMode: @escaping (_ editModeActive: Bool) -> Void
    ) {
        self.download = download
        self.browserAction = browserAction
        self.moveToRubbishBin = moveToRubbishBin
        self.exportFiles = exportFiles
        self.shareFolders = shareFolders
        self.shareOrManageLink = shareOrManageLink
        self.sendToChat = sendToChat
        self.removeLink = removeLink
        self.removeFromRubbishBin = removeFromRubbishBin
        self.saveToPhotos = saveToPhotos
        self.showNodeInfo = showNodeInfo
        self.toggleNodeFavourite = toggleNodeFavourite
        self.assignLabel = assignLabel
        self.leaveSharing = leaveSharing
        self.rename = rename
        self.removeSharing = removeSharing
        self.viewVersions = viewVersions
        self.restore = restore
        self.manageShare = manageShare
        self.shareFolder = shareFolder
        self.editTextFile = editTextFile
        self.disputeTakedown = disputeTakedown
        self.toggleEditMode = toggleEditMode
        self.hide = hide
        self.unhide = unhide
        self.addToAlbum = addToAlbum
        self.addTo = addTo
    }
    
    func nodeAction(
        _ nodeAction: NodeActionViewController,
        didSelect action: MegaNodeActionType,
        forNodes nodes: [MEGANode],
        from sender: Any
    ) {
        let nodeEntities = nodes.map {
            $0.toNodeEntity()
        }
        switch action {
        case .download:
            download(nodeEntities)
        case .copy:
            browserAction(.copy, nodeEntities)
        case .move:
            browserAction(.move, nodeEntities)
        case .moveToRubbishBin:
            moveToRubbishBin(nodeEntities)
        case .exportFile:
            exportFiles(nodeEntities, sender)
        case .shareFolder:
            shareFolders(nodeEntities)
        case .shareLink, .manageLink:
            shareOrManageLink(nodeEntities)
        case .sendToChat:
            sendToChat(nodeEntities)
        case .removeLink:
            removeLink(nodeEntities)
        case .saveToPhotos:
            saveToPhotos(nodeEntities)
        case .hide:
            hide(nodeEntities)
        case .unhide:
            unhide(nodeEntities)
        case .addToAlbum:
            addToAlbum(nodeEntities)
        case .addTo:
            addTo(nodeEntities)
        default:
            break
        }
        
        toggleEditMode(false)
    }
    
    func nodeAction(
        _ nodeAction: NodeActionViewController,
        didSelect action: MegaNodeActionType,
        for node: MEGANode,
        from sender: Any
    ) {
        
        let nodeEntity = node.toNodeEntity()
        
        switch action {
        case .download:
            download([nodeEntity])
        case .exportFile:
            exportFiles([nodeEntity], sender)
        case .copy:
            browserAction(.copy, [nodeEntity])
        case .move, .restoreBackup:
            browserAction(.move, [nodeEntity])
        case .info:
            showNodeInfo(nodeEntity)
        case .favourite:
            toggleNodeFavourite(nodeEntity)
        case .label:
            assignLabel(nodeEntity)
        case .leaveSharing:
            leaveSharing(nodeEntity)
        case .rename:
            rename(nodeEntity, {})
        case .removeLink:
            removeLink([nodeEntity])
        case .moveToRubbishBin:
            moveToRubbishBin([nodeEntity])
        case .remove:
            removeFromRubbishBin([nodeEntity])
        case .removeSharing:
            removeSharing(nodeEntity)
        case .viewVersions:
            viewVersions(nodeEntity)
        case .restore:
            restore([nodeEntity])
        case .saveToPhotos:
            saveToPhotos([nodeEntity])
        case .manageShare:
            manageShare(nodeEntity)
        case .shareFolder:
            shareFolder(nodeEntity)
        case .manageLink, .shareLink:
            shareOrManageLink([nodeEntity])
        case .sendToChat:
            sendToChat([nodeEntity])
        case .editTextFile:
            editTextFile(nodeEntity)
        case .disputeTakedown:
            disputeTakedown(nodeEntity)
        case .hide:
            hide([nodeEntity])
        case .unhide:
            unhide([nodeEntity])
        case .addToAlbum:
            addToAlbum([nodeEntity])
        case .addTo:
            addTo([nodeEntity])
        default:
            break
        }
        
        toggleEditMode(false)
    }
}
