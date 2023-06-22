import MEGADomain
import XCTest

final class ContextMenuActionsTests: XCTestCase {
    
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
    
    private func filterUploadAddActions(from menuActions: [CMElementTypeEntity]) -> [UploadAddActionEntity] {
        menuActions.compactMap {
            if case let .uploadAdd(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    private func filterDisplayActions(from menuActions: [CMElementTypeEntity]) -> [DisplayActionEntity] {
        menuActions.compactMap {
            if case let .display(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    private func filterSortActions(from menuActions: [CMElementTypeEntity]) -> [SortOrderEntity] {
        menuActions.compactMap {
            if case let .sort(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    private func filterRubbishBinActions(from menuActions: [CMElementTypeEntity]) -> [RubbishBinActionEntity] {
        menuActions.compactMap {
            if case let .rubbishBin(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    private func filterQuickActions(from menuActions: [CMElementTypeEntity]) -> [QuickActionEntity] {
        menuActions.compactMap {
            if case let .quickActions(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    private func filterChatStatusActions(from menuActions: [CMElementTypeEntity]) -> [ChatStatusEntity] {
        menuActions.compactMap {
            if case let .chatStatus(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    private func filterMyQRActions(from menuActions: [CMElementTypeEntity]) -> [MyQRActionEntity] {
        menuActions.compactMap {
            if case let .qr(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    private func filterMeetingActions(from menuActions: [CMElementTypeEntity]) -> [MeetingActionEntity] {
        menuActions.compactMap {
            if case let .meeting(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    private func filterDoNotDisturbDisabled(from menuActions: [CMElementTypeEntity]) -> [DNDDisabledActionEntity] {
        menuActions.compactMap {
            if case let .chatDoNotDisturbDisabled(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    private func filterDoNotDisturbEnabled(from menuActions: [CMElementTypeEntity]) -> [DNDTurnOnOptionEntity] {
        menuActions.compactMap {
            if case let .chatDoNotDisturbEnabled(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    private func filterAlbumActions(from menuActions: [CMElementTypeEntity]) -> [AlbumActionEntity] {
        menuActions.compactMap {
            if case let .album(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    private func filterFilterActions(from menuActions: [CMElementTypeEntity]) -> [FilterEntity] {
        menuActions.compactMap {
            if case let .filter(action) = $0 {
                return action
            }
            return nil
        }
    }
    
    func testUploadAddMenu() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .uploadAdd))
                                                .setShowMediaDiscovery(true)
                                                .build())

        XCTAssertTrue(filterUploadAddActions(from: decomposeMenuIntoActions(menu: menuEntity)) == UploadAddActionEntity.allCases)
    }
    
    func testDisplayMenu() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setViewMode(.list)
                                                .setSortType(.defaultAsc)
                                                .build())
        
        let excludedActions: [DisplayActionEntity] = [.clearRubbishBin, .mediaDiscovery, .filter, .sort]
        
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedActions.contains($0) })
        
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
            
    }
    
    func testDisplayMenu_isViewInFolder() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setViewMode(.list)
                                                .setSortType(.defaultAsc)
                                                .setIsViewInFolder(true)
                                                .build())
        
        let excludedActions: [DisplayActionEntity] = [.select, .clearRubbishBin, .mediaDiscovery, .filter, .sort]
        
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedActions.contains($0) })
        
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
            
    }

    func testDisplayMenuRubbishBin_isViewInFolder() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setViewMode(.list)
                                                .setSortType(.defaultAsc)
                                                .setIsRubbishBinFolder(true)
                                                .setIsViewInFolder(true)
                                                .build())
        
        let excludedActions: [DisplayActionEntity] = [.select, .mediaDiscovery, .filter, .sort, .clearRubbishBin]
    
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedActions.contains($0) })
                                                            
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
    }
    
    func testDisplayMenuRubbishBin() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setViewMode(.list)
                                                .setSortType(.defaultAsc)
                                                .setIsRubbishBinFolder(true)
                                                .build())
        
        let excludedActions: [DisplayActionEntity] = [.mediaDiscovery, .filter, .sort]
    
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedActions.contains($0) })
                                                            
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
    }
    
    func testDisplayMenuOffline() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setViewMode(.list)
                                                .setSortType(.defaultAsc)
                                                .setIsOfflineFolder(true)
                                                .build())
        
        let excludedDisplayActions: [DisplayActionEntity] = [.mediaDiscovery, .clearRubbishBin, .filter, .sort]
        let excludedSortOptions: [SortOrderEntity] = [.labelAsc, .favouriteAsc]
        
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedDisplayActions.contains($0) })
                                                            
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid
                                                                                                        .filter { !excludedSortOptions.contains($0) })
    }
    
    func testDisplayMenuBackupsRootNode() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setAccessLevel(.owner)
                                                .setIsAFolder(true)
                                                .setBackupsRootNode(true)
                                                .build())

        let excludedDisplayActions: [DisplayActionEntity] = [.mediaDiscovery, .clearRubbishBin, .filter, .sort]
        
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedDisplayActions.contains($0) })
                                                            
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
    }
    
    func testDisplayMenuBackupsChild() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setAccessLevel(.owner)
                                                .setIsAFolder(true)
                                                .setIsBackupsChild(true)
                                                .build())

        let excludedQuickActions: [QuickActionEntity] = [.manageLink, .removeLink, .manageFolder, .rename, .removeSharing, .leaveSharing]
        let excludedDisplayActions: [DisplayActionEntity] = [.mediaDiscovery, .clearRubbishBin, .filter, .sort]
        
        XCTAssertTrue(filterQuickActions(from: decomposeMenuIntoActions(menu: menuEntity)) == QuickActionEntity
                                                                                                            .allCases
                                                                                                            .filter { !excludedQuickActions.contains($0) })
        
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedDisplayActions.contains($0) })
                                                            
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
    }

