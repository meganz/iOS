import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import UIKit

class BaseAction: NSObject {
    var title: String?
    var detail: String?
    var accessoryView: UIView?
    var image: UIImage?
    var style: UIAlertAction.Style = .default
    var enabled: Bool = true
    var syncIconAndTextColor: Bool = false
    var showNewFeatureBadge: Bool = false
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(title?.hash)
        hasher.combine(detail?.hash)
        hasher.combine(accessoryView?.hash)
        hasher.combine(image?.hash)
        hasher.combine(style.hashValue)
        hasher.combine(enabled)
        hasher.combine(syncIconAndTextColor)
        hasher.combine(showNewFeatureBadge)
        return hasher.finalize()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherObject = object as? BaseAction else { return false }

        guard title == otherObject.title else { return false }
        guard detail == otherObject.detail else { return false }
        guard accessoryView == otherObject.accessoryView else { return false }
        guard image == otherObject.image else { return false }
        guard style == otherObject.style else { return false }
        guard enabled == otherObject.enabled else { return false }
        guard syncIconAndTextColor == otherObject.syncIconAndTextColor else { return false }
        guard showNewFeatureBadge == otherObject.showNewFeatureBadge else { return false }

        return true
    }
}

class ActionSheetAction: BaseAction {
    
    var actionHandler: () -> Void
    
    @objc init(
        title: String?,
        detail: String?,
        image: UIImage?,
        enabled: Bool = true,
        syncIconAndTextColor: Bool = false,
        showNewFeatureBadge: Bool = false,
        style: UIAlertAction.Style,
        actionHandler: @escaping () -> Void
    ) {
        self.actionHandler = actionHandler
        super.init()
        self.title = title
        self.detail = detail
        self.image = image
        self.enabled = enabled
        self.syncIconAndTextColor = syncIconAndTextColor
        self.showNewFeatureBadge = showNewFeatureBadge
        self.style = style
    }
    
    @objc convenience init(
        title: String?,
        detail: String?,
        image: UIImage?,
        style: UIAlertAction.Style,
        actionHandler: @escaping () -> Void
    ) {
        self.init(
            title: title,
            detail: detail,
            image: image,
            enabled: true,
            style: style,
            actionHandler: actionHandler
        )
    }
    
    @objc init(
        title: String?,
        detail: String?,
        accessoryView: UIView?,
        image: UIImage?,
        style: UIAlertAction.Style,
        actionHandler: @escaping () -> Void
    ) {
        self.actionHandler = actionHandler
        super.init()
        self.title = title
        self.detail = detail
        self.accessoryView = accessoryView
        self.image = image
        self.style = style
    }
    
    // method used to add additional action
    // when given action is triggered such as:
    // 1. execute a comment action after each menu action, such as re-appear
    //    a view that was dismissed temporarily to present ActionSheetMenu
    func attachingAction(_ action: @escaping () -> Void) -> Self {
        let oldAction = self.actionHandler
        self.actionHandler = {
            oldAction()
            action()
        }
        return self
    }
}

class ActionSheetSwitchAction: ActionSheetAction {
    var switchView: UISwitch?
    
    @objc init(
        title: String?,
        detail: String?,
        switchView: UISwitch,
        image: UIImage?,
        style: UIAlertAction.Style,
        actionHandler: @escaping () -> Void
    ) {
        super.init(
            title: title,
            detail: detail,
            image: image,
            enabled: true,
            style: style,
            actionHandler: actionHandler
        )
        self.switchView = switchView
    }
    
    @MainActor
    @objc func change(state: Bool) {
        switchView?.isOn = state
    }
    
    @MainActor
    @objc func switchStatus() -> Bool {
        switchView?.isOn ?? false
    }
}

class NodeAction: BaseAction {
    let type: MegaNodeActionType
    let showProTag: Bool
    
    private init(title: String?,
                 detail: String? = nil,
                 accessoryView: UIView? = nil,
                 image: UIImage? = nil,
                 style: UIAlertAction.Style = .default,
                 type: MegaNodeActionType,
                 showProTag: Bool = false,
                 syncIconAndTextColor: Bool = false
    ) {
        self.type = type
        self.showProTag = showProTag
        super.init()
        self.title = title
        self.detail = detail
        self.accessoryView = accessoryView
        self.image = image
        self.style = style
        self.syncIconAndTextColor = syncIconAndTextColor
    }
}

final class ContextActionSheetAction: BaseAction {
    let identifier: String?
    let type: CMElementTypeEntity?
    var actionHandler: (ContextActionSheetAction) -> Void
    
    init(title: String?, detail: String?, image: UIImage?, identifier: String?, type: CMElementTypeEntity?, actionHandler: @escaping (ContextActionSheetAction) -> Void) {
        self.identifier = identifier
        self.type = type
        self.actionHandler = actionHandler
        super.init()
        self.title = title
        self.detail = detail
        self.image = image
    }
}

