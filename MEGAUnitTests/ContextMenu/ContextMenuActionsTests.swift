import XCTest
@testable import MEGA

final class ContextMenuActionsTests: XCTestCase {
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
    
    private func compare(menuEntity: CMEntity, menuActionIdentifiers: [String]) {
        let actionsIdentifiers = convertMenuToActionIdentifiers(menu: menuEntity)
        
        XCTAssertNotNil(actionsIdentifiers)
        XCTAssertTrue(Set(actionsIdentifiers) == Set(menuActionIdentifiers))
    }
    
    func testUploadAddMenu() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.uploadAdd)
                                                .setShowMediaDiscovery(true)
                                                .build())
        
        compare(menuEntity: menuEntity, menuActionIdentifiers: UploadAddAction
                                                                        .allCases
                                                                        .compactMap{$0.rawValue})
    }
    
    func testDisplayMenu() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setViewMode(.list)
                                                .setSortType(.nameAscending)
                                                .build())
        
        compare(menuEntity: menuEntity, menuActionIdentifiers: DisplayAction
                                                                        .allCases
                                                                        .filter{$0 != .clearRubbishBin && $0 != .mediaDiscovery}
                                                                        .compactMap{$0.rawValue})
    }
    
    func testDisplayMenuRubbishBin() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setViewMode(.list)
                                                .setSortType(.nameAscending)
                                                .setIsRubbishBinFolder(true)
                                                .build())
        
        compare(menuEntity: menuEntity, menuActionIdentifiers: DisplayAction
                                                                        .allCases
                                                                        .filter{$0 != .mediaDiscovery}
                                                                        .compactMap{$0.rawValue})
    }
    
    func testRubbishBinSubFoldersMenu() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                    .setType(.rubbishBin)
                                                    .setSortType(.nameAscending)
                                                    .setIsRubbishBinFolder(true)
                                                    .setIsRestorable(true)
                                                    .setVersionsCount(2)
                                                    .build())
        
        compare(menuEntity: menuEntity, menuActionIdentifiers: RubbishBinAction
                                                                        .allCases
                                                                        .compactMap{$0.rawValue})
    }
    
    func testQuickFolderActionMenu() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setAccessLevel(.accessOwner)
                                                .setIsIncomingShareChild(false)
                                                .setShowMediaDiscovery(true)
                                                .setIsAFolder(true)
                                                .build())
        
        let excludedActions: [QuickFolderAction] = [.leaveSharing]
        
        compare(menuEntity: menuEntity, menuActionIdentifiers: [QuickFolderAction
                                                                            .allCases
                                                                            .filter { !excludedActions.contains($0) }
                                                                            .compactMap{$0.rawValue},
                                                                DisplayAction
                                                                            .allCases
                                                                            .filter{$0 != .clearRubbishBin}
                                                                            .compactMap{$0.rawValue}].reduce([], +))
    }
    
    func testQuickFolderActionMenu_readOnly() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setAccessLevel(.accessRead)
                                                .setShowMediaDiscovery(true)
                                                .setIsAFolder(true)
                                                .build())
        
        let excludedActions: [QuickFolderAction] = [.shareLink, .shareFolder, .rename, .leaveSharing]
        
        compare(menuEntity: menuEntity, menuActionIdentifiers: [QuickFolderAction
                                                                            .allCases
                                                                            .filter { !excludedActions.contains($0) }
                                                                            .compactMap{$0.rawValue},
                                                                DisplayAction
                                                                            .allCases
                                                                            .filter{$0 != .clearRubbishBin}
                                                                            .compactMap{$0.rawValue}].reduce([], +))
    }
    
    func testQuickFolderActionMenu_IncomingChild() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setIsIncomingShareChild(true)
                                                .setShowMediaDiscovery(true)
                                                .setIsAFolder(true)
                                                .build())
        
        compare(menuEntity: menuEntity, menuActionIdentifiers: [QuickFolderAction
                                                                            .allCases
                                                                            .compactMap{$0.rawValue},
                                                                DisplayAction
                                                                            .allCases
                                                                            .filter{$0 != .clearRubbishBin}
                                                                            .compactMap{$0.rawValue}].reduce([], +))
    }
}
