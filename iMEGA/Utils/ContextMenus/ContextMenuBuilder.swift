
final class ContextMenuBuilder {
    private var menuType: ContextMenuType = .unknown
    private var displayMode: DisplayMode = .unknown
    private var accessLevel: MEGAShareType = .accessUnknown
    private var viewMode: ViewModePreference = .list
    private var sortType: SortOrderType = .nameAscending
    private var isAFolder: Bool = false
    private var isRubbishBinFolder: Bool = false
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
    private var isDoNotDisturbEnabled: Bool = false
    private var isShareAvailable: Bool = false
    private var isSharedItemsChild: Bool = false
    private var isOutShare: Bool = false
    private var isExported: Bool = false
    private var timeRemainingToDeactiveDND: String? = nil
    private var versionsCount: Int = 0
    private var showMediaDiscovery: Bool = false
    private var chatStatus: ChatStatus = .invalid
    
    func setType(_ menuType: ContextMenuType?) -> ContextMenuBuilder {
        self.menuType = menuType ?? .unknown
        return self
    }
    
    func setDisplayMode(_ displayMode: DisplayMode) -> ContextMenuBuilder {
        self.displayMode = displayMode
        return self
    }
    
    func setAccessLevel(_ accessLevel: MEGAShareType?) -> ContextMenuBuilder {
        self.accessLevel = accessLevel ?? .accessUnknown
        return self
    }
    
    func setViewMode(_ viewMode: ViewModePreference?) -> ContextMenuBuilder {
        self.viewMode = viewMode ?? .list
        return self
    }
    
    func setSortType(_ sortType: SortOrderType?) -> ContextMenuBuilder {
        self.sortType = sortType ?? .nameAscending
        return self
    }
    
    func setIsAFolder(_ isAFolder: Bool) -> ContextMenuBuilder {
        self.isAFolder = isAFolder
        return self
    }
    
    func setIsRubbishBinFolder(_ isRubbishBinFolder: Bool) -> ContextMenuBuilder {
        self.isRubbishBinFolder = isRubbishBinFolder
        return self
    }
    
    func setIsRestorable(_ isRestorable: Bool) -> ContextMenuBuilder {
        self.isRestorable = isRestorable
        return self
    }
    
    func setIsInVersionsView(_ isInVersionsView: Bool) -> ContextMenuBuilder {
        self.isInVersionsView = isInVersionsView
        return self
    }
    
    func setIsSharedItems(_ isSharedItems: Bool) -> ContextMenuBuilder {
        self.isSharedItems = isSharedItems
        return self
    }
    
    func setIsIncomingShareChild(_ isIncomingShareChild: Bool) -> ContextMenuBuilder {
        self.isIncomingShareChild = isIncomingShareChild
        return self
    }
    
    func setIsHome(_ isHome: Bool) -> ContextMenuBuilder {
        self.isHome = isHome
        return self
    }
    
    func setIsFavouritesExplorer(_ isFavouritesExplorer: Bool) -> ContextMenuBuilder {
        self.isFavouritesExplorer = isFavouritesExplorer
        return self
    }
    
    func setIsDocumentExplorer(_ isDocumentExplorer: Bool) -> ContextMenuBuilder {
        self.isDocumentExplorer = isDocumentExplorer
        return self
    }
    
    func setIsAudiosExplorer(_ isAudiosExplorer: Bool) -> ContextMenuBuilder {
        self.isAudiosExplorer = isAudiosExplorer
        return self
    }
    
    func setIsVideosExplorer(_ isVideosExplorer: Bool) -> ContextMenuBuilder {
        self.isVideosExplorer = isVideosExplorer
        return self
    }
    
    func setIsCameraUploadExplorer(_ isCameraUploadExplorer: Bool) -> ContextMenuBuilder {
        self.isCameraUploadExplorer = isCameraUploadExplorer
        return self
    }
    
    func setIsDoNotDisturbEnabled(_ isDoNotDisturbEnabled: Bool) -> ContextMenuBuilder {
        self.isDoNotDisturbEnabled = isDoNotDisturbEnabled
        return self
    }
    
    func setIsShareAvailable(_ isShareAvailable: Bool) -> ContextMenuBuilder {
        self.isShareAvailable = isShareAvailable
        return self
    }
    
    func setIsSharedItemsChild(_ isSharedItemsChild: Bool) -> ContextMenuBuilder {
        self.isSharedItemsChild = isSharedItemsChild
        return self
    }
    
    func setIsOutShare(_ isOutShare: Bool) -> ContextMenuBuilder {
        self.isOutShare = isOutShare
        return self
    }
    
    func setIsExported(_ isExported: Bool) -> ContextMenuBuilder {
        self.isExported = isExported
        return self
    }
    
    func setTimeRemainingToDeactiveDND(_ timeRemainingToDeactiveDND: String?) -> ContextMenuBuilder {
        self.timeRemainingToDeactiveDND = timeRemainingToDeactiveDND
        return self
    }
    