// MARK: - Node Actions Factory

extension NodeAction {
    class func exportFileAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.ExportFile.title(nodeCount), image: .export, type: .exportFile)
    }
    
    class func shareFolderAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.ShareFolder.title(nodeCount), image: .shareFolder, type: .shareFolder)
    }
    
    class func verifyContactAction(receiverDetail: String) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.VerifyContact.title(receiverDetail), image: MEGAAssets.UIImage.verifyContact, type: .verifyContact)
    }
    
    class func manageFolderAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.manageShare, image: .shareFolder, type: .manageShare)
    }
    
    class func downloadAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.downloadToOffline, image: .download, type: .download)
    }
    
    class func infoAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.info, image: .info, type: .info)
    }
    
    class func renameAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.rename, image: .rename, type: .rename)
    }
    
    class func copyAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.copy, image: .copy, type: .copy)
    }
    
    class func moveAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.move, image: .move, type: .move)
    }
    
    class func moveToRubbishBinAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.moveToRubbishBin, image: .rubbishBin, type: .moveToRubbishBin)
    }
    
    class func removeVideoFromVideoPlaylistAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.Videos.Tab.Playlist.Content.removeFromPlaylist, image: .removeVideoFromVideoPlaylist, type: .removeVideoFromVideoPlaylist, syncIconAndTextColor: true)
    }
    
    class func moveVideoInVideoPlaylistContentToRubbishBinAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.moveToRubbishBin, image: .rubbishBin, type: .moveVideoInVideoPlaylistContentToRubbishBin)
    }
    
    class func removeAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.deletePermanently, image: .rubbishBin, type: .remove)
    }

    class func removeFromAlbumAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.remove, image: .rubbishBin, type: .remove)
    }

    class func leaveSharingAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.leaveFolder, image: MEGAAssets.UIImage.leaveShare, type: .leaveSharing)
    }
    
    class func shareLinkAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.ShareLink.title(nodeCount), image: .shareLink, type: .shareLink)
    }
    
    class func retryAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.retry, image: MEGAAssets.UIImage.link, type: .retry)
    }
    
    class func manageLinkAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.ManageLink.title(nodeCount), image: .manageLink, type: .manageLink)
    }
    
    class func removeLinkAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.RemoveLink.title(nodeCount), image: .removelink, type: .removeLink)
    }
    
    class func removeSharingAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.removeSharing, image: MEGAAssets.UIImage.removeShare, type: .removeSharing)
    }
    
    class func viewInFolderAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.viewInFolder, image: .search, type: .viewInFolder)
    }

    class func showInLocationAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.Home.Recent.Bucket.Carousel.showInLocation, image: .showInLocation, type: .showInLocation)
    }
    
    class func clearAction() -> NodeAction {
        let action = NodeAction(title: Strings.Localizable.clear, image: .cancelTransfers, type: .clear)
        action.style = .destructive
        action.syncIconAndTextColor = true
        return action
    }
    
    class func importAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.importToCloudDrive, image: .import, type: .import)
    }
    
    class func viewVersionsAction(versionCount: Int) -> NodeAction {
        NodeAction(title: Strings.Localizable.versions, detail: String(versionCount), image: .versions, type: .viewVersions)
    }
    
    class func revertVersionAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.revert, image: .history, type: .revertVersion)
    }
    
    class func removeVersionAction() -> NodeAction {
        let nodeAction = NodeAction(title: Strings.Localizable.delete, image: .delete, type: .remove)
        nodeAction.style = .destructive
        return nodeAction
    }
    
    class func selectAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.select, image: .select, type: .select)
    }
    
    class func restoreAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.restore, image: .restore, type: .restore)
    }
    
    class func saveToPhotosAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.saveToPhotos, image: .saveToPhotos, type: .saveToPhotos)
    }
    
    class func sendToChatAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.sendToChat, image: .sendToChat, type: .sendToChat)
    }
    
    class func pdfPageViewAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.pageView, image: MEGAAssets.UIImage.pageView, type: .pdfPageView)
    }
    
    class func pdfThumbnailViewAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.thumbnailView, image: MEGAAssets.UIImage.thumbnailsThin, type: .pdfThumbnailView)
    }
    
    class func textEditorAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.edit, image: .editText, type: .editTextFile)
    }
    
    class func forwardAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.forward, image: MEGAAssets.UIImage.forwardToolbar, type: .forward)
    }
    
    class func searchAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.search, image: .search, type: .search)
    }
    
    class func favouriteAction(isFavourite: Bool) -> NodeAction {
        NodeAction(title: isFavourite ? Strings.Localizable.removeFavourite : Strings.Localizable.favourite, image: .favourite(isFavourite: isFavourite), type: .favourite)
    }
    
    @MainActor
    class func labelAction(label: MEGANodeLabel) -> NodeAction {
        let labelString = MEGANode.string(for: label)
        
        let detailText: String? = if let labelString {
            Strings.localized(labelString, comment: "")
        } else {
            nil
        }
        
        let image: UIImage? = if let labelString {
            MEGAAssets.UIImage.image(named: labelString)
        } else {
            nil
        }
        
        return NodeAction(title: Strings.Localizable.CloudDrive.Sort.label, detail: (label != .unknown ? detailText : nil), accessoryView: (label != .unknown ? UIImageView(image: image) : UIImageView(image: MEGAAssets.UIImage.standardDisclosureIndicator)), image: .label, type: .label)
    }
    
    class func disputeTakedownAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.disputeTakedown, image: .disputeTakedown, type: .disputeTakedown)
    }
    
    class func restoreBackupAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.restore, image: .restore, type: .restoreBackup)
    }
    
    @MainActor
    class func hideAction(showProTag: Bool = false) -> NodeAction {
        let helpButton = {
            let accessoryButton = UIButton(frame: .init(x: 0, y: 0, width: 24, height: 24))
            accessoryButton.setImage(MEGAAssets.UIImage.helpCircleThinMedium, for: .normal)
            return accessoryButton
        }
        return NodeAction(
            title: Strings.Localizable.General.MenuAction.Hide.title,
            accessoryView: showProTag ? nil : helpButton(),
            image: MEGAAssets.UIImage.eyeOff,
            type: .hide,
            showProTag: showProTag)
    }
    
    class func unHideAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.Unhide.title,
                   image: MEGAAssets.UIImage.eyeOn, type: .unhide)
    }
    
    class func addToAction() -> NodeAction {
        NodeAction(
            title: Strings.Localizable.Set.addTo,
            image: .addTo,
            type: .addTo)
    }
    
    class func addToAlbumAction() -> NodeAction {
        NodeAction(
            title: Strings.Localizable.Set.AddTo.album,
            image: .addTo,
            type: .addToAlbum)
    }
}

