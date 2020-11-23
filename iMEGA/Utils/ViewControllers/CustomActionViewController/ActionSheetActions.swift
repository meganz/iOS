import UIKit

class BaseAction: NSObject {
    var title: String?
    var detail: String?
    var accessoryView: UIView?
    var image: UIImage?
    var style: UIAlertAction.Style = .default
}

class ActionSheetAction: BaseAction {
    var actionHandler : () -> Void

    @objc init(title: String?, detail: String?, image: UIImage?, style: UIAlertAction.Style, actionHandler: @escaping () -> Void) {
        self.actionHandler = actionHandler
        super.init()
        self.title = title
        self.detail = detail
        self.image = image
        self.style = style
    }
    
    @objc init(title: String?, detail: String?, accessoryView: UIView?, image: UIImage?, style: UIAlertAction.Style, actionHandler: @escaping () -> Void) {
        self.actionHandler = actionHandler
        super.init()
        self.title = title
        self.detail = detail
        self.accessoryView = accessoryView
        self.image = image
        self.style = style
    }
}

class ActionSheetSwitchAction: ActionSheetAction {
    var switchView: UISwitch?
    
    @objc init(title: String?, detail: String?, switchView: UISwitch, image: UIImage?, style: UIAlertAction.Style, actionHandler: @escaping () -> Void) {
        super.init(title: title, detail: detail, image: image, style: style, actionHandler: actionHandler)
        self.switchView = switchView
    }
    
    @objc func change(state: Bool) {
        switchView?.isOn = state
    }
    
    @objc func switchStatus() -> Bool {
        return switchView?.isOn ?? false
    }
}

class NodeAction: BaseAction {
    var type: MegaNodeActionType

    private init(title: String?, detail: String?, image: UIImage?, type: MegaNodeActionType) {
        self.type = type
        super.init()
        self.title = title
        self.detail = detail
        self.image = image
    }
    
    private init(title: String?, detail: String?, accessoryView: UIView?, image: UIImage?, type: MegaNodeActionType) {
        self.type = type
        super.init()
        self.title = title
        self.detail = detail
        self.accessoryView = accessoryView
        self.image = image
    }
}

// MARK: - Node Actions Factory

