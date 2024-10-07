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
    var badgeModel: Badge?
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(title?.hash)
        hasher.combine(detail?.hash)
        hasher.combine(accessoryView?.hash)
        hasher.combine(image?.hash)
        hasher.combine(style.hashValue)
        hasher.combine(enabled)
        hasher.combine(syncIconAndTextColor)
        hasher.combine(badgeModel)
        return hasher.finalize()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let otherObject = object as? BaseAction else { return false }
        return title == otherObject.title
        && detail == otherObject.detail
        && accessoryView == otherObject.accessoryView
        && image == otherObject.image
        && style == otherObject.style
        && enabled == otherObject.enabled
        && syncIconAndTextColor == otherObject.syncIconAndTextColor
        && badgeModel == otherObject.badgeModel
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
        badgeModel: Badge? = nil,
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
        self.badgeModel = badgeModel
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
    
    @objc func change(state: Bool) {
        switchView?.isOn = state
    }
    
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
        NodeAction(title: Strings.Localizable.General.MenuAction.ExportFile.title(nodeCount), image: UIImage.export, type: .exportFile)
    }
    
    class func shareFolderAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.ShareFolder.title(nodeCount), image: UIImage.shareFolder, type: .shareFolder)
    }
    
    class func verifyContactAction(receiverDetail: String) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.VerifyContact.title(receiverDetail), image: UIImage.verifyContact, type: .verifyContact)
    }
    
    class func manageFolderAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.manageShare, image: UIImage.shareFolder, type: .manageShare)
    }
    
    class func downloadAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.downloadToOffline, image: UIImage.offline, type: .download)
    }
    
    class func infoAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.info, image: UIImage.info, type: .info)
    }
    
    class func renameAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.rename, image: UIImage.rename, type: .rename)
    }
    
    class func copyAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.copy, image: UIImage.copy, type: .copy)
    }
    
    class func moveAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.move, image: UIImage.move, type: .move)
    }
    
    class func moveToRubbishBinAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.moveToRubbishBin, image: UIImage.rubbishBin, type: .moveToRubbishBin)
    }
    
    class func removeVideoFromVideoPlaylistAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.Videos.Tab.Playlist.Content.removeFromPlaylist, image: UIImage.hudMinus, type: .removeVideoFromVideoPlaylist, syncIconAndTextColor: true)
    }
    
    class func moveVideoInVideoPlaylistContentToRubbishBinAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.moveToRubbishBin, image: UIImage.rubbishBin, type: .moveVideoInVideoPlaylistContentToRubbishBin)
    }
    
    class func removeAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.deletePermanently, image: UIImage.rubbishBin, type: .remove)
    }
    
    class func leaveSharingAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.leaveFolder, image: UIImage.leaveShare, type: .leaveSharing)
    }
    
    class func shareLinkAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.ShareLink.title(nodeCount), image: UIImage.link, type: .shareLink)
    }
    
    class func retryAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.retry, image: UIImage.link, type: .retry)
    }
    
    class func manageLinkAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.ManageLink.title(nodeCount), image: UIImage.link, type: .manageLink)
    }
    
    class func removeLinkAction(nodeCount: Int = 1) -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.RemoveLink.title(nodeCount), image: UIImage.removeLink, type: .removeLink)
    }
    
    class func removeSharingAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.removeSharing, image: UIImage.removeShare, type: .removeSharing)
    }
    
    class func viewInFolderAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.viewInFolder, image: UIImage.search, type: .viewInFolder)
    }
    
    class func clearAction() -> NodeAction {
        let action = NodeAction(title: Strings.Localizable.clear, image: UIImage.cancelTransfers, type: .clear)
        action.style = .destructive
        action.syncIconAndTextColor = true
        return action
    }
    
    class func importAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.importToCloudDrive, image: UIImage.import, type: .import)
    }
    
    class func viewVersionsAction(versionCount: Int) -> NodeAction {
        NodeAction(title: Strings.Localizable.versions, detail: String(versionCount), image: UIImage.versions, type: .viewVersions)
    }
    
    class func revertVersionAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.revert, image: UIImage.history, type: .revertVersion)
    }
    
    class func removeVersionAction() -> NodeAction {
        let nodeAction = NodeAction(title: Strings.Localizable.delete, image: UIImage.delete, type: .remove)
        nodeAction.style = .destructive
        return nodeAction
    }
    
    class func selectAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.select, image: UIImage(named: "select"), type: .select)
    }
    
    class func restoreAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.restore, image: UIImage.restore, type: .restore)
    }
    
    class func saveToPhotosAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.saveToPhotos, image: UIImage.saveToPhotos, type: .saveToPhotos)
    }
    
    class func sendToChatAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.sendToChat, image: UIImage.sendToChat, type: .sendToChat)
    }
    
    class func pdfPageViewAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.pageView, image: UIImage.pageView, type: .pdfPageView)
    }
    
    class func pdfThumbnailViewAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.thumbnailView, image: UIImage(named: "thumbnailsThin"), type: .pdfThumbnailView)
    }
    
    class func textEditorAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.edit, image: UIImage.edittext, type: .editTextFile)
    }
    
    class func forwardAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.forward, image: UIImage.forwardToolbar, type: .forward)
    }
    
    class func searchAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.search, image: UIImage.search, type: .search)
    }
    
    class func favouriteAction(isFavourite: Bool) -> NodeAction {
        NodeAction(title: isFavourite ? Strings.Localizable.removeFavourite : Strings.Localizable.favourite, image: isFavourite ? UIImage.removeFavourite : UIImage.favourite, type: .favourite)
    }
    
    class func labelAction(label: MEGANodeLabel) -> NodeAction {
        let labelString = MEGANode.string(for: label)
        let detailText = Strings.localized(labelString!, comment: "")
        let image = UIImage(named: labelString!)
        
        return NodeAction(title: Strings.Localizable.CloudDrive.Sort.label, detail: (label != .unknown ? detailText : nil), accessoryView: (label != .unknown ? UIImageView(image: image) : UIImageView(image: UIImage.standardDisclosureIndicator)), image: UIImage.label, type: .label)
    }
    
    class func listAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.listView, image: UIImage(named: "gridThin"), type: .list)
    }
    
    class func thumbnailAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.thumbnailView, image: UIImage(named: "thumbnailsThin"), type: .thumbnail)
    }
    
    class func sortAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.sortTitle, image: UIImage(named: "sort"), type: .sort)
    }
    
    class func disputeTakedownAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.disputeTakedown, image: UIImage.disputeTakedown, type: .disputeTakedown)
    }
    
    class func restoreBackupAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.restore, image: UIImage.restore, type: .restoreBackup)
    }
    
    class func mediaDiscoveryAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.CloudDrive.Menu.MediaDiscovery.title,
                   image: UIImage.mediaDiscovery, type: .mediaDiscovery)
    }
    
    class func hideAction(showProTag: Bool = false) -> NodeAction {
        let helpButton = {
            let accessoryButton = UIButton(frame: .init(x: 0, y: 0, width: 24, height: 24))
            accessoryButton.setImage(.helpCircleThinMedium, for: .normal)
            return accessoryButton
        }
        return NodeAction(
            title: Strings.Localizable.General.MenuAction.Hide.title,
            accessoryView: showProTag ? nil : helpButton(),
            image: UIImage.eyeOff,
            type: .hide,
            showProTag: showProTag)
    }
    
    class func unHideAction() -> NodeAction {
        NodeAction(title: Strings.Localizable.General.MenuAction.Unhide.title,
                   image: UIImage.eyeOn, type: .unhide)
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

// MARK: Badge

class Badge: NSObject {
    
    var title: String
    var foregroundColor: UIColor
    var backgroundColor: UIColor
    
    required init(title: String, foregroundColor: UIColor, backgroundColor: UIColor) {
        self.title = title
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        
        super.init()
    }
}

extension Badge {
    static var raiseHandFeature: Self {
        .init(
            title: Strings.Localizable.Chat.Call.ContextMenu.newFeature,
            foregroundColor: TokenColors.Text.inverse,
            backgroundColor: TokenColors.Text.info
        )
    }
}