// MARK: Action images
private extension UIImage {
    static var info: UIImage { MEGAAssets.UIImage.infoMono }
    static var select: UIImage { MEGAAssets.UIImage.checkCircle }
    static var label: UIImage { MEGAAssets.UIImage.tagSimple }
    static func favourite(isFavourite: Bool) -> UIImage {
        isFavourite ? MEGAAssets.UIImage.heartBroken : MEGAAssets.UIImage.heartOutline
    }

    static var download: UIImage { MEGAAssets.UIImage.arrowDownCircle }
    static var shareLink: UIImage { MEGAAssets.UIImage.link01 }
    static var manageLink: UIImage { MEGAAssets.UIImage.linkGear }
    static var removelink: UIImage { MEGAAssets.UIImage.linkOff02 }
    static var shareFolder: UIImage { MEGAAssets.UIImage.folderUsersMono }

    static var editText: UIImage { MEGAAssets.UIImage.edit }
    static var saveToPhotos: UIImage { MEGAAssets.UIImage.photosApp }
    static var export: UIImage { MEGAAssets.UIImage.externalLink }
    static var sendToChat: UIImage { MEGAAssets.UIImage.messagePlus }
    static var rename: UIImage { MEGAAssets.UIImage.pen2 }
    static var addTo: UIImage { MEGAAssets.UIImage.rectangleStackPlus }
    static var copy: UIImage { MEGAAssets.UIImage.copy01 }
    static var rubbishBin: UIImage { MEGAAssets.UIImage.trash }
    static var move: UIImage { MEGAAssets.UIImage.moveMono }
    static var leaveShare: UIImage { MEGAAssets.UIImage.folderUsersMono }
    static var restore: UIImage { MEGAAssets.UIImage.rotateCcw }
    static var versions: UIImage { MEGAAssets.UIImage.clock }
    static var history: UIImage { MEGAAssets.UIImage.clockRotate }

    static var cancelTransfers: UIImage { MEGAAssets.UIImage.x }
    static var delete: UIImage { MEGAAssets.UIImage.x }
    static var search: UIImage { MEGAAssets.UIImage.searchSmall }
    static var showInLocation: UIImage { MEGAAssets.UIImage.monoFileSearchMediumRegularOutline }

    static var disputeTakedown: UIImage { MEGAAssets.UIImage.alertTriangle }
    static var removeVideoFromVideoPlaylist: UIImage { MEGAAssets.UIImage.minusCircle }

    static var `import`: UIImage { MEGAAssets.UIImage.folderArrow }
}
