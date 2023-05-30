
// MARK: - Context Menu different types

/// Different context menu items  types defined in the app
///
/// Enum that facilitates the creation of new contextual menus in the app. Depending on the type of menu, a series of actions will be shown or others.
/// Before creating a new menu, check if any currently defined menus apply. In case you need to display more or fewer actions than those defined for a menu already created,
/// you can add new parameters in the ContextMenuBuilder to display the actions correctly in each case.
/// We have two different types of context menu items: Menus or CMEntities and Actions or CMActionEntities. The CMElementTypeEntity enum allows the creation of both types of elements
/// Using the "case menu" to create menus and the other cases to define different actions depending on the type.
///

public enum CMElementTypeEntity: Equatable {
    /// Menus
    case menu(type: ContextMenuTypeEntity)
    
    // Actions
    case uploadAdd(actionType: UploadAddActionEntity)
    case display(actionType: DisplayActionEntity)
    case quickActions(actionType: QuickActionEntity)
    case sort(actionType: SortOrderEntity)
    case filter(actionType: FilterEntity)
    case rubbishBin(actionType: RubbishBinActionEntity)
    case chat(actionType: ChatActionEntity)
    case chatStatus(actionType: ChatStatusEntity)
    case chatDoNotDisturbDisabled(actionType: DNDDisabledActionEntity)
    case chatDoNotDisturbEnabled(optionType: DNDTurnOnOptionEntity)
    case qr(actionType: MyQRActionEntity)
    case meeting(actionType: MeetingActionEntity)
    case album(actionType: AlbumActionEntity)
    
    case unknown
}

// MARK: - Context Menu types
public enum ContextMenuTypeEntity {
    case uploadAdd, display, quickActions, sort, rubbishBin, chat, chatStatus, chatDoNotDisturb, qr, meeting, unknown, album, timeline
}

// MARK: - Context Menu grouped actions
public enum UploadAddActionEntity: CaseIterable {
    case chooseFromPhotos, capture, importFrom, scanDocument, newFolder, newTextFile
}

public enum DisplayActionEntity: CaseIterable {
    case select, mediaDiscovery, thumbnailView, listView, sort, clearRubbishBin, filter
}

public enum QuickActionEntity: CaseIterable {
    case info, download, shareLink, manageLink, removeLink, shareFolder, manageFolder, rename, copy, removeSharing, leaveSharing
}

public enum RubbishBinActionEntity: CaseIterable {
    case restore, info, versions, remove
}

public enum ChatActionEntity: CaseIterable {
    case status, doNotDisturb, archivedChats
}

public enum DNDDisabledActionEntity: CaseIterable {
    case off
}

public enum MyQRActionEntity: CaseIterable {
    case share, settings, resetQR
}

public enum MeetingActionEntity: CaseIterable  {
    case startMeeting, joinMeeting, scheduleMeeting
}

public enum AlbumActionEntity: CaseIterable {
    case selectAlbumCover, delete
}
