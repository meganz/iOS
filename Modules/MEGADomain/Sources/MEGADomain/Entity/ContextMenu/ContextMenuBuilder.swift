public final class ContextMenuBuilder {
    private var menuType: CMElementTypeEntity = .unknown
    private var accessLevel: ShareAccessLevelEntity = .unknown
    private var viewMode: ViewModePreferenceEntity = .list
    private var sortType: SortOrderEntity = .defaultAsc
    private var isAFolder: Bool = false
    private var isRubbishBinFolder: Bool = false
    private var isOfflineFolder: Bool = false
    private var isViewInFolder = false
    private var isRestorable: Bool = false
    private var isInVersionsView: Bool = false
    private var isSharedItems: Bool = false
    private var isIncomingShareChild: Bool = false
    private var isHome: Bool = false
    private var isFavouritesExplorer: Bool = false
    private var isDocumentExplorer: Bool = false
    private var isAudiosExplorer: Bool = false
    private var isVideosExplorer: Bool = false
    private var isCameraUploadExplorer: Bool = false
    private var isFilterEnabled: Bool = false
    private var isDoNotDisturbEnabled: Bool = false
    private var isShareAvailable: Bool = false
    private var isMyBackupsNode: Bool = false
    private var isMyBackupsChild: Bool = false
    private var isSharedItemsChild: Bool = false
    private var isOutShare: Bool = false
    private var isExported: Bool = false
    private var isEmptyState: Bool = false
    private var timeRemainingToDeactiveDND: String? = nil
    private var versionsCount: Int = 0
    private var showMediaDiscovery: Bool = false
    private var chatStatus: ChatStatusEntity = .invalid
    private var shouldStartMeeting = false
    private var shouldJoinMeeting = false
    private var shouldScheduleMeeting = false
    
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
    
    public func setIsCameraUploadExplorer(_ isCameraUploadExplorer: Bool) -> ContextMenuBuilder {
        self.isCameraUploadExplorer = isCameraUploadExplorer
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
    
    public func setIsMyBackupsNode(_ isMyBackupsNode: Bool) -> ContextMenuBuilder {
        self.isMyBackupsNode = isMyBackupsNode
        return self
    }
    
    public func setIsMyBackupsChild(_ isMyBackupsChild: Bool) -> ContextMenuBuilder {
        self.isMyBackupsChild = isMyBackupsChild
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
    
    public func setShouldStartMeeting(_ shouldStartMeeting: Bool) -> ContextMenuBuilder {
        self.shouldStartMeeting = shouldStartMeeting
        return self
    }
    
    public func setShouldJoinMeeting(_ shouldJoinMeeting: Bool) -> ContextMenuBuilder {
        self.shouldJoinMeeting = shouldJoinMeeting
        return self
    }
    
    public func setShouldScheduleMeeting(_ shouldScheduleMeeting: Bool) -> ContextMenuBuilder {
        self.shouldScheduleMeeting = shouldScheduleMeeting
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
    
    func currentChatStatus() -> ChatStatusEntity {
        chatStatus
    }
    
    func currentTimeRemainingToDeactiveDND() -> String? {
        timeRemainingToDeactiveDND
    }

    //MARK: - Upload Add Context Actions grouping functions
    private func uploadAddMenu() -> CMEntity {
        var uploadAddActions: [CMElement] = []
        
        if isHome {
            uploadAddActions.append(contentsOf: [choosePhotoVideo, newTextFile, scanDocument, capturePhotoVideo, importFromFiles])
        } else if isDocumentExplorer {
            uploadAddActions.append(contentsOf: [newTextFile, scanDocument, importFromFiles])
        } else {
            uploadAddActions.append(contentsOf: [choosePhotoVideo, capturePhotoVideo, importFromFiles, scanDocument, newFolder, newTextFile])
        }
        
        return CMEntity(displayInline: true,
                        children: uploadAddActions)
    }
    
    //MARK: - Display Context Actions grouping functions
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
        
        if showMediaDiscovery && !isRubbishBinFolder && !isMyBackupsChild {
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
    
    private func sortMenu() -> CMElement {
        if isEmptyState {
            return CMActionEntity(type: .display(actionType: .sort),
                                  isEnabled: false)
        } else {
            var sortMenuActions = [sortNameAscending, sortNameDescending]
                    
            if isCameraUploadExplorer {
                sortMenuActions = [sortNewest, sortOldest]
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
        CMEntity(displayInline: true,
                 children: [filter]
        )
    }
    
    private func displayMenu() -> CMEntity {
        var displayActionsMenuChildren: [CMElement] = []
        
        if isAFolder && !isRubbishBinFolder && !isMyBackupsNode {
            displayActionsMenuChildren.append(makeQuickActions())
        }
        
        if isSharedItems || isAudiosExplorer {
            displayActionsMenuChildren.append(contentsOf: [selectMenu(), sortMenu()])
        } else if isVideosExplorer {
            displayActionsMenuChildren.append(contentsOf: [sortMenu()])
        } else if isCameraUploadExplorer {
            displayActionsMenuChildren = [selectMenu(), sortMenu()]
            if isFilterEnabled {
                displayActionsMenuChildren.append(filterMenu())
            }
        } else {
            let menu = isViewInFolder ? [viewTypeMenu(), sortMenu()] : [selectMenu(), viewTypeMenu(), sortMenu()]
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
            if !isMyBackupsChild {
                quickActions.append(rename)
            }
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
    
    //MARK: - Rubbish Bin Children Context Actions grouping functions
    private func rubbishBinChildFolderMenu() -> CMEntity {
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
        
        return CMEntity(children: rubbishBinActions)
    }
    
    //MARK: - Chat Context Actions
    private func chatMenu() -> CMEntity {
        CMEntity(displayInline: true,
                 children: [chatStatusMenu(), doNotDisturbMenu()])
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
    
    //MARK: - Meeting Context Actions
    private func meetingMenu() -> CMEntity {
        CMEntity(
            displayInline: true,
            children: shouldScheduleMeeting ? [startMeeting, joinMeeting, scheduleMeeting] : [startMeeting, joinMeeting]
        )
    }
    
    //MARK: - My QR Code Actions
    private func myQRCodeMenu() -> CMEntity {
        var myQRCodeActions = [CMActionEntity]()
        
        if isShareAvailable {
            myQRCodeActions.append(share)
        }
        
        myQRCodeActions.append(contentsOf: [settings, resetQR])
        
        return CMEntity(displayInline: true,
                        children: myQRCodeActions)
    }
}
