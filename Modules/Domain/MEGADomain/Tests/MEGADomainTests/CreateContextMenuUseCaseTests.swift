import MEGADomain
import MEGADomainMock
import XCTest

final class CreateContextMenuUseCaseTests: XCTestCase {
    let repo = MockCreateContextMenuRepository.newRepo
    var menuActionsArray = [CMElementTypeEntity]()
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        menuActionsArray.removeAll()
    }
    
    private func decomposeMenuIntoActions(menu: CMEntity) -> [CMElementTypeEntity] {
        return menu.children.compactMap {
            if let action = $0 as? CMActionEntity {
                return [action.type]
            } else if let menu = $0 as? CMEntity {
                return decomposeMenuIntoActions(menu: menu)
            }
            return nil
        }.reduce([], +)
    }
    
    private func contextMenuActionEntity(with config: CMConfigEntity?) throws -> CMEntity {
        let sut = CreateContextMenuUseCase(repo: repo)
        let configEntity = try XCTUnwrap(config)
        return try XCTUnwrap(sut.createContextMenu(config: configEntity))
    }
    
    func testCreateContextMenu_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        viewMode: .list,
                                                                        sortType: .defaultAsc,
                                                                        showMediaDiscovery: true))
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        menuActionsArray = [.display(actionType: .select),
                            .display(actionType: .mediaDiscovery),
                            .display(actionType: .thumbnailView),
                            .display(actionType: .listView),
                            .sort(actionType: .defaultAsc),
                            .sort(actionType: .defaultDesc),
                            .sort(actionType: .sizeDesc),
                            .sort(actionType: .sizeAsc),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc),
                            .sort(actionType: .labelAsc),
                            .sort(actionType: .favouriteAsc)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testMenuItemsForAlbumContentScreen_whenUserOpenAnAlbum_shouldReturnTheRightMenuItems() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album),
                                                                        sortType: .creationDesc,
                                                                        filterType: .allMedia,
                                                                        albumType: .user,
                                                                        isFilterEnabled: true,
                                                                        isEmptyState: false))
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        menuActionsArray = [.quickActions(actionType: .rename),
                            .album(actionType: .selectAlbumCover),
                            .display(actionType: .select),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc),
                            .filter(actionType: .allMedia),
                            .filter(actionType: .images),
                            .filter(actionType: .videos),
                            .album(actionType: .delete)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenuRubbishBin_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        isRubbishBinFolder: true,
                                                                        isRestorable: true))
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        menuActionsArray = [.display(actionType: .select),
                            .display(actionType: .thumbnailView),
                            .display(actionType: .listView),
                            .sort(actionType: .defaultAsc),
                            .sort(actionType: .defaultDesc),
                            .sort(actionType: .sizeDesc),
                            .sort(actionType: .sizeAsc),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc),
                            .sort(actionType: .labelAsc),
                            .sort(actionType: .favouriteAsc),
                            .display(actionType: .clearRubbishBin)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenuSharedItems_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        sortType: .defaultAsc,
                                                                        isSharedItems: true))
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        menuActionsArray = [.display(actionType: .select),
                            .sort(actionType: .defaultAsc),
                            .sort(actionType: .defaultDesc)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenuBackups_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        accessLevel: .owner,
                                                                        isAFolder: true,
                                                                        isBackupsRootNode: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        
        menuActionsArray = [.display(actionType: .select),
                            .display(actionType: .thumbnailView),
                            .display(actionType: .listView),
                            .sort(actionType: .defaultAsc),
                            .sort(actionType: .defaultDesc),
                            .sort(actionType: .sizeDesc),
                            .sort(actionType: .sizeAsc),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc),
                            .sort(actionType: .labelAsc),
                            .sort(actionType: .favouriteAsc)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenuBackupsChild_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        accessLevel: .owner,
                                                                        isAFolder: true,
                                                                        isBackupsChild: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        
        menuActionsArray = [.quickActions(actionType: .info),
                            .quickActions(actionType: .download),
                            .quickActions(actionType: .shareLink),
                            .quickActions(actionType: .shareFolder),
                            .quickActions(actionType: .copy),
                            .display(actionType: .select),
                            .display(actionType: .thumbnailView),
                            .display(actionType: .listView),
                            .sort(actionType: .defaultAsc),
                            .sort(actionType: .defaultDesc),
                            .sort(actionType: .sizeDesc),
                            .sort(actionType: .sizeAsc),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc),
                            .sort(actionType: .labelAsc),
                            .sort(actionType: .favouriteAsc)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_displayHidden_returnsCorrectMenuActions() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        accessLevel: .owner,
                                                                        isAFolder: true,
                                                                        isHidden: false))
        
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        
        menuActionsArray = [.quickActions(actionType: .info),
                            .quickActions(actionType: .download),
                            .quickActions(actionType: .shareLink),
                            .quickActions(actionType: .shareFolder),
                            .quickActions(actionType: .rename),
                            .quickActions(actionType: .hide),
                            .quickActions(actionType: .copy),
                            .display(actionType: .select),
                            .display(actionType: .thumbnailView),
                            .display(actionType: .listView),
                            .sort(actionType: .defaultAsc),
                            .sort(actionType: .defaultDesc),
                            .sort(actionType: .sizeDesc),
                            .sort(actionType: .sizeAsc),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc),
                            .sort(actionType: .labelAsc),
                            .sort(actionType: .favouriteAsc)
        ]
        
        XCTAssertEqual(menuActions, menuActionsArray)
    }
    
    func testCreateContextMenu_withAlbumConfigurationFilterEnabledAndNotInEmptyState_shouldShowCorrecMenuActions() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album),
                                                                        sortType: SortOrderEntity.modificationDesc,
                                                                        albumType: .gif,
                                                                        isFilterEnabled: true,
                                                                        isEmptyState: false))
        
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        
        menuActionsArray = [.display(actionType: .select),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc),
                            .filter(actionType: .allMedia),
                            .filter(actionType: .images),
                            .filter(actionType: .videos)
        ]
        
        XCTAssertEqual(menuActions, menuActionsArray)
    }
    
    func testCreateContextMenu_withAlbumConfigurationFilterDisabledAndInEmptyState_shouldShowCorrecMenuActions() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album),
                                                                        sortType: SortOrderEntity.modificationDesc,
                                                                        albumType: .favourite,
                                                                        isFilterEnabled: false,
                                                                        isEmptyState: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        
        menuActionsArray = [.display(actionType: .select)]
        
        XCTAssertEqual(menuActions, menuActionsArray)
    }
    
    func testCreateContextMenu_onAlbumContentPageFilterDisabledAndNotInEmptyState_shouldShowCorrecMenuActions() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album),
                                                                        sortType: SortOrderEntity.modificationDesc,
                                                                        albumType: .gif,
                                                                        isFilterEnabled: false,
                                                                        isEmptyState: false))

        let menuActions = decomposeMenuIntoActions(menu: cmEntity)

        menuActionsArray = [.display(actionType: .select),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc)
        ]

        XCTAssertEqual(menuActions, menuActionsArray)
    }
    
    func testCreateContextMenu_onCustomAlbumContentPageInEmptyState_shouldShowCorrecMenuActions() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album),
                                                                        sortType: SortOrderEntity.modificationDesc,
                                                                        albumType: .user,
                                                                        isFilterEnabled: true,
                                                                        isEmptyState: true))

        let menuActions = decomposeMenuIntoActions(menu: cmEntity)

        menuActionsArray = [.quickActions(actionType: .rename), .album(actionType: .delete)]

        XCTAssertEqual(menuActions, menuActionsArray)
    }
    
    func testCreateContextMenu_onAlbumsIsSelectHidden_shouldNotShowSelectActions() throws {
        try [AlbumEntityType.favourite, .user].forEach {
            let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album),
                                                                            albumType: $0,
                                                                            isSelectHidden: true))
            
            let menuActions = decomposeMenuIntoActions(menu: cmEntity)
            XCTAssertTrue(!menuActions.contains(.display(actionType: .select)))
        }
    }
    
    func testCreateContextMenu_UploadAdd() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .uploadAdd),
                                                                        showMediaDiscovery: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        menuActionsArray = [.uploadAdd(actionType: .chooseFromPhotos),
                            .uploadAdd(actionType: .capture),
                            .uploadAdd(actionType: .importFrom),
                            .uploadAdd(actionType: .scanDocument),
                            .uploadAdd(actionType: .newFolder),
                            .uploadAdd(actionType: .newTextFile)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_HomeDocumentsExplorer() throws {
        let cmUploadAddEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .uploadAdd),
                                                                        isDocumentExplorer: true))
        
        let menActions = decomposeMenuIntoActions(menu: cmUploadAddEntity)
        menuActionsArray = [.uploadAdd(actionType: .newTextFile),
                                  .uploadAdd(actionType: .scanDocument),
                                  .uploadAdd(actionType: .importFrom)]
        
        XCTAssertTrue(menActions == menuActionsArray)
        
        let cmDisplayEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                               viewMode: .list,
                                                                               sortType: .defaultAsc,
                                                                               isDocumentExplorer: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmDisplayEntity)
        menuActionsArray = [.display(actionType: .select),
                            .display(actionType: .thumbnailView),
                            .display(actionType: .listView),
                            .sort(actionType: .defaultAsc),
                            .sort(actionType: .defaultDesc),
                            .sort(actionType: .sizeDesc),
                            .sort(actionType: .sizeAsc),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc),
                            .sort(actionType: .labelAsc),
                            .sort(actionType: .favouriteAsc)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_HomeAudiosExplorer() throws {
        let cmDisplayEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                               viewMode: .list,
                                                                               sortType: .defaultAsc,
                                                                               isAudiosExplorer: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmDisplayEntity)
        menuActionsArray = [.display(actionType: .select),
                            .sort(actionType: .defaultAsc),
                            .sort(actionType: .defaultDesc),
                            .sort(actionType: .sizeDesc),
                            .sort(actionType: .sizeAsc),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc),
                            .sort(actionType: .labelAsc),
                            .sort(actionType: .favouriteAsc)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_HomeVideosExplorer() throws {
        let cmDisplayEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                               viewMode: .list,
                                                                               sortType: .defaultAsc,
                                                                               isVideosExplorer: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmDisplayEntity)
        menuActionsArray = [.sort(actionType: .defaultAsc),
                            .sort(actionType: .defaultDesc),
                            .sort(actionType: .sizeDesc),
                            .sort(actionType: .sizeAsc),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc),
                            .sort(actionType: .labelAsc),
                            .sort(actionType: .favouriteAsc)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_ChatListWithArchived() throws {
        let cmChatEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .chat),
                                                                            isDoNotDisturbEnabled: false,
                                                                            timeRemainingToDeactiveDND: nil,
                                                                            chatStatus: .online,
                                                                            isArchivedChatsVisible: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmChatEntity)
        menuActionsArray = [.chatStatus(actionType: .offline),
                            .chatStatus(actionType: .away),
                            .chatStatus(actionType: .online),
                            .chatStatus(actionType: .busy),
                            .chatDoNotDisturbDisabled(actionType: .off),
                            .chatDoNotDisturbEnabled(optionType: .thirtyMinutes),
                            .chatDoNotDisturbEnabled(optionType: .oneHour),
                            .chatDoNotDisturbEnabled(optionType: .sixHours),
                            .chatDoNotDisturbEnabled(optionType: .twentyFourHours),
                            .chatDoNotDisturbEnabled(optionType: .morningEightAM),
                            .chat(actionType: .archivedChats)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_ChatListWithOutArchived() throws {
        let cmChatEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .chat),
                                                                            isDoNotDisturbEnabled: false,
                                                                            timeRemainingToDeactiveDND: nil,
                                                                            chatStatus: .online,
                                                                           isArchivedChatsVisible: false))
        
        let menuActions = decomposeMenuIntoActions(menu: cmChatEntity)
        menuActionsArray = [.chatStatus(actionType: .offline),
                            .chatStatus(actionType: .away),
                            .chatStatus(actionType: .online),
                            .chatStatus(actionType: .busy),
                            .chatDoNotDisturbDisabled(actionType: .off),
                            .chatDoNotDisturbEnabled(optionType: .thirtyMinutes),
                            .chatDoNotDisturbEnabled(optionType: .oneHour),
                            .chatDoNotDisturbEnabled(optionType: .sixHours),
                            .chatDoNotDisturbEnabled(optionType: .twentyFourHours),
                            .chatDoNotDisturbEnabled(optionType: .morningEightAM)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_videosVideoPlaylists_shouldDeliverCorrectContextMenu() throws {
        let configEntity = CMConfigEntity(
            menuType: .menu(type: .homeVideoPlaylists),
            isVideosRevampExplorerVideoPlaylists: true
        )
        let contextMenuActionEntity = try contextMenuActionEntity(with: configEntity)
        
        let menuActions = decomposeMenuIntoActions(menu: contextMenuActionEntity)
        
        XCTAssertEqual(menuActions, [
            .display(actionType: .newPlaylist),
            .sort(actionType: .modificationDesc),
            .sort(actionType: .modificationAsc)
        ])
    }
    
    func testCreateContextMenu_videoPlaylistContent_shouldDeliverCorrectContextMenu() throws {
        let configEntity = CMConfigEntity(
            menuType: .menu(type: .videoPlaylistContent),
            isVideoPlaylistContent: true,
            isEmptyState: false
        )
        let contextMenuActionEntity = try contextMenuActionEntity(with: configEntity)
        
        let menuActions = decomposeMenuIntoActions(menu: contextMenuActionEntity)
        
        XCTAssertEqual(menuActions, [
            .quickActions(actionType: .rename),
            .display(actionType: .select),
            .videoPlaylist(actionType: .addVideosToVideoPlaylistContent),
            .sort(actionType: .defaultAsc),
            .sort(actionType: .defaultDesc),
            .sort(actionType: .modificationDesc),
            .sort(actionType: .modificationAsc),
            .videoPlaylist(actionType: .delete)
        ])
    }
    
    func testCreateContextMenu_videoPlaylistContentEmpty_shouldDeliverCorrectContextMenu() throws {
        let configEntity = CMConfigEntity(
            menuType: .menu(type: .videoPlaylistContent),
            isVideoPlaylistContent: true,
            isEmptyState: true
        )
        let contextMenuActionEntity = try contextMenuActionEntity(with: configEntity)
        
        let menuActions = decomposeMenuIntoActions(menu: contextMenuActionEntity)
        
        XCTAssertEqual(menuActions, [
            .quickActions(actionType: .rename),
            .videoPlaylist(actionType: .addVideosToVideoPlaylistContent),
            .videoPlaylist(actionType: .delete)
        ])
    }
    
    func testCreateContextMenu_Meeting() throws {
        let cmMeetingEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .meeting)))
        
        let menuActions = decomposeMenuIntoActions(menu: cmMeetingEntity)
        menuActionsArray = [.meeting(actionType: .startMeeting),
                            .meeting(actionType: .joinMeeting),
                            .meeting(actionType: .scheduleMeeting)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_MyQR() throws {
        let cmMeetingEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .qr),
                                                                               isShareAvailable: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmMeetingEntity)
        menuActionsArray = [.qr(actionType: .share),
                            .qr(actionType: .qrSettings),
                            .qr(actionType: .resetQR)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_RubbishBinChild() throws {
        let cmRubbishBinChildEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .rubbishBin),
                                                                                       viewMode: .list,
                                                                                       sortType: .defaultAsc,
                                                                                       isRubbishBinFolder: true,
                                                                                       isRestorable: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmRubbishBinChildEntity)
        menuActionsArray = [.display(actionType: .select),
                            .display(actionType: .thumbnailView),
                            .display(actionType: .listView),
                            .sort(actionType: .defaultAsc),
                            .sort(actionType: .defaultDesc),
                            .sort(actionType: .sizeDesc),
                            .sort(actionType: .sizeAsc),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc),
                            .sort(actionType: .labelAsc),
                            .sort(actionType: .favouriteAsc),
                            .rubbishBin(actionType: .restore),
                            .rubbishBin(actionType: .info),
                            .rubbishBin(actionType: .remove)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_whenUsedOnAlbum_shouldReturnRightAlbumMenu() throws {
        let cmEntity1 = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album)))
        let menuActions1 = decomposeMenuIntoActions(menu: cmEntity1)
        XCTAssertEqual(menuActions1, [])
        
        let cmEntity2 = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album), albumType: .user, isEmptyState: true))
        let menuActions2 = decomposeMenuIntoActions(menu: cmEntity2)
        XCTAssertEqual(menuActions2, [.quickActions(actionType: .rename), .album(actionType: .delete)])
        
        let cmEntity3 = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album), albumType: .user))
        let menuActions3 = decomposeMenuIntoActions(menu: cmEntity3)
        XCTAssertEqual(menuActions3, [.quickActions(actionType: .rename),
                                      .album(actionType: .selectAlbumCover),
                                      .display(actionType: .select),
                                      .sort(actionType: .modificationDesc),
                                      .sort(actionType: .modificationAsc),
                                      .album(actionType: .delete)])

        let cmEntity4 = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album), albumType: .favourite, isEmptyState: true))
        let menuActions4 = decomposeMenuIntoActions(menu: cmEntity4)
        XCTAssertEqual(menuActions4, [
                                      .display(actionType: .select)])
        
        let cmEntity5 = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album), albumType: .gif, isFilterEnabled: true))
        let menuActions5 = decomposeMenuIntoActions(menu: cmEntity5)
        XCTAssertEqual(menuActions5, [.display(actionType: .select),
                                      .sort(actionType: .modificationDesc),
                                      .sort(actionType: .modificationAsc),
                                      .filter(actionType: .allMedia),
                                      .filter(actionType: .images),
                                      .filter(actionType: .videos)])
        
        let cmEntity6 = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .album), albumType: .favourite, isFilterEnabled: true))
        let menuActions6 = decomposeMenuIntoActions(menu: cmEntity6)
        XCTAssertEqual(menuActions6, [.display(actionType: .select),
                                      .sort(actionType: .modificationDesc),
                                      .sort(actionType: .modificationAsc),
                                      .filter(actionType: .allMedia),
                                      .filter(actionType: .images),
                                      .filter(actionType: .videos)])
    }
    func testCreateContextMenu_whenUsedOnTimelineAndIsCameraUploadsEnabledIsSet_shouldReturnRightAlbumMenu() throws {
        
        for isCameraUploadsEnabled in [true, false] {
            let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(
                menuType: .menu(type: .timeline),
                isCameraUploadExplorer: true,
                isCameraUploadsEnabled: isCameraUploadsEnabled
            ))
            let menuActions = decomposeMenuIntoActions(menu: cmEntity)
            XCTAssertEqual(menuActions, [
                .display(actionType: .select),
                .sort(actionType: .modificationDesc),
                .sort(actionType: .modificationAsc),
                isCameraUploadsEnabled ? .quickActions(actionType: .settings) : nil
            ].compactMap { $0 })
        }
    }
}
