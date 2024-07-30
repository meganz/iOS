import Foundation

/// Configure the parameters needed to create a new CMEntity by the ContextMenuBuilder
///
///  - Parameters:
///     - menuType: The type of context menu used in each case
///     - viewMode: The current view mode (List, Thumbnail)
///     - accessLevel: The access level type for the current folder
///     - sortType: The selected sort type for this folder
///     - filterType: The selected filter type for this album
///     - isRubbishBinFolder: Indicates whether or not it is the RubbishBin folder
///     - isRestorable: Indicates if the current node is restorable
///     - isOfflineFolder: Indicates whether or not it is the Offline folder
///     - isInVersionsView: Indicates whether or not it is versions view
///     - isSharedItems: Indicates whether or not it is the shared items screen
///     - isIncomingShareChild: Indicates whether or not it is an incoming shared child folder
///     - isHome: Indicates whether or not it is the home screen
///     - isDocumentExplorer: Indicates whether or not it is the home docs explorer
///     - isAudiosExplorer: Indicates whether or not it is the home audios explorer
///     - isVideosExplorer: Indicates whether or not it is the home videos explorer
///     - isVideosRevampExplorer: Indicates whether or not it is the home videos revamp explorer
///     - isVideosRevampExplorerVideoPlaylists:Indicates whether or not it is the home videos revamp explorer specific on Video playlists tab
///     - isCameraUploadExplorer: Indicates whether or not it is the camera upload explorer
///     - albumType: Indicates whether or not it is the album and the type of album
///     - isFilterEnabled: Indicates whether or not if the filter is enabled
///     - isDoNotDisturbEnabled: Indicates wether or not the notifications are disabled
///     - isBackupsRootNode: Indicates if the current node is the Backups root node
///     - isBackupsChild: Indicates if the current node is a Backups node child
///     - isSelectHidden: Indicates if select is shown in menu
///     - isShareAvailable: Indicates if the share action is available
///     - isSharedItemsChild: Indicates if the current node is a shared items child
///     - isOutShare: Indicates if the current node is being shared with other users
///     - isExported: Indicates if the current node has been exported
///     - isEmptyState: Indicates whether an empty state is currently being displayed
///     - timeRemainingToDeactiveDND: Indicates the remaining time to active again the notifications
///     - versionsCount: The number of versions of the current node
///     - showMediaDiscovery:  Indicates whether or not it is avaiable to show Media Discovery
///     - chatStatus: Indicates the user chat status (online, away, busy, offline...)
///     - shouldStartMeeting: Indicates whether or not to start a meeting
///     - shouldJoiningMeeting: Indicated whether or not to join a meeting
///     - sharedLinkStatus: Indicates current status of shared link
///     - isArchivedChatsVisible: Show archived chats action if exists some chat archived
///     - isHidden: Indicates if the current node is hidden 
///
public struct CMConfigEntity: Sendable {
    public let menuType: CMElementTypeEntity
    public var viewMode: ViewModePreferenceEntity?
    public var accessLevel: ShareAccessLevelEntity?
    public var sortType: SortOrderEntity?
    public var filterType: FilterEntity?
    public var isAFolder: Bool
    public var isRubbishBinFolder: Bool
    public var isViewInFolder: Bool
    public var isRestorable: Bool
    public var isInVersionsView: Bool
    public var isOfflineFolder: Bool
    public var isSharedItems: Bool
    public var isIncomingShareChild: Bool
    public var isHome: Bool
    public var isFavouritesExplorer: Bool
    public var isDocumentExplorer: Bool
    public var isAudiosExplorer: Bool
    public var isVideosExplorer: Bool
    public var isVideosRevampExplorer: Bool
    public var isVideosRevampExplorerVideoPlaylists: Bool
    public var isVideoPlaylistContent: Bool
    public var isCameraUploadExplorer: Bool
    public var albumType: AlbumEntityType?
    public var isFilterEnabled: Bool
    public var isDoNotDisturbEnabled: Bool
    public var isBackupsRootNode: Bool
    public var isBackupsChild: Bool
    public var isSelectHidden: Bool
    public var isShareAvailable: Bool
    public var isSharedItemsChild: Bool
    public var isOutShare: Bool
    public var isExported: Bool
    public var isEmptyState: Bool
    public var timeRemainingToDeactiveDND: String?
    public var versionsCount: Int
    public var showMediaDiscovery: Bool
    public var chatStatus: ChatStatusEntity
    public var shouldStartMeeting: Bool
    public var shouldJoiningMeeting: Bool
    public var shouldScheduleMeeting: Bool
    public var sharedLinkStatus: SharedLinkStatusEntity?
    public var isArchivedChatsVisible: Bool = false
    public var isMediaFile: Bool = false
    public var isFilterActive: Bool = false
    public var isHidden: Bool?
    public var isCameraUploadsEnabled: Bool

