import XCTest
@testable import MEGA

final class CreateContextMenuUseCaseTests: XCTestCase {
    let repo = CreateContextMenuRepository()
    var actionIdentifiersArray = [String]()
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        actionIdentifiersArray.removeAll()
    }
    
    private func convertMenuToActionIdentifiers(menu: CMEntity) -> [String] {
        return menu.children.compactMap {
            if let action = $0 as? CMActionEntity {
                return action.identifier != nil ? [action.identifier ?? ""] : nil
            } else if let menu = $0 as? CMEntity {
                if menu.title != nil && menu.image != nil {
                    return menu.identifier != nil ? [menu.identifier ?? ""] : nil
                } else {
                    return convertMenuToActionIdentifiers(menu: menu)
                }
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
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .display,
                                                                        viewMode: .list,
                                                                        sortType: .nameAscending,
                                                                        showMediaDiscovery: true))
        let actionIdentifiers = convertMenuToActionIdentifiers(menu: cmEntity)
        actionIdentifiersArray = [DisplayAction.select.rawValue,
                                  DisplayAction.thumbnailView.rawValue,
                                  DisplayAction.listView.rawValue,
                                  DisplayAction.sort.rawValue,
                                  DisplayAction.mediaDiscovery.rawValue]
        
        XCTAssertTrue(Set(actionIdentifiers) == Set(actionIdentifiersArray))
    }
    
    func testCreateContextMenuRubbishBin_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .display,
                                                                        isRubbishBinFolder: true,
                                                                        isRestorable: true))
        let actionIdentifiers = convertMenuToActionIdentifiers(menu: cmEntity)
        actionIdentifiersArray = [DisplayAction.select.rawValue,
                                  DisplayAction.thumbnailView.rawValue,
                                  DisplayAction.listView.rawValue,
                                  DisplayAction.sort.rawValue,
                                  DisplayAction.clearRubbishBin.rawValue]
        
        XCTAssertTrue(Set(actionIdentifiers) == Set(actionIdentifiersArray))
    }
    
    func testCreateContextMenuSharedItems_Display() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .display,
                                                                        sortType: .nameAscending,
                                                                        isSharedItems: true))
        let actionIdentifiers = convertMenuToActionIdentifiers(menu: cmEntity)
        actionIdentifiersArray = [DisplayAction.select.rawValue,
                                  DisplayAction.sort.rawValue]
        
        XCTAssertTrue(Set(actionIdentifiers) == Set(actionIdentifiersArray))
    }
    
    func testCreateContextMenu_UploadAdd() throws {
        let cmEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .uploadAdd,
                                                                        showMediaDiscovery: true))
        
        let actionIdentifiers = convertMenuToActionIdentifiers(menu: cmEntity)
        actionIdentifiersArray = [UploadAddAction.chooseFromPhotos.rawValue,
                                  UploadAddAction.capture.rawValue,
                                  UploadAddAction.importFrom.rawValue,
                                  UploadAddAction.scanDocument.rawValue,
                                  UploadAddAction.newFolder.rawValue,
                                  UploadAddAction.newTextFile.rawValue]
        
        XCTAssertTrue(Set(actionIdentifiers) == Set(actionIdentifiersArray))
    }
    
    func testCreateContextMenu_HomeDocumentsExplorer() throws {
        let cmUploadAddEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .uploadAdd,
                                                                        isDocumentExplorer: true))
        
        let uploadAddActionIdentifiers = convertMenuToActionIdentifiers(menu: cmUploadAddEntity)
        actionIdentifiersArray = [UploadAddAction.newTextFile.rawValue,
                                  UploadAddAction.scanDocument.rawValue,
                                  UploadAddAction.importFrom.rawValue]
        
        XCTAssertTrue(Set(uploadAddActionIdentifiers) == Set(actionIdentifiersArray))
        
        let cmDisplayEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .display,
                                                                               viewMode: .list,
                                                                               sortType: .nameAscending,
                                                                               isDocumentExplorer: true))
        
        let displayActionIdentifiers = convertMenuToActionIdentifiers(menu: cmDisplayEntity)
        actionIdentifiersArray = [DisplayAction.select.rawValue,
                                  DisplayAction.thumbnailView.rawValue,
                                  DisplayAction.listView.rawValue,
                                  DisplayAction.sort.rawValue]
        
        XCTAssertTrue(Set(displayActionIdentifiers) == Set(actionIdentifiersArray))
    }
    
    func testCreateContextMenu_HomeAudiosExplorer() throws {
        let cmDisplayEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .display,
                                                                               viewMode: .list,
                                                                               sortType: .nameAscending,
                                                                               isAudiosExplorer: true))
        
        let displayActionIdentifiers = convertMenuToActionIdentifiers(menu: cmDisplayEntity)
        actionIdentifiersArray = [DisplayAction.select.rawValue,
                                  DisplayAction.sort.rawValue]
        
        XCTAssertTrue(Set(displayActionIdentifiers) == Set(actionIdentifiersArray))
    }
    
    func testCreateContextMenu_HomeVideosExplorer() throws {
        let cmDisplayEntity = try contextMenuActionEntity(with: CMConfigEntity(menuType: .display,
                                                                               viewMode: .list,
                                                                               sortType: .nameAscending,
                                                                               isVideosExplorer: true))
        
        let displayActionIdentifiers = convertMenuToActionIdentifiers(menu: cmDisplayEntity)
        actionIdentifiersArray = [DisplayAction.sort.rawValue]
        
        XCTAssertTrue(Set(displayActionIdentifiers) == Set(actionIdentifiersArray))
    }
}
