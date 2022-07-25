
/// Configure the parameters needed to create a new CMEntity by the ContextMenuBuilder
///
///  - Parameters:
///     - menuType: The type of context menu used in each case
///     - viewMode: The current view mode (List, Thumbnail)
///     - accessLevel: The access level type for the current folder
///     - sortType: The selected sort type for this folder
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
///     - isCameraUploadExplorer: Indicates whether or not it is the camera upload explorer
///     - isFilterEnabled: Indicates whether or not if the filter is enabled
///     - isDoNotDisturbEnabled: Indicates wether or not the notifications are disabled
///     - isShareAvailable: Indicates if the share action is available
///     - isSharedItemsChild: Indicates if the current node is a shared items child
///     - isOutShare: Indicates if the current node is being shared with other users
///     - isExported: Indicates if the currrent node has been exported
///     - timeRemainingToDeactiveDND: Indicates the remaining time to active again the notifications
///     - versionsCount: The number of versions of the current node
///     - showMediaDiscovery:  Indicates whether or not it is avaiable to show Media Discovery
///     - chatStatus: Indicates the user chat status (online, away, busy, offline...)
///     - shouldStartMeeting: Indicates whether or not to start a meeting
///     - shouldJoiningMeeting: Indicated whether or not to join a meeting
///
struct CMConfigEntity {
    let menuType: ContextMenuType
    var viewMode: ViewModePreference? = nil
    var accessLevel: MEGAShareType? = nil
    var sortType: SortOrderType? = nil
    var isAFolder: Bool = false
    var isRubbishBinFolder: Bool = false
    var isRestorable: Bool = false
    var isInVersionsView: Bool = false
    var isOfflineFolder: Bool = false
    var isSharedItems: Bool = false
    var isIncomingShareChild: Bool = false
    var isHome: Bool = false
    var isFavouritesExplorer: Bool = false
    var isDocumentExplorer: Bool = false
    var isAudiosExplorer: Bool = false
    var isVideosExplorer: Bool = false
    var isCameraUploadExplorer: Bool = false
    var isFilterEnabled: Bool = false
    var isDoNotDisturbEnabled: Bool = false
    var isShareAvailable: Bool = false
    var isSharedItemsChild: Bool = false
    var isOutShare: Bool = false
    var isExported: Bool = false
    var timeRemainingToDeactiveDND: String? = nil
    var versionsCount: Int = 0
    var showMediaDiscovery: Bool = false
    var chatStatus: ChatStatus = .invalid
    var shouldStartMeeting = false
    var shouldJoiningMeeting = false
}