    public init(menuType: CMElementTypeEntity, viewMode: ViewModePreferenceEntity? = nil, accessLevel: ShareAccessLevelEntity? = nil, sortType: SortOrderEntity? = nil, filterType: FilterEntity? = nil, isAFolder: Bool = false, isRubbishBinFolder: Bool = false, isViewInFolder: Bool = false, isRestorable: Bool = false, isInVersionsView: Bool = false, isOfflineFolder: Bool = false, isSharedItems: Bool = false, isIncomingShareChild: Bool = false, isHome: Bool = false, isFavouritesExplorer: Bool = false, isDocumentExplorer: Bool = false, isAudiosExplorer: Bool = false, isVideosExplorer: Bool = false, isVideosRevampExplorer: Bool = false, isVideosRevampExplorerVideoPlaylists: Bool = false, isVideoPlaylistContent: Bool = false, isCameraUploadExplorer: Bool = false, albumType: AlbumEntityType? = nil, isFilterEnabled: Bool = false, isDoNotDisturbEnabled: Bool = false, isBackupsRootNode: Bool = false, isBackupsChild: Bool = false, isSelectHidden: Bool = false, isShareAvailable: Bool = false, isSharedItemsChild: Bool = false, isOutShare: Bool = false, isExported: Bool = false, isEmptyState: Bool = false, timeRemainingToDeactiveDND: String? = nil, versionsCount: Int = 0, showMediaDiscovery: Bool = false, chatStatus: ChatStatusEntity = .invalid, shouldStartMeeting: Bool = false, shouldJoiningMeeting: Bool = false, shouldScheduleMeeting: Bool = false, sharedLinkStatus: SharedLinkStatusEntity? = nil, isArchivedChatsVisible: Bool = false, isMediaFile: Bool = false, isFilterActive: Bool = false, isHidden: Bool? = nil, isCameraUploadsEnabled: Bool = false) {
        self.menuType = menuType
        self.viewMode = viewMode
        self.accessLevel = accessLevel
        self.sortType = sortType
        self.filterType = filterType
        self.isAFolder = isAFolder
        self.isRubbishBinFolder = isRubbishBinFolder
        self.isViewInFolder = isViewInFolder
        self.isRestorable = isRestorable
        self.isInVersionsView = isInVersionsView
        self.isOfflineFolder = isOfflineFolder
        self.isSelectHidden = isSelectHidden
        self.isSharedItems = isSharedItems
        self.isIncomingShareChild = isIncomingShareChild
        self.isHome = isHome
        self.isFavouritesExplorer = isFavouritesExplorer
        self.isDocumentExplorer = isDocumentExplorer
        self.isAudiosExplorer = isAudiosExplorer
        self.isVideosExplorer = isVideosExplorer
        self.isVideosRevampExplorer = isVideosRevampExplorer
        self.isVideosRevampExplorerVideoPlaylists = isVideosRevampExplorerVideoPlaylists
        self.isVideoPlaylistContent = isVideoPlaylistContent
        self.isCameraUploadExplorer = isCameraUploadExplorer
        self.albumType = albumType
        self.isFilterEnabled = isFilterEnabled
        self.isDoNotDisturbEnabled = isDoNotDisturbEnabled
        self.isBackupsRootNode = isBackupsRootNode
        self.isBackupsChild = isBackupsChild
        self.isShareAvailable = isShareAvailable
        self.isSharedItemsChild = isSharedItemsChild
        self.isOutShare = isOutShare
        self.isExported = isExported
        self.isEmptyState = isEmptyState
        self.timeRemainingToDeactiveDND = timeRemainingToDeactiveDND
        self.versionsCount = versionsCount
        self.showMediaDiscovery = showMediaDiscovery
        self.chatStatus = chatStatus
        self.shouldStartMeeting = shouldStartMeeting
        self.shouldJoiningMeeting = shouldJoiningMeeting
        self.shouldScheduleMeeting = shouldScheduleMeeting
        self.sharedLinkStatus = sharedLinkStatus
        self.isArchivedChatsVisible = isArchivedChatsVisible
        self.isMediaFile = isMediaFile
        self.isFilterActive = isFilterActive
        self.isHidden = isHidden
        self.isCameraUploadsEnabled = isCameraUploadsEnabled
    }
}
