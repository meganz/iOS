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
        XCTAssertTrue(actionsIdentifiers == menuActionIdentifiers)
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
    
    func testDisplayMenuOffline() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setViewMode(.list)
                                                .setSortType(.nameAscending)
                                                .setIsOfflineFolder(true)
                                                .build())
        
        compare(menuEntity: menuEntity, menuActionIdentifiers: DisplayAction
                                                                            .allCases
                                                                            .filter{$0 != .clearRubbishBin && $0 != .mediaDiscovery}
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
        
        let excludedActions: [QuickFolderAction] = [.manageLink, .removeLink, .manageFolder, .removeSharing, .leaveSharing]
        
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
        
        let excludedActions: [QuickFolderAction] = [.shareLink, .manageLink, .removeLink, .manageFolder, .removeSharing, .shareFolder, .rename, .leaveSharing]
        
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
        
        let excludedActions: [QuickFolderAction] = [.shareLink, .manageLink, .removeLink, .manageFolder, .removeSharing, .shareFolder, .rename]
        
        compare(menuEntity: menuEntity, menuActionIdentifiers: [QuickFolderAction
                                                                            .allCases
                                                                            .filter { !excludedActions.contains($0) }
                                                                            .compactMap{$0.rawValue},
                                                                DisplayAction
                                                                            .allCases
                                                                            .filter{$0 != .clearRubbishBin}
                                                                            .compactMap{$0.rawValue}].reduce([], +))
    }
    
    func testQuickFolderActionMenu_Outgoing() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setAccessLevel(.accessOwner)
                                                .setIsOutShare(true)
                                                .setIsSharedItemsChild(true)
                                                .setShowMediaDiscovery(true)
                                                .setIsAFolder(true)
                                                .build())
        
        let excludedActions: [QuickFolderAction] = [.manageLink, .removeLink, .leaveSharing, .shareFolder]
        
        compare(menuEntity: menuEntity, menuActionIdentifiers: [QuickFolderAction
                                                                            .allCases
                                                                            .filter { !excludedActions.contains($0) }
                                                                            .compactMap{$0.rawValue},
                                                                DisplayAction
                                                                            .allCases
                                                                            .filter{$0 != .clearRubbishBin}
                                                                            .compactMap{$0.rawValue}].reduce([], +))
    }
    
    func testQuickFolderActionMenu_Outgoing_exported() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setAccessLevel(.accessOwner)
                                                .setIsOutShare(true)
                                                .setIsSharedItemsChild(true)
                                                .setIsExported(true)
                                                .setShowMediaDiscovery(true)
                                                .setIsAFolder(true)
                                                .build())
        
        let excludedActions: [QuickFolderAction] = [.shareLink, .leaveSharing, .shareFolder]
        
        compare(menuEntity: menuEntity, menuActionIdentifiers: [QuickFolderAction
                                                                            .allCases
                                                                            .filter { !excludedActions.contains($0) }
                                                                            .compactMap{$0.rawValue},
                                                                DisplayAction
                                                                            .allCases
                                                                            .filter{$0 != .clearRubbishBin}
                                                                            .compactMap{$0.rawValue}].reduce([], +))
    }
    
    func testDisplayMenuCameraUploadExplorer() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setSortType(.newest)
                                                .setIsSharedItems(true)
                                                .setIsCameraUploadExplorer(true)
                                                .build())

        compare(menuEntity: menuEntity, menuActionIdentifiers: DisplayAction
                                                                            .allCases
                                                                            .filter{
                                                                                $0 == .select ||
                                                                                $0 == .sort
                                                                            }
                                                                            .compactMap{$0.rawValue})
    }
    
    func testDisplayMenuFavouritesExplorerSortByOptions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setSortType(.newest)
                                                .setIsFavouritesExplorer(true)
                                                .build())
        
        let menuEntitySort = try XCTUnwrap(menuEntity.children
                                                .compactMap{ $0 as? CMEntity }
                                                .filter{ $0.identifier == DisplayAction.sort.rawValue }
                                                .first)

        compare(menuEntity: menuEntitySort, menuActionIdentifiers: SortOrderType
                                                                            .allCases
                                                                            .filter {
                                                                                $0 != .none &&
                                                                                $0 != .favourite
                                                                            }.compactMap{ $0.rawValue })
    }
    
    func testDisplayMenuDocumentExplorerSortByOptions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setSortType(.newest)
                                                .setIsDocumentExplorer(true)
                                                .build())
        
        let menuEntitySort = try XCTUnwrap(menuEntity.children
                                                .compactMap{ $0 as? CMEntity }
                                                .filter{ $0.identifier == DisplayAction.sort.rawValue }
                                                .first)

        compare(menuEntity: menuEntitySort, menuActionIdentifiers: SortOrderType
                                                                            .allCases
                                                                            .filter {
                                                                                $0 != .none
                                                                            }.compactMap{ $0.rawValue })
    }
    
    func testDisplayMenuAudioExplorerSortByOptions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setSortType(.newest)
                                                .setIsAudiosExplorer(true)
                                                .build())
        
        let menuEntitySort = try XCTUnwrap(menuEntity.children
                                                .compactMap{ $0 as? CMEntity }
                                                .filter{ $0.identifier == DisplayAction.sort.rawValue }
                                                .first)

        compare(menuEntity: menuEntitySort, menuActionIdentifiers: SortOrderType
                                                                            .allCases
                                                                            .filter {
                                                                                $0 != .none
                                                                            }.compactMap{ $0.rawValue })
    }
    
    func testDisplayMenuVideoExplorerSortByOptions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.display)
                                                .setSortType(.newest)
                                                .setIsVideosExplorer(true)
                                                .build())
        
        let menuEntitySort = try XCTUnwrap(menuEntity.children
                                                .compactMap{ $0 as? CMEntity }
                                                .filter{ $0.identifier == DisplayAction.sort.rawValue }
                                                .first)

        compare(menuEntity: menuEntitySort, menuActionIdentifiers: SortOrderType
                                                                            .allCases
                                                                            .filter {
                                                                                $0 != .none
                                                                            }.compactMap{ $0.rawValue })
    }
}
