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
        menuActionsArray = [CMElementTypeEntity.display(actionType: .select),
                                  CMElementTypeEntity.display(actionType: .mediaDiscovery),
                                  CMElementTypeEntity.display(actionType: .thumbnailView),
                                  CMElementTypeEntity.display(actionType: .listView),
                                  CMElementTypeEntity.sort(actionType: .defaultAsc),
                                  CMElementTypeEntity.sort(actionType: .defaultDesc),
                                  CMElementTypeEntity.sort(actionType: .sizeDesc),
                                  CMElementTypeEntity.sort(actionType: .sizeAsc),
                                  CMElementTypeEntity.sort(actionType: .modificationDesc),
                                  CMElementTypeEntity.sort(actionType: .modificationAsc),
                                  CMElementTypeEntity.sort(actionType: .labelAsc),
                                  CMElementTypeEntity.sort(actionType: .favouriteAsc)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenuRubbishBin_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        isRubbishBinFolder: true,
                                                                        isRestorable: true))
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        menuActionsArray = [CMElementTypeEntity.display(actionType: .select),
                                  CMElementTypeEntity.display(actionType: .thumbnailView),
                                  CMElementTypeEntity.display(actionType: .listView),
                                  CMElementTypeEntity.sort(actionType: .defaultAsc),
                                  CMElementTypeEntity.sort(actionType: .defaultDesc),
                                  CMElementTypeEntity.sort(actionType: .sizeDesc),
                                  CMElementTypeEntity.sort(actionType: .sizeAsc),
                                  CMElementTypeEntity.sort(actionType: .modificationDesc),
                                  CMElementTypeEntity.sort(actionType: .modificationAsc),
                                  CMElementTypeEntity.sort(actionType: .labelAsc),
                                  CMElementTypeEntity.sort(actionType: .favouriteAsc),
                                  CMElementTypeEntity.display(actionType: .clearRubbishBin)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenuSharedItems_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        sortType: .defaultAsc,
                                                                        isSharedItems: true))
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        menuActionsArray = [CMElementTypeEntity.display(actionType: .select),
                                  CMElementTypeEntity.sort(actionType: .defaultAsc),
                                  CMElementTypeEntity.sort(actionType: .defaultDesc)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenuBackups_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        accessLevel: .owner,
                                                                        isAFolder: true,
                                                                        isMyBackupsNode: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        
        menuActionsArray = [CMElementTypeEntity.display(actionType: .select),
                            CMElementTypeEntity.display(actionType: .thumbnailView),
                            CMElementTypeEntity.display(actionType: .listView),
                            CMElementTypeEntity.sort(actionType: .defaultAsc),
                            CMElementTypeEntity.sort(actionType: .defaultDesc),
                            CMElementTypeEntity.sort(actionType: .sizeDesc),
                            CMElementTypeEntity.sort(actionType: .sizeAsc),
                            CMElementTypeEntity.sort(actionType: .modificationDesc),
                            CMElementTypeEntity.sort(actionType: .modificationAsc),
                            CMElementTypeEntity.sort(actionType: .labelAsc),
                            CMElementTypeEntity.sort(actionType: .favouriteAsc)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenuMyBackupsChild_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                        accessLevel: .owner,
                                                                        isAFolder: true,
                                                                        isMyBackupsChild: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        
        menuActionsArray = [CMElementTypeEntity.quickActions(actionType: .info),
                            CMElementTypeEntity.quickActions(actionType: .download),
                            CMElementTypeEntity.quickActions(actionType: .shareLink),
                            CMElementTypeEntity.quickActions(actionType: .shareFolder),
                            CMElementTypeEntity.quickActions(actionType: .copy),
                            CMElementTypeEntity.display(actionType: .select),
                            CMElementTypeEntity.display(actionType: .thumbnailView),
                            CMElementTypeEntity.display(actionType: .listView),
                            CMElementTypeEntity.sort(actionType: .defaultAsc),
                            CMElementTypeEntity.sort(actionType: .defaultDesc),
                            CMElementTypeEntity.sort(actionType: .sizeDesc),
                            CMElementTypeEntity.sort(actionType: .sizeAsc),
                            CMElementTypeEntity.sort(actionType: .modificationDesc),
                            CMElementTypeEntity.sort(actionType: .modificationAsc),
                            CMElementTypeEntity.sort(actionType: .labelAsc),
                            CMElementTypeEntity.sort(actionType: .favouriteAsc)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_UploadAdd() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .uploadAdd),
                                                                        showMediaDiscovery: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmEntity)
        menuActionsArray = [CMElementTypeEntity.uploadAdd(actionType: .chooseFromPhotos),
                                  CMElementTypeEntity.uploadAdd(actionType: .capture),
                                  CMElementTypeEntity.uploadAdd(actionType: .importFrom),
                                  CMElementTypeEntity.uploadAdd(actionType: .scanDocument),
                                  CMElementTypeEntity.uploadAdd(actionType: .newFolder),
                                  CMElementTypeEntity.uploadAdd(actionType: .newTextFile)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_HomeDocumentsExplorer() throws {
        let cmUploadAddEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .uploadAdd),
                                                                        isDocumentExplorer: true))
        
        let menActions = decomposeMenuIntoActions(menu: cmUploadAddEntity)
        menuActionsArray = [CMElementTypeEntity.uploadAdd(actionType: .newTextFile),
                                  CMElementTypeEntity.uploadAdd(actionType: .scanDocument),
                                  CMElementTypeEntity.uploadAdd(actionType: .importFrom)]
        
        XCTAssertTrue(menActions == menuActionsArray)
        
        let cmDisplayEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                               viewMode: .list,
                                                                               sortType: .defaultAsc,
                                                                               isDocumentExplorer: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmDisplayEntity)
        menuActionsArray = [CMElementTypeEntity.display(actionType: .select),
                                  CMElementTypeEntity.display(actionType: .thumbnailView),
                                  CMElementTypeEntity.display(actionType: .listView),
                                  CMElementTypeEntity.sort(actionType: .defaultAsc),
                                  CMElementTypeEntity.sort(actionType: .defaultDesc),
                                  CMElementTypeEntity.sort(actionType: .sizeDesc),
                                  CMElementTypeEntity.sort(actionType: .sizeAsc),
                                  CMElementTypeEntity.sort(actionType: .modificationDesc),
                                  CMElementTypeEntity.sort(actionType: .modificationAsc),
                                  CMElementTypeEntity.sort(actionType: .labelAsc),
                                  CMElementTypeEntity.sort(actionType: .favouriteAsc)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_HomeAudiosExplorer() throws {
        let cmDisplayEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                               viewMode: .list,
                                                                               sortType: .defaultAsc,
                                                                               isAudiosExplorer: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmDisplayEntity)
        menuActionsArray = [CMElementTypeEntity.display(actionType: .select),
                                  CMElementTypeEntity.sort(actionType: .defaultAsc),
                                  CMElementTypeEntity.sort(actionType: .defaultDesc),
                                  CMElementTypeEntity.sort(actionType: .sizeDesc),
                                  CMElementTypeEntity.sort(actionType: .sizeAsc),
                                  CMElementTypeEntity.sort(actionType: .modificationDesc),
                                  CMElementTypeEntity.sort(actionType: .modificationAsc),
                                  CMElementTypeEntity.sort(actionType: .labelAsc),
                                  CMElementTypeEntity.sort(actionType: .favouriteAsc)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_HomeVideosExplorer() throws {
        let cmDisplayEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .display),
                                                                               viewMode: .list,
                                                                               sortType: .defaultAsc,
                                                                               isVideosExplorer: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmDisplayEntity)
        menuActionsArray = [CMElementTypeEntity.sort(actionType: .defaultAsc),
                                  CMElementTypeEntity.sort(actionType: .defaultDesc),
                                  CMElementTypeEntity.sort(actionType: .sizeDesc),
                                  CMElementTypeEntity.sort(actionType: .sizeAsc),
                                  CMElementTypeEntity.sort(actionType: .modificationDesc),
                                  CMElementTypeEntity.sort(actionType: .modificationAsc),
                                  CMElementTypeEntity.sort(actionType: .labelAsc),
                                  CMElementTypeEntity.sort(actionType: .favouriteAsc)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_ChatList() throws {
        let cmChatEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .chat),
                                                                            isDoNotDisturbEnabled: false,
                                                                            timeRemainingToDeactiveDND: nil,
                                                                            chatStatus: .online))
        
        let menuActions = decomposeMenuIntoActions(menu: cmChatEntity)
        menuActionsArray = [CMElementTypeEntity.chatStatus(actionType: .offline),
                            CMElementTypeEntity.chatStatus(actionType: .away),
                            CMElementTypeEntity.chatStatus(actionType: .online),
                            CMElementTypeEntity.chatStatus(actionType: .busy),
                            CMElementTypeEntity.chatDoNotDisturbDisabled(actionType: .off),
                            CMElementTypeEntity.chatDoNotDisturbEnabled(optionType: .thirtyMinutes),
                            CMElementTypeEntity.chatDoNotDisturbEnabled(optionType: .oneHour),
                            CMElementTypeEntity.chatDoNotDisturbEnabled(optionType: .sixHours),
                            CMElementTypeEntity.chatDoNotDisturbEnabled(optionType: .twentyFourHours),
                            CMElementTypeEntity.chatDoNotDisturbEnabled(optionType: .morningEightAM)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_Meeting() throws {
        let cmMettingEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .meeting)))
        
        let menuActions = decomposeMenuIntoActions(menu: cmMettingEntity)
        menuActionsArray = [CMElementTypeEntity.meeting(actionType: .startMeeting),
                            CMElementTypeEntity.meeting(actionType: .joinMeeting)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
    
    func testCreateContextMenu_MyQR() throws {
        let cmMettingEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .menu(type: .qr),
                                                                               isShareAvailable: true))
        
        let menuActions = decomposeMenuIntoActions(menu: cmMettingEntity)
        menuActionsArray = [CMElementTypeEntity.qr(actionType: .share),
                            CMElementTypeEntity.qr(actionType: .settings),
                            CMElementTypeEntity.qr(actionType: .resetQR)]
        
        XCTAssertTrue(menuActions == menuActionsArray)
    }
}