    func setVersionsCount(_ versionsCount: Int) -> ContextMenuBuilder {
        self.versionsCount = versionsCount
        return self
    }
    
    func setShowMediaDiscovery(_ showMediaDiscovery: Bool) -> ContextMenuBuilder {
        self.showMediaDiscovery = showMediaDiscovery
        return self
    }
    
    func setChatStatus(_ chatStatus: ChatStatus) -> ContextMenuBuilder {
        self.chatStatus = chatStatus
        return self
    }
    
    func build() -> CMEntity? {
        switch menuType {
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
        default:
            return nil
        }
    }
    
    func currentViewMode() -> ViewModePreference {
        viewMode
    }
    
    func currentSortType() -> SortOrderType {
        sortType
    }
    
    func currentVersionsCount() -> Int {
        versionsCount
    }
    
    func currentChatStatus() -> ChatStatus {
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
        CMEntity(displayInline: true,
                 children: [select]
        )
    }
    
    private func viewTypeMenu() -> CMEntity {
        if #available(iOS 14.0, *) {
            return CMEntity(displayInline: true,
                     children: [thumbnailView, listView]
            )
        } else {
            return CMEntity(children: [viewMode == .thumbnail ? listView : thumbnailView])
        }
    }
    
    private func rubbishBinMenu() -> CMEntity {
        CMEntity(displayInline: true,
                 children: [emptyRubbishBin]
        )
    }
    
    private func sortMenu() -> CMEntity {
        var sortMenuActions = [sortNameAscending, sortNameDescending]
        
        if isCameraUploadExplorer {
            sortMenuActions = [sortNewest, sortOldest]
        }
        else if !isSharedItems {
            var list = [sortLargest, sortSmallest, sortNewest, sortOldest, sortLabel]
            if !isFavouritesExplorer {
                list.append(sortFavourite)
            }
            sortMenuActions.append(contentsOf: list)
        }
        
        return CMEntity(title: Strings.Localizable.sortTitle,
                        detail: sortType.localizedString,
                        image: Asset.Images.ActionSheetIcons.sort.image,
                        identifier: DisplayAction.sort.rawValue,
                        children: sortMenuActions)
    }
    
    private func displayMenu() -> CMEntity {
        var displayActionsMenuChildren: [CMElement] = []
        
        if isAFolder && !isRubbishBinFolder {
            displayActionsMenuChildren.append(quickFolderActions())
        }
        
        if isSharedItems || isAudiosExplorer {
            displayActionsMenuChildren.append(contentsOf: [selectMenu(), sortMenu()])
        } else if isVideosExplorer {
            displayActionsMenuChildren.append(contentsOf: [sortMenu()])
        } else {
            displayActionsMenuChildren.append(contentsOf: [selectMenu(), viewTypeMenu(), sortMenu()])
        }
        
        if isRubbishBinFolder {
            displayActionsMenuChildren.append(rubbishBinMenu())
        }
                
        if showMediaDiscovery && !isRubbishBinFolder {
            displayActionsMenuChildren.append(mediaDiscovery)
        }
        
        return CMEntity(displayInline: true,
                        children: displayActionsMenuChildren)
    }
    
    private func quickFolderActions() -> CMEntity {
        var quickActions: [CMElement] = [info, download]
        
        if accessLevel == .accessOwner {
            quickActions.append(contentsOf: isExported ? [manageLink, removeLink] : [shareLink])
            quickActions.append(contentsOf: isOutShare ? [manageFolder] : [shareFolder, rename])
        }
        
        quickActions.append(copy)
        
        if isIncomingShareChild {
            quickActions.append(leaveSharing)
        }
        
        if isOutShare {
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
        
        rubbishBinActions.append(info)
        
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
        CMEntity(title: Strings.Localizable.status,
                 detail: currentChatStatus().localizedIdentifier,
                 identifier: ChatAction.status.rawValue,
                 children: ChatStatus
                                    .allCases
                                    .filter { $0 != .invalid }
                                    .compactMap(chatStatus))
    }
    
    private func doNotDisturbMenu() -> CMEntity {
        var doNotDisturbElements = [CMElement]()
        if #available(iOS 14.0, *) {
            doNotDisturbElements.append(CMEntity(displayInline: true,
                                                 children: [CMActionEntity(title: Strings.Localizable.off,
                                                                           identifier: DNDDisabledAction.off.rawValue,
                                                                           state: isDoNotDisturbEnabled ? .off : .on)]))
        
        }
            
        if !isDoNotDisturbEnabled {
            doNotDisturbElements.append(CMEntity(displayInline: true,
                                                 children: DNDTurnOnOption
                                                                        .allCases
                                                                        .filter { $0 != .forever }
                                                                        .compactMap(doNotDisturb)))
        }
                        
        return CMEntity(title: Strings.Localizable.doNotDisturb,
                        detail: isDoNotDisturbEnabled ? currentTimeRemainingToDeactiveDND() : nil,
                        identifier: ChatAction.doNotDisturb.rawValue,
                        children: doNotDisturbElements)
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