    func testRubbishBinSubFoldersMenu() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                    .setType(.menu(type: .rubbishBin))
                                                    .setSortType(.defaultAsc)
                                                    .setIsRubbishBinFolder(true)
                                                    .setIsRestorable(true)
                                                    .setVersionsCount(2)
                                                    .build())

        XCTAssertTrue(filterRubbishBinActions(from: decomposeMenuIntoActions(menu: menuEntity)) == RubbishBinActionEntity
                                                                                                                    .allCases)
    }

    func testQuickFolderActionMenu_readOnly() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setAccessLevel(.read)
                                                .setShowMediaDiscovery(true)
                                                .setIsAFolder(true)
                                                .build())

        let excludedQuickActions: [QuickActionEntity] = [.shareLink, .manageLink, .removeLink, .manageFolder, .removeSharing, .shareFolder, .rename, .leaveSharing]
        let excludedDisplayActions: [DisplayActionEntity] = [.clearRubbishBin, .filter, .sort]
        
        XCTAssertTrue(filterQuickActions(from: decomposeMenuIntoActions(menu: menuEntity)) == QuickActionEntity
                                                                                                            .allCases
                                                                                                            .filter { !excludedQuickActions.contains($0) })
        
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedDisplayActions.contains($0) })
                                                            
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
    }

    func testQuickFolderActionMenu_IncomingChild() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setIsIncomingShareChild(true)
                                                .setShowMediaDiscovery(true)
                                                .setIsAFolder(true)
                                                .build())

        let excludedQuickActions: [QuickActionEntity] = [.shareLink, .manageLink, .removeLink, .manageFolder, .removeSharing, .shareFolder, .rename]
        let excludedDisplayActions: [DisplayActionEntity] = [.clearRubbishBin, .filter, .sort]
        
        XCTAssertTrue(filterQuickActions(from: decomposeMenuIntoActions(menu: menuEntity)) == QuickActionEntity
                                                                                                            .allCases
                                                                                                            .filter { !excludedQuickActions.contains($0) })
        
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedDisplayActions.contains($0) })
                                                            
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
    }

    func testQuickFolderActionMenu_Outgoing() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setAccessLevel(.owner)
                                                .setIsOutShare(true)
                                                .setIsSharedItemsChild(true)
                                                .setShowMediaDiscovery(true)
                                                .setIsAFolder(true)
                                                .build())

        let excludedQuickActions: [QuickActionEntity] = [.manageLink, .removeLink, .leaveSharing, .shareFolder]
        let excludedDisplayActions: [DisplayActionEntity] = [.clearRubbishBin, .filter, .sort]

        XCTAssertTrue(filterQuickActions(from: decomposeMenuIntoActions(menu: menuEntity)) == QuickActionEntity
                                                                                                            .allCases
                                                                                                            .filter { !excludedQuickActions.contains($0) })
        
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedDisplayActions.contains($0) })
                                                            
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
    }

    func testQuickFolderActionMenu_Outgoing_exported() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setAccessLevel(.owner)
                                                .setIsOutShare(true)
                                                .setIsSharedItemsChild(true)
                                                .setIsExported(true)
                                                .setShowMediaDiscovery(true)
                                                .setIsAFolder(true)
                                                .build())

        let excludedQuickActions: [QuickActionEntity] = [.shareLink, .leaveSharing, .shareFolder]
        let excludedDisplayActions: [DisplayActionEntity] = [.clearRubbishBin, .filter, .sort]
        
        XCTAssertTrue(filterQuickActions(from: decomposeMenuIntoActions(menu: menuEntity)) == QuickActionEntity
                                                                                                            .allCases
                                                                                                            .filter { !excludedQuickActions.contains($0) })
        
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedDisplayActions.contains($0) })
                                                            
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
    }

    func testDisplayMenuCameraUploadExplorer() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setSortType(.modificationDesc)
                                                .setIsSharedItems(true)
                                                .setIsCameraUploadExplorer(true)
                                                .build())

        let excludedDisplayActions: [DisplayActionEntity] = [.mediaDiscovery, .thumbnailView, .listView, .clearRubbishBin, .filter, .sort]
        let excludedSortOptions: [SortOrderEntity] = [.defaultAsc, .defaultDesc, .sizeDesc, .sizeAsc, .labelAsc, .favouriteAsc]
        
        XCTAssertTrue(filterDisplayActions(from: decomposeMenuIntoActions(menu: menuEntity)) == DisplayActionEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedDisplayActions.contains($0) })
        
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid
                                                                                                        .filter { !excludedSortOptions.contains($0) })
    }

    func testDisplayMenuFavouritesExplorerSortByOptions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setSortType(.modificationDesc)
                                                .setIsFavouritesExplorer(true)
                                                .build())

        let excludedSortOptions: [SortOrderEntity] = [.favouriteAsc]
        
        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid
                                                                                                        .filter { !excludedSortOptions.contains($0) })
    }

    func testDisplayMenuDocumentExplorerSortByOptions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setSortType(.modificationDesc)
                                                .setIsDocumentExplorer(true)
                                                .build())

        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
    }

    func testDisplayMenuAudioExplorerSortByOptions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setSortType(.modificationDesc)
                                                .setIsAudiosExplorer(true)
                                                .build())

        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
    }

    func testDisplayMenuVideoExplorerSortByOptions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .display))
                                                .setSortType(.modificationDesc)
                                                .setIsVideosExplorer(true)
                                                .build())

        XCTAssertTrue(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)) == SortOrderEntity
                                                                                                        .allValid)
    }
    
    func testChatActionsMenu() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .chat))
                                                .setIsDoNotDisturbEnabled(false)
                                                .setTimeRemainingToDeactiveDND("")
                                                .setChatStatus(.online)
                                                .build())
        
        let excludedChatStatusActions: [ChatStatusEntity] = [.invalid]
        let excludedDoNotDisturbEnabledOptions: [DNDTurnOnOptionEntity] = [.forever]
        
        XCTAssertTrue(filterChatStatusActions(from: decomposeMenuIntoActions(menu: menuEntity)) == ChatStatusEntity
                                                                                                                .allCases
                                                                                                                .filter { !excludedChatStatusActions.contains($0) })
        
        XCTAssertTrue(filterDoNotDisturbDisabled(from: decomposeMenuIntoActions(menu: menuEntity)) == DNDDisabledActionEntity
                                                                                                                        .allCases)
        
        XCTAssertTrue(filterDoNotDisturbEnabled(from: decomposeMenuIntoActions(menu: menuEntity)) == DNDTurnOnOptionEntity
                                                                                                                        .allCases
                                                                                                                        .filter { !excludedDoNotDisturbEnabledOptions.contains($0) })
                                                                            
    }
    
    func testMyQRActionsMenu() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .qr))
                                                .setIsShareAvailable(true)
                                                .build())
        
        XCTAssertTrue(filterMyQRActions(from: decomposeMenuIntoActions(menu: menuEntity)) == MyQRActionEntity
                                                                                                        .allCases)
    }
    
    func testMeetingActionsMenuWithoutScheduleMeeting() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .meeting))
                                                .build())
                
        XCTAssertTrue(filterMeetingActions(from: decomposeMenuIntoActions(menu: menuEntity)) == [MeetingActionEntity.startMeeting, MeetingActionEntity.joinMeeting])
    }
    
    func testMeetingActionsMenuWithScheduleMeeting() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .meeting))
                                                .setShouldScheduleMeeting(true)
                                                .build())
        
        XCTAssertTrue(filterMeetingActions(from: decomposeMenuIntoActions(menu: menuEntity)) == MeetingActionEntity
                                                                                                                .allCases)
    }
    
    func testTimelineMenu_onSortTypeFitlerEnabledAndSelectNotHidden_shouldShowAllOptions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
            .setType(.menu(type: .timeline))
            .setSortType(.modificationDesc)
            .setIsCameraUploadExplorer(true)
            .setIsFilterEnabled(true)
            .setIsSelectHidden(false)
            .setIsEmptyState(false)
            .build())
        let actions = decomposeMenuIntoActions(menu: menuEntity)
        
        XCTAssertEqual(filterDisplayActions(from: actions),
                       [.select, .filter])
        XCTAssertEqual(filterSortActions(from: actions),
                       [.modificationDesc, .modificationAsc])
    }
    
    func testTimelineMenu_onEmptyState_shouldDisableSelectAndSortEnableFilter() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
            .setType(.menu(type: .timeline))
            .setSortType(.modificationDesc)
            .setIsCameraUploadExplorer(true)
            .setIsFilterEnabled(true)
            .setIsSelectHidden(false)
            .setIsEmptyState(true)
            .build())
        let actions = decomposeMenuIntoActions(menu: menuEntity)
        
        XCTAssertEqual(filterDisplayActions(from: actions),
                       [.select, .sort, .filter])
    }
    
    func testAlbumMenu_onSharedLinkExportedState_showsCorrectLinkActions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .album))
                                                .setSortType(.defaultDesc)
                                                .setFilterType(.allMedia)
                                                .setAlbumType(.user)
                                                .setIsFilterEnabled(true)
                                                .setIsSelectHidden(false)
                                                .setIsEmptyState(false)
                                                .setSharedLinkStatus(.exported(true))
                                                .build())
        
        let actions = decomposeMenuIntoActions(menu: menuEntity)
        
        XCTAssertEqual(filterQuickActions(from: actions),
                       [.manageLink, .removeLink, .rename])
        XCTAssertEqual(filterAlbumActions(from: actions),
                       [.selectAlbumCover, .delete])
        XCTAssertEqual(filterSortActions(from: decomposeMenuIntoActions(menu: menuEntity)), [.modificationDesc, .modificationAsc])
        XCTAssertEqual(filterFilterActions(from: decomposeMenuIntoActions(menu: menuEntity)), [.allMedia, .images, .videos])
    }
    
    func testAlbumMenu_onAlbumShareLinkUnavailable_showsNoLinkActions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .album))
                                                .setAlbumType(.user)
                                                .setSharedLinkStatus(.unavailable)
                                                .build())
        
        let actions = decomposeMenuIntoActions(menu: menuEntity)
        XCTAssertEqual(filterQuickActions(from: actions), [.rename])
    }
    
    func testAlbumMenu_onAlbumShareLinkNotExported_showsShareLinkAction() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
                                                .setType(.menu(type: .album))
                                                .setAlbumType(.user)
                                                .setSharedLinkStatus(.exported(false))
                                                .build())
        
        let actions = decomposeMenuIntoActions(menu: menuEntity)
        XCTAssertTrue(filterQuickActions(from: actions).contains(.shareLink))
    }
    
    func testAlbumMenu_onEmptyAlbumSharedLinkExportedState_showsCorrectLinkActions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
            .setType(.menu(type: .album))
            .setAlbumType(.user)
            .setIsEmptyState(true)
            .setSharedLinkStatus(.exported(true))
            .build())
        
        let actions = decomposeMenuIntoActions(menu: menuEntity)
        
        XCTAssertEqual(filterQuickActions(from: actions),
                       [.manageLink, .removeLink, .rename])
        XCTAssertEqual(filterAlbumActions(from: actions), [.delete])
    }
    
    func testAlbumMenu_onEmptyAlbumSharedLinkExportedStateFalse_showsCorrectLinkActions() throws {
        let menuEntity = try XCTUnwrap(ContextMenuBuilder()
            .setType(.menu(type: .album))
            .setAlbumType(.user)
            .setIsEmptyState(true)
            .setSharedLinkStatus(.exported(false))
            .build())
        
        let actions = decomposeMenuIntoActions(menu: menuEntity)
        
        XCTAssertEqual(filterQuickActions(from: actions),
                       [.shareLink, .rename])
        XCTAssertEqual(filterAlbumActions(from: actions), [.delete])
    }
}
