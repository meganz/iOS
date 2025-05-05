// MARK: - Context Menu different types

/// Different context menu items  types defined in the app
///
/// Enum that facilitates the creation of new contextual menus in the app. Depending on the type of menu, a series of actions will be shown or others.
/// Before creating a new menu, check if any currently defined menus apply. In case you need to display more or fewer actions than those defined for a menu already created,
/// you can add new parameters in the ContextMenuBuilder to display the actions correctly in each case.
/// We have two different types of context menu items: Menus or CMEntities and Actions or CMActionEntities. The CMElementTypeEntity enum allows the creation of both types of elements
/// Using the "case menu" to create menus and the other cases to define different actions depending on the type.
///

public enum CMElementTypeEntity: Equatable, Sendable {
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
    case videoPlaylist(actionType: VideoPlaylistActionEntity)
    case unknown
}

// MARK: - Context Menu types
public enum ContextMenuTypeEntity: Sendable {
    case uploadAdd, display, quickActions, sort, rubbishBin, chat, chatStatus, chatDoNotDisturb, qr, meeting, unknown, album, timeline, folderLink, fileLink, home, homeVideos, homeVideoPlaylists, videoPlaylistContent
}

// MARK: - Context Menu grouped actions
public enum UploadAddActionEntity: CaseIterable, Sendable {
    case chooseFromPhotos, capture, importFrom, scanDocument, newFolder, newTextFile, importFolderLink
}

public enum DisplayActionEntity: CaseIterable, Sendable {
    case select, mediaDiscovery, thumbnailView, listView, sort, clearRubbishBin, filter, filterActive, newPlaylist
}

public enum QuickActionEntity: CaseIterable, Sendable {
    case info, download, shareLink, manageLink, removeLink, shareFolder, manageFolder, dispute, rename, copy, removeSharing, leaveSharing, sendToChat, saveToPhotos, hide, unhide, settings
}

public enum RubbishBinActionEntity: CaseIterable, Sendable {
    case restore, info, versions, remove
}

public enum ChatActionEntity: CaseIterable, Sendable {
    case status, doNotDisturb, archivedChats
}

public enum DNDDisabledActionEntity: CaseIterable, Sendable {
    case off
}

public enum MyQRActionEntity: CaseIterable, Sendable {
    case share, qrSettings, resetQR
}

public enum MeetingActionEntity: CaseIterable, Sendable {
    case startMeeting, joinMeeting, scheduleMeeting
}

public enum AlbumActionEntity: CaseIterable, Sendable {
    case selectAlbumCover, delete
}

public enum VideoPlaylistActionEntity: CaseIterable, Sendable {
    case addVideosToVideoPlaylistContent
    case delete
}
