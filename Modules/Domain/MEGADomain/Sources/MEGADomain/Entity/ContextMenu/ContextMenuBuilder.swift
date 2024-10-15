public final class ContextMenuBuilder {
    private var menuType: CMElementTypeEntity = .unknown
    private var accessLevel: ShareAccessLevelEntity = .unknown
    private var viewMode: ViewModePreferenceEntity = .list
    private var sortType: SortOrderEntity = .defaultAsc
    private var filterType: FilterEntity = .allMedia
    private var isAFolder: Bool = false
    private var isRubbishBinFolder: Bool = false
    private var isOfflineFolder: Bool = false
    private var isViewInFolder = false
    private var isRestorable: Bool = false
    private var isInVersionsView: Bool = false
    private var isSelectHidden: Bool = false
    private var isSharedItems: Bool = false
    private var isIncomingShareChild: Bool = false
    private var isHome: Bool = false
    private var isFavouritesExplorer: Bool = false
    private var isDocumentExplorer: Bool = false
    private var isAudiosExplorer: Bool = false
    private var isVideosExplorer: Bool = false
    private var isVideosRevampExplorer: Bool = false
    private var isVideosRevampExplorerVideoPlaylists: Bool = false
    private var isVideoPlaylistContent: Bool = false
    private var isCameraUploadExplorer: Bool = false
    private var albumType: AlbumEntityType?
    private var isFilterEnabled: Bool = false
    private var isDoNotDisturbEnabled: Bool = false
    private var isShareAvailable: Bool = false
    private var isBackupsRootNode: Bool = false
    private var isBackupsChild: Bool = false
    private var isSharedItemsChild: Bool = false
    private var isOutShare: Bool = false
    private var isExported: Bool = false
    private var isEmptyState: Bool = false
    private var timeRemainingToDeactiveDND: String?
    private var versionsCount: Int = 0
    private var showMediaDiscovery: Bool = false
    private var chatStatus: ChatStatusEntity = .invalid
    private var shouldScheduleMeeting = false
    private var sharedLinkStatus: SharedLinkStatusEntity = .unavailable
    private var isArchivedChatsVisible: Bool = false
    private var isMediaFile: Bool = false
    private var isFilterActive: Bool = false
    private var isHidden: Bool?
    private var isCameraUploadsEnabled: Bool = false
    private var isVideoPlaylistSharingFeatureFlagEnabled: Bool = false

    public init() {}
    
    public func setType(_ menuType: CMElementTypeEntity?) -> ContextMenuBuilder {
        self.menuType = menuType ?? .unknown
        return self
    }
    
    public func setAccessLevel(_ accessLevel: ShareAccessLevelEntity?) -> ContextMenuBuilder {
        self.accessLevel = accessLevel ?? .unknown
        return self
    }
    
    public func setViewMode(_ viewMode: ViewModePreferenceEntity?) -> ContextMenuBuilder {
        self.viewMode = viewMode ?? .list
        return self
    }
    
    public func setSortType(_ sortType: SortOrderEntity?) -> ContextMenuBuilder {
        self.sortType = sortType ?? .defaultAsc
        return self
    }
    
    public func setFilterType(_ filterType: FilterEntity?) -> ContextMenuBuilder {
        self.filterType = filterType ?? .allMedia
        return self
    }
    
    public func setIsAFolder(_ isAFolder: Bool) -> ContextMenuBuilder {
        self.isAFolder = isAFolder
        return self
    }
    
    public func setIsRubbishBinFolder(_ isRubbishBinFolder: Bool) -> ContextMenuBuilder {
        self.isRubbishBinFolder = isRubbishBinFolder
        return self
    }
    
    public func setIsOfflineFolder(_ isOfflineFolder: Bool) -> ContextMenuBuilder {
        self.isOfflineFolder = isOfflineFolder
        return self
    }
    
    public func setIsViewInFolder(_ isViewInFolder: Bool) -> ContextMenuBuilder {
        self.isViewInFolder = isViewInFolder
        return self
    }
    
    public func setIsRestorable(_ isRestorable: Bool) -> ContextMenuBuilder {
        self.isRestorable = isRestorable
        return self
    }
    
    public func setIsInVersionsView(_ isInVersionsView: Bool) -> ContextMenuBuilder {
        self.isInVersionsView = isInVersionsView
        return self
    }
    
    public func setIsSelectHidden(_ isSelectHidden: Bool) -> ContextMenuBuilder {
        self.isSelectHidden = isSelectHidden
        return self
    }
    
    public func setIsSharedItems(_ isSharedItems: Bool) -> ContextMenuBuilder {
        self.isSharedItems = isSharedItems
        return self
    }
    
    public func setIsIncomingShareChild(_ isIncomingShareChild: Bool) -> ContextMenuBuilder {
        self.isIncomingShareChild = isIncomingShareChild
        return self
    }
    
    public func setIsHome(_ isHome: Bool) -> ContextMenuBuilder {
        self.isHome = isHome
        return self
    }
    
    public func setIsFavouritesExplorer(_ isFavouritesExplorer: Bool) -> ContextMenuBuilder {
        self.isFavouritesExplorer = isFavouritesExplorer
        return self
    }
    
    public func setIsDocumentExplorer(_ isDocumentExplorer: Bool) -> ContextMenuBuilder {
        self.isDocumentExplorer = isDocumentExplorer
        return self
    }
    
    public func setIsAudiosExplorer(_ isAudiosExplorer: Bool) -> ContextMenuBuilder {
        self.isAudiosExplorer = isAudiosExplorer
        return self
    }
    
    public func setIsVideosExplorer(_ isVideosExplorer: Bool) -> ContextMenuBuilder {
        self.isVideosExplorer = isVideosExplorer
        return self
    }
    
    public func setIsVideosRevampExplorer(_ isVideosRevampExplorer: Bool) -> ContextMenuBuilder {
        self.isVideosRevampExplorer = isVideosRevampExplorer
        return self
    }
    
    public func setIsVideosRevampExplorerVideoPlaylists(_ isVideosRevampExplorerVideoPlaylists: Bool) -> ContextMenuBuilder {
        self.isVideosRevampExplorerVideoPlaylists = isVideosRevampExplorerVideoPlaylists
        return self
    }
    
    public func setIsVideoPlaylistContent(_ isVideoPlaylistContent: Bool) -> ContextMenuBuilder {
        self.isVideoPlaylistContent = isVideoPlaylistContent
        return self
    }
    
    public func setIsCameraUploadExplorer(_ isCameraUploadExplorer: Bool) -> ContextMenuBuilder {
        self.isCameraUploadExplorer = isCameraUploadExplorer
        return self
    }
    
    public func setAlbumType(_ albumType: AlbumEntityType?) -> ContextMenuBuilder {
        self.albumType = albumType
        return self
    }
    
    public func setIsFilterEnabled(_ isFilterEnabled: Bool) -> ContextMenuBuilder {
        self.isFilterEnabled = isFilterEnabled
        return self
    }
    
    public func setIsDoNotDisturbEnabled(_ isDoNotDisturbEnabled: Bool) -> ContextMenuBuilder {
        self.isDoNotDisturbEnabled = isDoNotDisturbEnabled
        return self
    }
    
    public func setIsShareAvailable(_ isShareAvailable: Bool) -> ContextMenuBuilder {
        self.isShareAvailable = isShareAvailable
        return self
    }
    
    public func setBackupsRootNode(_ isBackupsNode: Bool) -> ContextMenuBuilder {
        self.isBackupsRootNode = isBackupsNode
        return self
    }
    
    public func setIsBackupsChild(_ isBackupsChild: Bool) -> ContextMenuBuilder {
        self.isBackupsChild = isBackupsChild
        return self
    }
    
    public func setIsSharedItemsChild(_ isSharedItemsChild: Bool) -> ContextMenuBuilder {
        self.isSharedItemsChild = isSharedItemsChild
        return self
    }
    
    public func setIsOutShare(_ isOutShare: Bool) -> ContextMenuBuilder {
        self.isOutShare = isOutShare
        return self
    }
    
    public func setIsExported(_ isExported: Bool) -> ContextMenuBuilder {
        self.isExported = isExported
        return self
    }
    
    public func setIsEmptyState(_ isEmptyState: Bool) -> ContextMenuBuilder {
        self.isEmptyState = isEmptyState
        return self
    }
    
    public func setTimeRemainingToDeactiveDND(_ timeRemainingToDeactiveDND: String?) -> ContextMenuBuilder {
        self.timeRemainingToDeactiveDND = timeRemainingToDeactiveDND
        return self
    }
    
    public func setVersionsCount(_ versionsCount: Int) -> ContextMenuBuilder {
        self.versionsCount = versionsCount
        return self
    }
    
    public func setShowMediaDiscovery(_ showMediaDiscovery: Bool) -> ContextMenuBuilder {
        self.showMediaDiscovery = showMediaDiscovery
        return self
    }
    
    public func setChatStatus(_ chatStatus: ChatStatusEntity) -> ContextMenuBuilder {
        self.chatStatus = chatStatus
        return self
    }
    
    public func setShouldScheduleMeeting(_ shouldScheduleMeeting: Bool) -> ContextMenuBuilder {
        self.shouldScheduleMeeting = shouldScheduleMeeting
        return self
    }
    
    public func setSharedLinkStatus(_ sharedLinkStatus: SharedLinkStatusEntity?) -> ContextMenuBuilder {
        self.sharedLinkStatus = sharedLinkStatus ?? .unavailable
        return self
    }
    
    public func setIsArchivedChatsVisible(_ archivedChatVisible: Bool) -> ContextMenuBuilder {
        isArchivedChatsVisible = archivedChatVisible
        return self
    }

    public func setIsMediaFile(_ isMediaFile: Bool) -> ContextMenuBuilder {
        self.isMediaFile = isMediaFile
        return self
    }
    
    public func setIsFilterActive(_ isActive: Bool) -> ContextMenuBuilder {
        self.isFilterActive = isActive
        return self
    }
    
    public func setIsHidden(_ isHidden: Bool?) -> ContextMenuBuilder {
        self.isHidden = isHidden
        return self
    }
    
    public func setIsCameraUploadsEnabled(_ isCameraUploadsEnabled: Bool) -> ContextMenuBuilder {
        self.isCameraUploadsEnabled = isCameraUploadsEnabled
        return self
    }
    
    public func setIsVideoPlaylistSharingFeatureFlagEnabled(_ isEnabled: Bool) -> ContextMenuBuilder {
        self.isVideoPlaylistSharingFeatureFlagEnabled = isEnabled
        return self
    }
    
    public func build() -> CMEntity? {
        /// It is only allowed to build menu type elements. The other elements refer to the actions that a menu contains, and that cannot be constructed if not inside a menu.
        if case let .menu(type) = menuType {
            switch type {
            case .uploadAdd:
                return uploadAddMenu()
            case .display:
                return displayMenu()
            case .rubbishBin:
                return rubbishBinChildFolderMenu()
            case .chat:
                return chatMenu()
            case .qr:
                return myQRCodeMenu()
            case .meeting:
                return meetingMenu()
            case .album:
                return albumMenu()
            case .timeline:
                return timelineMenu()
            case .folderLink:
                return folderLinkMenu()
            case .fileLink:
                return fileLinkMenu()
            case .home:
                return homeMenu()
            case .homeVideos:
                return homeVideosMenu()
            case .homeVideoPlaylists:
                return homeVideoPlaylistsMenu()
            case .videoPlaylistContent:
                return videoPlaylistContentMenu()
            default:
                return nil
            }
        }
        return nil
    }
    
    func currentViewMode() -> ViewModePreferenceEntity {
        viewMode
    }
    
    func currentSortType() -> SortOrderEntity {
        sortType
    }
    
    func currentFilterType() -> FilterEntity {
        filterType
    }
    
    func currentChatStatus() -> ChatStatusEntity {
        chatStatus
    }
    
    func currentTimeRemainingToDeactiveDND() -> String? {
        timeRemainingToDeactiveDND
    }

    // MARK: - Upload Add Context Actions grouping functions
    private func uploadAddMenu() -> CMEntity {
        var uploadAddActions: [CMElement] = []
        
        if isHome {
            uploadAddActions.append(contentsOf: [choosePhotoVideo, newTextFile, scanDocument, capturePhotoVideo, importFromFiles])
        } else if isDocumentExplorer {
            uploadAddActions.append(contentsOf: [newTextFile, scanDocument, importFromFiles])
        } else if viewMode == .mediaDiscovery {
            uploadAddActions.append(contentsOf: [choosePhotoVideo, capturePhotoVideo])
        } else {
            uploadAddActions.append(contentsOf: [choosePhotoVideo, capturePhotoVideo, importFromFiles, scanDocument, newFolder, newTextFile])
        }
        
        return CMEntity(displayInline: true,
                        children: uploadAddActions)
    }
    
    // MARK: - Display Context Actions grouping functions
    private func selectMenu() -> CMEntity {
        let selectAction = select
        
        if isEmptyState {
            selectAction.isEnabled = false
        }
        
        return CMEntity(displayInline: true,
                        children: [selectAction]
        )
    }
    
    private func viewTypeMenu() -> CMEntity {
        var viewTypeMenuActions: [CMElement] = []
        
        if showMediaDiscovery && !isRubbishBinFolder && !isBackupsChild {
            viewTypeMenuActions.append(mediaDiscovery)
        }
        
        viewTypeMenuActions.append(contentsOf: [thumbnailView, listView])
        
        return CMEntity(displayInline: true,
                        children: viewTypeMenuActions
        )
    }
    
    private func rubbishBinMenu() -> CMEntity {
        CMEntity(displayInline: true,
                 children: [emptyRubbishBin]
        )
    }
    
    private func newPlaylistMenu() -> CMEntity {
        CMEntity(
            displayInline: true,
            children: [ newPlaylist ]
        )
    }
    
    private func sortMenu() -> CMElement {
        if isEmptyState {
            return CMActionEntity(type: .display(actionType: .sort),
                                  isEnabled: false)
        } else {
            var sortMenuActions = [sortNameAscending, sortNameDescending]
            
            if isCameraUploadExplorer || isAlbum || viewMode == .mediaDiscovery {
                sortMenuActions = [sortNewest, sortOldest]
            } else if isVideosRevampExplorerVideoPlaylists {
                sortMenuActions = [sortNewest, sortOldest]
                return CMEntity(type: .display(actionType: .sort),
                                currentSortType: sortType,
                                children: sortMenuActions)
            } else if isVideoPlaylistContent {
                sortMenuActions = [ sortNameAscending, sortNameDescending, sortNewest, sortOldest ]
            } else if !isSharedItems {
                sortMenuActions.append(contentsOf: [sortLargest, sortSmallest, sortNewest, sortOldest])
                if !isOfflineFolder {
                    sortMenuActions.append(sortLabel)
                    if !isFavouritesExplorer {
                        sortMenuActions.append(sortFavourite)
                    }
                }
            }
            return CMEntity(type: .display(actionType: .sort),
                            currentSortType: sortType,
                            children: sortMenuActions)
        }
    }
    
    private func filterMenu() -> CMEntity {
        if isAlbum {
            return CMEntity(type: .display(actionType: .filter),
                            currentFilterType: filterType,
                            children: [CMEntity(displayInline: true, children: [filterAllMedia]),
                                        filterImages,
                                        filterVideos])
        } else {
            return CMEntity(displayInline: true,
                     children: [filter(isActive: isFilterActive)])
        }
    }
    
    private func displayMenu() -> CMEntity {
        var displayActionsMenuChildren: [CMElement] = []
        
        if isAFolder && !isRubbishBinFolder && !isBackupsRootNode {
            displayActionsMenuChildren.append(makeQuickActions())
        }
        
        if isSharedItems || isAudiosExplorer {
            displayActionsMenuChildren.append(contentsOf: [selectMenu(), sortMenu()])
        } else if isVideosExplorer {
            displayActionsMenuChildren.append(contentsOf: [sortMenu()])
        } else if isVideosRevampExplorer {
            displayActionsMenuChildren.append(contentsOf: [selectMenu(), sortMenu()])
        } else if isVideosRevampExplorerVideoPlaylists {
            displayActionsMenuChildren.append(contentsOf: [newPlaylistMenu(), sortMenu()])
        } else if isCameraUploadExplorer {
            displayActionsMenuChildren = [selectMenu(), sortMenu()]
            if isFilterEnabled {
                displayActionsMenuChildren.append(filterMenu())
            }
        } else {
            let menu: [CMElement]
            if isViewInFolder || isSelectHidden {
                menu = [viewTypeMenu(), sortMenu()]
            } else {
                menu = [selectMenu(), viewTypeMenu(), sortMenu()]
            }
            
            displayActionsMenuChildren.append(contentsOf: menu)
        }
        
        if isRubbishBinFolder && !isViewInFolder {
            displayActionsMenuChildren.append(rubbishBinMenu())
        }
        
        return CMEntity(displayInline: true,
                        children: displayActionsMenuChildren)
    }
    
    private func makeQuickActions() -> CMEntity {
        var quickActions: [CMElement] = [info, download]
        
        if accessLevel == .owner {
            quickActions.append(contentsOf: isExported ? [manageLink, removeLink] : [shareLink])
            quickActions.append(contentsOf: isOutShare ? [manageFolder] : [shareFolder])
            if !isBackupsChild {
                quickActions.append(rename)
            }
        }
        
        if isHidden == true {
            quickActions.append(unhide)
        } else if isHidden == false {
            quickActions.append(hide)
        }
        
        quickActions.append(copy)
        
        if isIncomingShareChild {
            quickActions.append(leaveSharing)
        }
        
        if isSharedItemsChild, isOutShare {
            quickActions.append(removeSharing)
        }
        
        return CMEntity(displayInline: true,
                        children: quickActions)
    }

    private func makeFolderLinkQuickActions() -> CMEntity {
        return CMEntity(
            displayInline: true,
            children: [
                selectMenu(),
                importFolderLink,
                download,
                shareLink,
                sendToChat
            ]
        )
    }
    
    // MARK: - Rubbish Bin Children Context Actions grouping functions
    private func rubbishBinChildFolderMenu() -> CMEntity {
        CMEntity(displayInline: true, children: [selectMenu(), viewTypeMenu(), sortMenu(), rubbishBinChildQuickActionsMenu()])
    }
    
    private func rubbishBinChildQuickActionsMenu() -> CMEntity {
        var rubbishBinActions = [CMActionEntity]()
        
        if isRestorable {
            rubbishBinActions.append(restore)
        }
        
        rubbishBinActions.append(infoRubbishBin)
        
        if !isInVersionsView {
            if versionsCount > 0 {
                rubbishBinActions.append(versions)
            }
            rubbishBinActions.append(remove)
        }
        
        return CMEntity(displayInline: true, children: rubbishBinActions)
    }
    
    // MARK: - Chat Context Actions
    private func chatMenu() -> CMEntity {
        if isArchivedChatsVisible {
            return CMEntity(displayInline: true, children: [chatStatusMenu(), doNotDisturbMenu(), CMActionEntity(type: .chat(actionType: .archivedChats))])
        } else {
            return CMEntity(displayInline: true, children: [chatStatusMenu(), doNotDisturbMenu()])
        }
    }
    
    private func chatStatusMenu() -> CMEntity {
        CMEntity(type: .chat(actionType: .status),
                 currentChatStatus: currentChatStatus(),
                 children: ChatStatusEntity
                                    .allCases
                                    .filter { $0 != .invalid }
                                    .compactMap(chatStatus))
    }
    
    private func doNotDisturbMenu() -> CMEntity {
        var doNotDisturbElements = [CMElement]()
        doNotDisturbElements.append(CMEntity(displayInline: true,
                                             children: [CMActionEntity(type: .chatDoNotDisturbDisabled(actionType: .off),
                                                                       state: isDoNotDisturbEnabled ? .off : .on)]))
            
        if !isDoNotDisturbEnabled {
            doNotDisturbElements.append(CMEntity(displayInline: true,
                                                 children: DNDTurnOnOptionEntity
                                                                        .allCases
                                                                        .filter { $0 != .forever }
                                                                        .compactMap(doNotDisturb)))
        }
                        
        return CMEntity(type: .chat(actionType: .doNotDisturb),
                        dndRemainingTime: isDoNotDisturbEnabled ? currentTimeRemainingToDeactiveDND() : nil,
                        children: doNotDisturbElements)
    }
    
    // MARK: - Meeting Context Actions
    private func meetingMenu() -> CMEntity {
        CMEntity(
            displayInline: true,
            children: shouldScheduleMeeting ? [startMeeting, joinMeeting, scheduleMeeting] : [startMeeting, joinMeeting]
        )
    }
    
    // MARK: - My QR Code Actions
    private func myQRCodeMenu() -> CMEntity {
        var myQRCodeActions = [CMActionEntity]()
        
        if isShareAvailable {
            myQRCodeActions.append(share)
        }
        
        myQRCodeActions.append(contentsOf: [qrSettings, resetQR])
        
        return CMEntity(displayInline: true,
                        children: myQRCodeActions)
    }
    
    // MARK: - Album
    private var isAlbum: Bool {
        albumType != nil
    }
    
    private func albumMenu() -> CMEntity {
        guard let albumType else { return CMEntity(displayInline: true, children: []) }
        var displayActionsMenuChildren = [CMElement]()
        
        if albumType == .user && isEmptyState {
            var children = [CMElement]()
            children.append(contentsOf: userAlbumLinkMenuItems())
            children.append(contentsOf: [rename, CMEntity(displayInline: true, children: [delete])])
            return CMEntity(displayInline: true,
                            children: children)
        }
        
        if albumType == .user {
            displayActionsMenuChildren.append(userAlbumMenu())
        } else if !isSelectHidden {
            displayActionsMenuChildren.append(selectMenu())
        }
        
        if !isEmptyState {
            displayActionsMenuChildren.append(CMEntity(displayInline: true, children: [sortMenu()]))
        }
        if isFilterEnabled {
            displayActionsMenuChildren.append(filterMenu())
        }
        
        if albumType == .user {
            displayActionsMenuChildren.append(CMEntity(displayInline: true, children: [delete]))
        }
        
        return CMEntity(displayInline: true, children: displayActionsMenuChildren)
    }
    
    private func userAlbumMenu() -> CMEntity {
        var children = [CMElement]()
        children.append(contentsOf: userAlbumLinkMenuItems())
        children.append(contentsOf: [rename, selectAlbumCover])
        if !isSelectHidden {
            children.append(contentsOf: selectMenu().children)
        }
        
        return CMEntity(displayInline: true, children: children)
    }
    
    private func userAlbumLinkMenuItems() -> [CMElement] {
        if case let .exported(isLinkExported) = sharedLinkStatus {
            return isLinkExported ? [manageLink, removeLink] : [shareLink]
        }
        return []
    }
    
    private func timelineMenu() -> CMEntity {
        var displayActionsMenuChildren: [CMElement] = []
        if !isSelectHidden {
            displayActionsMenuChildren.append(selectMenu())
        }
        if isCameraUploadExplorer {
            displayActionsMenuChildren.append(sortMenu())
            if isFilterEnabled {
                displayActionsMenuChildren.append(filterMenu())
            }
        }
        
        if isCameraUploadsEnabled {
            displayActionsMenuChildren.append(settings)
        }
        
        return CMEntity(displayInline: true,
                        children: displayActionsMenuChildren)
    }
    
    // MARK: - HomeVideos
    
    private func homeVideosMenu() -> CMEntity {
        var displayActionsMenuChildren: [CMElement] = []
        if !isSelectHidden {
            displayActionsMenuChildren.append(selectMenu())
        }
        displayActionsMenuChildren.append(sortMenu())
        return CMEntity(
            displayInline: true,
            children: displayActionsMenuChildren
        )
    }
    
    // MARK: - HomeVideos - VideoPlaylists
    
    private func homeVideoPlaylistsMenu() -> CMEntity {
        var displayActionsMenuChildren: [CMElement] = []
        
        displayActionsMenuChildren.append(newPlaylistMenu())
        displayActionsMenuChildren.append(sortMenu())
        
        return CMEntity(
            displayInline: true,
            children: displayActionsMenuChildren
        )
    }
    
    // MARK: - Video Playlist Content
    
    private func videoPlaylistContentMenu() -> CMEntity {
        var displayActionsMenuChildren: [CMElement?] = []
        let deleteMenu = CMEntity(displayInline: true, children: [deleteVideoPlaylist])
        
        if isVideoPlaylistContent {
            displayActionsMenuChildren.append(CMEntity(
                displayInline: true,
                children: [
                    isVideoPlaylistSharingFeatureFlagEnabled ? shareLink : nil,
                    rename,
                    isEmptyState ? nil : select,
                    addVideosToVideoPlaylistContent
                ].compactMap { $0 }
            ))
            displayActionsMenuChildren.append(isEmptyState ? nil : sortMenu())
            displayActionsMenuChildren.append(deleteMenu)
        }
        
        return CMEntity(
            displayInline: true,
            children: displayActionsMenuChildren.compactMap { $0 }
        )
    }

    // MARK: - Folder link actions
    private func folderLinkMenu() -> CMEntity {
        var folderLinkActions = [CMElement]()

        if isRestorable {
            folderLinkActions.append(restore)
        }

        folderLinkActions.append(
            makeFolderLinkQuickActions()
        )

        if showMediaDiscovery {
            folderLinkActions.append(mediaDiscovery)
        }

        folderLinkActions.append(
            contentsOf: [
                sortMenu(),
                viewTypeMenu()
            ]
        )

        return CMEntity(
            displayInline: true,
            children: folderLinkActions
        )
    }

    // MARK: - File link actions
    private func fileLinkMenu() -> CMEntity {
        var fileLinkActions = [CMActionEntity]()

        if isRestorable {
            fileLinkActions.append(restore)
        }

        fileLinkActions.append(contentsOf: [importFromFiles, download, shareLink, sendToChat])

        if isMediaFile {
            fileLinkActions.append(saveToPhotos)
        }

        return CMEntity(
            displayInline: true,
            children: fileLinkActions
        )
    }
    
    // used in the home search results screen
    private func homeMenu() -> CMEntity {
        CMEntity(
            children: [thumbnailView, listView]
        )
    }
}