extension NodeAction {
    class func shareAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("share", "Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected"), detail: nil, image: UIImage(named: "share"), type: .share)
    }
    
    class func shareFolderAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("shareFolder", "Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected, the folder you want inside your Cloud Drive"), detail: nil, image: UIImage(named: "shareFolder"), type: .shareFolder)
    }
    
    class func manageFolderAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("Manage Share", "Text indicating to the user the action that will be executed on tap."), detail: nil, image: UIImage(named: "shareFolder"), type: .manageShare)
    }
    
    class func downloadAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("download", "Text to perform an action to save a file in offline section"), detail: nil, image: UIImage(named: "offline"), type: .download)
    }
    
    class func infoAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("info", "A button label. The button allows the user to get more info of the current context."), detail: nil, image: UIImage(named: "info"), type: .info)
    }
    
    class func renameAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("rename", "Title for the action that allows you to rename a file or folder"), detail: nil, image: UIImage(named: "rename"), type: .rename)
    }
    
    class func copyAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("copy", "List option shown on the details of a file or folder"), detail: nil, image: UIImage(named: "copy"), type: .copy)
    }
    
    class func moveAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("move", "Title for the action that allows you to move a file or folder"), detail: nil, image: UIImage(named: "move"), type: .move)
    }
    
    class func moveToRubbishBinAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("moveToTheRubbishBin", "Title for the action that allows you to 'Move to the Rubbish Bin' files or folders"), detail: nil, image: UIImage(named: "rubbishBin"), type: .moveToRubbishBin)
    }
    
    class func removeAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("remove", "Title for the action that allows to remove a file or folder"), detail: nil, image: UIImage(named: "remove"), type: .remove)
    }
    
    class func leaveSharingAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("leaveFolder", "Button title of the action that allows to leave a shared folder"), detail: nil, image: UIImage(named: "leaveShare"), type: .leaveSharing)
    }
    
    class func getLinkAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("getLink", "Title shown under the action that allows you to get a link to file or folder"), detail: nil, image: UIImage(named: "link"), type: .getLink)
    }
    
    class func retryAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("retry"), detail: nil, image: UIImage(named: "link"), type: .retry)
    }
    
    class func manageLinkAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("manageLink", "Item menu option upon right click on one or multiple files"), detail: nil, image: UIImage(named: "link"), type: .manageLink)
    }
    
    class func removeLinkAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("removeLink", "Message shown when there is an active link that can be removed or disabled"), detail: nil, image: UIImage(named: "removeLink"), type: .removeLink)
    }
    
    class func removeSharingAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("removeSharing", "Alert title shown on the Shared Items section when you want to remove 1 share"), detail: nil, image: UIImage(named: "removeShare"), type: .removeSharing)
    }
    
    class func viewInFolderAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("View in Folder", "Button title which, if tapped, will trigger the action of opening a folder containg this file"), detail: nil, image: UIImage(named: "searchThin"), type: .viewInFolder)
    }
    
    class func clearAction() -> NodeAction {
        let action = NodeAction(title: AMLocalizedString("clear", "Button title to clear something"), detail: nil, image: UIImage(named: "cancelTransfers"), type: .clear)
        action.style = .destructive
        return action
    }
    
    class func importAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("Import to Cloud Drive", "Button title that triggers the importing link action"), detail: nil, image: UIImage(named: "import"), type: .import)
    }
    
    class func revertVersionAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("revert", "A button label which reverts a certain version of a file to be the current version of the selected file."), detail: nil, image: UIImage(named: "history"), type: .revertVersion)
    }
    
    class func removeVersionAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("delete", "Text for a destructive action for some item. A node version for example."), detail: nil, image: UIImage(named: "remove"), type: .remove)
    }
    
    class func selectAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("select", "Button that allows you to select a given folder"), detail: nil, image: UIImage(named: "select"), type: .select)
    }
    
    class func restoreAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("restore", "Button title to perform a restore action. For example failed purchases or a node in the rubbish bin."), detail: nil, image: UIImage(named: "restore"), type: .restore)
    }
    
    class func saveToPhotosAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("Save to Photos", "A button label which allows the users save images/videos in the Photos app"), detail: nil, image: UIImage(named: "saveToPhotos"), type: .saveToPhotos)
    }
    
    class func sendToChatAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("sendToContact", "Text for the action to send something to a contact through the chat."), detail: nil, image: UIImage(named: "sendMessage"), type: .sendToChat)
    }
    
    class func pdfPageViewAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("Page View", "Text shown when switching from thumbnail view to page view when previewing a document, for example a PDF."), detail: nil, image: UIImage(named: "pageView"), type: .pdfPageView)
    }
    
    class func pdfThumbnailViewAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("Thumbnail View", "Text shown for switching from list view to thumbnail view."), detail: nil, image: UIImage(named: "thumbnailsThin"), type: .pdfThumbnailView)
    }
    
    class func forwardAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("forward", "Item of a menu to forward a message chat to another chatroom"), detail: nil, image: UIImage(named: "forwardToolbar"), type: .forward)
    }
    
    class func searchAction() -> NodeAction {
        return NodeAction(title: AMLocalizedString("Search", "Title of the Spotlight Search section"), detail: nil, image: UIImage(named: "search"), type: .search)
    }
    
    class func favouriteAction(isFavourite: Bool) -> NodeAction {
        return NodeAction(title: isFavourite ? AMLocalizedString("Remove Favourite", "Context menu item. Allows user to delete file/folder from favourites") : AMLocalizedString("Favourite", "Context menu item. Allows user to add file/folder to favourites"), detail: nil, image: isFavourite ? UIImage(named: "removeFavourite") : UIImage(named: "favourite"), type: .favourite)
    }
    
    class func labelAction(label: MEGANodeLabel) -> NodeAction {
        let labelString = MEGANode.string(for: label)
        let detailText = AMLocalizedString(labelString!)
        let image = UIImage(named: labelString!)
        
        return NodeAction(title: AMLocalizedString("Label...", "Context menu item which allows to mark folders with own color label"), detail: (label != .unknown ? detailText : nil), accessoryView: (label != .unknown ? UIImageView(image: image) : nil), image: UIImage(named: "label"), type: .label)
    }
}
