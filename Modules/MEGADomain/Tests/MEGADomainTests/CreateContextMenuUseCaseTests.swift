import XCTest
import MEGADomain
import MEGADomainMock

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
                                                                        isMyBackupsNode: true))
        
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
    
    func testCreateContextMenuMyBackupsChild_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        accessLevel: .owner,
                                                                        isAFolder: true,
                                                                        isMyBackupsChild: true))
        
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
    
    func testCreateContextMenu_withAlbumConfigurationFilterEnabledAndNotInEmptyState_shouldShowCorrecMenuActions() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        sortType: SortOrderEntity.modificationDesc,
                                                                        isAlbum: true,
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
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        sortType: SortOrderEntity.modificationDesc,
                                                                        isAlbum: true,
                                                                        isFilterEnabled: false,
                                                                        isEmptyState: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        
        menuActionsArray = [.display(actionType: .select)]
        
        XCTAssertEqual(menuActions, menuActionsArray)
    }
    
    func testCreateContextMenu_onAlbumContentPageFilterDisabledAndNotInEmptyState_shouldShowCorrecMenuActions() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        sortType: SortOrderEntity.modificationDesc,
                                                                        isAlbum: true,
                                                                        isFilterEnabled: false,
                                                                        isEmptyState: false))

        let menuActions = decomposeMenuIntoActions(menu: cmEntity)

        menuActionsArray = [.display(actionType: .select),
                            .sort(actionType: .modificationDesc),
                            .sort(actionType: .modificationAsc)
        ]

        XCTAssertEqual(menuActions, menuActionsArray)
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
    
    func testCreateContextMenu_ChatList() throws {
        let cmChatEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .chat),
                                                                            isDoNotDisturbEnabled: false,
                                                                            timeRemainingToDeactiveDND: nil,
                                                                            chatStatus: .online))
        
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
    
    func testCreateContextMenu_Meeting() throws {
        let cmMettingEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .meeting)))
        
        let menuActions = decomposeMenuIntoActions(menu: cmMettingEntity)
        menuActionsArray = [.meeting(actionType: .startMeeting),
                            .meeting(actionType: .joinMeeting)
        ]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_MyQR() throws {
        let cmMettingEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .qr),
                                                                               isShareAvailable: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmMettingEntity)
        menuActionsArray = [.qr(actionType: .share),
                            .qr(actionType: .settings),
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
}
