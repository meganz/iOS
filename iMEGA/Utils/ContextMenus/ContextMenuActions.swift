
//MARK: - Context Menu different types

/// Different context menu types defined in the app
///
///  Enum that facilitates the creation of new contextual menus in the app. Depending on the type of menu, a series of actions will be shown or others.
///  Before creating a new menu, check if any of the currently defined menus apply. In case you need to display more or fewer actions than those defined for a menu already created,
///  you can add new parameters in the ContextMenuBuilder to display the actions correctly in each case.
///
enum ContextMenuType {
    case uploadAdd, display, quickFolderActions, sort, rubbishBin, chat, chatStatus, chatDoNotDisturb, qr, unknown
}

//MARK: - Context Menu grouped actions

enum UploadAddAction: String, CaseIterable {
    case chooseFromPhotos, capture, importFrom, scanDocument, newFolder, newTextFile
}

enum DisplayAction: String, CaseIterable {
    case select, mediaDiscovery, thumbnailView, listView, sort, clearRubbishBin
}

enum QuickFolderAction: String, CaseIterable {
    case info, download, shareLink, manageLink, removeLink, shareFolder, manageFolder, rename, copy, removeSharing, leaveSharing
}

enum RubbishBinAction: String, CaseIterable {
    case restore, info, versions, remove
}

enum ChatAction: String, CaseIterable {
    case status, doNotDisturb
}

enum ChatStatusAction: String, CaseIterable {
    case online, away, busy, offline
}

enum DNDDisabledAction: String, CaseIterable {
    case off
}

enum MyQRAction: String, CaseIterable {
    case share, settings, resetQR
}

final class ContextActionSheetAction: BaseAction {
    var identifier: String?
    var actionHandler: (ContextActionSheetAction) -> Void
    
    init(title: String?, detail: String?, image: UIImage?, identifier: String?, actionHandler: @escaping (ContextActionSheetAction) -> Void) {
        self.identifier = identifier
        self.actionHandler = actionHandler
        super.init()
        self.title = title
        self.detail = detail
        self.image = image
    }
}
