import FolderLink
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import Search
import SwiftUI
import XCTest

@MainActor
final class FolderLinkMediaDiscoveryViewModelTests {
    static func makeSUT(
        handle: HandleEntity = 0,
        link: String = "https://mega.nz/folders/abc",
        titleUseCase: MockFolderLinkTitleUseCase = MockFolderLinkTitleUseCase(),
        trackingUseCase: MockFolderLinkTrackingUseCase = MockFolderLinkTrackingUseCase(),
        editModeUseCase: MockFolderLinkEditModeUseCase = MockFolderLinkEditModeUseCase(),
        bottomBarUseCase: MockFolderLinkBottomBarUseCase = MockFolderLinkBottomBarUseCase(),
        quickActionUseCase: MockFolderLinkQuickActionUseCase = MockFolderLinkQuickActionUseCase(),
        viewMode: SearchResultsViewMode = .list,
        viewModeUpdate: @escaping (SearchResultsViewMode) -> Void = { _ in }
    ) -> FolderLinkMediaDiscoveryViewModel {
        let dependency = FolderLinkMediaDiscoveryViewModel.Dependency(
            handle: handle,
            link: link,
            titleUseCase: titleUseCase,
            trackingUseCase: trackingUseCase,
            editModeUseCase: editModeUseCase,
            bottomBarUseCase: bottomBarUseCase,
            quickActionUseCase: quickActionUseCase
        )
        let viewModeBinding: Binding<SearchResultsViewMode> = Binding(
            get: { viewMode },
            set: { viewModeUpdate($0) }
        )

        return FolderLinkMediaDiscoveryViewModel(dependency: dependency, viewMode: viewModeBinding)
    }
    
    @MainActor
    final class ViewModeTests: XCTestCase {
        func testInitialViewMode() {
            for viewMode in [SearchResultsViewMode.list, .grid, .mediaDiscovery] {
                let sut = makeSUT(viewMode: viewMode)
                XCTAssertEqual(sut.viewMode, viewMode)
            }
        }
        
        func testReceiveUpdatesFromViewModeViewModel() async {
            // Given
            var updatedViewMode: SearchResultsViewMode?
            let expectation = XCTestExpectation(description: "Should receive updated view mode")
            let sut = makeSUT(viewMode: .list) {
                updatedViewMode = $0
                expectation.fulfill()
            }
            
            // When
            sut.viewModeViewModel.selectedViewMode = .grid
            
            await fulfillment(of: [expectation], timeout: 1)
            
            // Then
            XCTAssertEqual(updatedViewMode, .grid)
        }
        
        func testShouldNotReceiveUpdatesFromViewModeViewModelWhenChangeToMediaDiscovery() async {
            // Given
            let expectation = XCTestExpectation(description: "Should receive updated view mode")
            expectation.isInverted = true
            let sut = makeSUT(viewMode: .list) { _ in
                expectation.fulfill()
            }
            
            // When
            sut.viewModeViewModel.selectedViewMode = .mediaDiscovery
            
            await fulfillment(of: [expectation], timeout: 1)
        }
        
        func testShouldHasAllAvailableViewModes() {
            let sut = makeSUT()
            XCTAssertEqual(sut.viewModeViewModel.availableViewModes, [.list, .grid, .mediaDiscovery])
        }
    }
    
    @MainActor
    final class TitleAndSubtitleTests: XCTestCase {
        func assertEqual(title: String?, and subtitle: String?, when titleType: FolderLinkTitleType) {
            // Given
            let titleUseCase = MockFolderLinkTitleUseCase(titleType: titleType)
            let sut = makeSUT(titleUseCase: titleUseCase)
            
            // Then
            XCTAssertEqual(sut.title, title)
            XCTAssertEqual(sut.subtitle, subtitle)
        }
        
        func testTitleAndSubtitle() {
            let testcases: [(String?, String?, FolderLinkTitleType)] = [
                (Strings.Localizable.selectTitle, nil, .askForSelecting),
                ("nodeName", Strings.Localizable.folderLink, .folderNodeName("nodeName")),
                (Strings.Localizable.General.Format.itemsSelected(5), nil, .selectedItems(5)),
                (Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName, Strings.Localizable.folderLink, .undecryptedFolder),
                (Strings.Localizable.folderLink, nil, .generic)
            ]
            
            for (title, subtitle, titleType) in testcases {
                assertEqual(title: title, and: subtitle, when: titleType)
            }
        }
        
        func testTitleAndSubtitleRefreshedWhenSelectedPhotosOrEditModeChanges() async {
            let expectation = XCTestExpectation(description: "Should refresh title and subtile when selectedPhotos or editMode changes")
            expectation.expectedFulfillmentCount = 4
            let titleUseCase = MockFolderLinkTitleUseCase()
            let sut = makeSUT(handle: 0, titleUseCase: titleUseCase)
            let subscription = sut
                .$title
                .sink { _ in
                    expectation.fulfill()
                }
            
            // When
            sut.editMode = .active
            sut.updateSelectedPhotos([NodeEntity(handle: 1)])
            sut.editMode = .inactive
            
            await fulfillment(of: [expectation], timeout: 1)
            
            // Then
            XCTAssertEqual(titleUseCase.calledArguments.count, 4)
            
            subscription.cancel()
        }
    }
    
    @MainActor
    final class BottomBarTests: XCTestCase {
        func testShouldShowHideBottomBarWhenEditModeChanges() {
            // Given
            let sut = makeSUT()
            XCTAssertEqual(sut.editMode, .inactive)
            XCTAssertFalse(sut.shouldShowBottomBar)
            
            // When
            sut.editMode = .active
            
            // Then
            XCTAssertTrue(sut.shouldShowBottomBar)
        }
        
        func testBottomBarDisabledComesFromUseCase() {
            func assertBottomBarDisabled(_ disabled: Bool) {
                let bottomBarUseCase = MockFolderLinkBottomBarUseCase(bottomBarDisabled: disabled)
                let sut = makeSUT(bottomBarUseCase: bottomBarUseCase)
                XCTAssertEqual(sut.bottomBarDisabled, disabled)
            }

            for disabled in [true, false] {
                assertBottomBarDisabled(disabled)
            }
        }

        func testBottomBarDisabledUpdatesWhenSelectedPhotosOrEditModeChanges() async {
            // Given
            let expectation = XCTestExpectation(description: "$bottomBarDisabled should change when selectedPhotos or editMode changes")
            expectation.expectedFulfillmentCount = 4
            let bottomBarUseCase = MockFolderLinkBottomBarUseCase()
            let sut = makeSUT(bottomBarUseCase: bottomBarUseCase)
            let subscription = sut
                .$bottomBarDisabled
                .sink { _ in
                    expectation.fulfill()
                }

            // When
            sut.editMode = .active
            sut.updateSelectedPhotos([NodeEntity(handle: 1)])
            sut.editMode = .inactive

            await fulfillment(of: [expectation], timeout: 1)

            // Then
            // shouldDisableBottomBar is called 4 times: first open, enter edit mode, selection changed, exit edit mode
            XCTAssertEqual(bottomBarUseCase.shouldDisableBottomBarCalledArguments.count, 4)

            subscription.cancel()
        }

        func testShouldIncludeSaveToPhotosBottomActionComesFromUseCase() {
            for included in [true, false] {
                let bottomBarUseCase = MockFolderLinkBottomBarUseCase(saveToPhotoActionIncluded: included)
                let sut = makeSUT(bottomBarUseCase: bottomBarUseCase)
                XCTAssertEqual(sut.shouldIncludeSaveToPhotosBottomAction, included)
            }
        }

        func testBottomBarAction_whenEditing_shouldUseSelectedPhotos() {
            func assertEqual(nodesAction: FolderLinkNodesAction, when bottomBarAction: FolderLinkBottomBarAction) {
                // Given
                let sut = makeSUT(handle: parentHandle)
                sut.editMode = .active
                sut.updateSelectedPhotos([NodeEntity(handle: 1), NodeEntity(handle: 2)])

                // When
                sut.bottomBarAction = bottomBarAction
                
                // Then
                XCTAssertEqual(nodesAction, sut.nodesAction)
            }

            let testcases: [(FolderLinkNodesAction, FolderLinkBottomBarAction)] = [
                (.addToCloudDrive([1, 2]), .addToCloudDrive),
                (.makeAvailableOffline([1, 2]), .makeAvailableOffline),
                (.downloadToFiles([1, 2]), .downloadToFiles),
                (.saveToPhotos([1, 2]), .saveToPhotos)
            ]
            
            for (nodesAction, bottomBarAction) in testcases {
                assertEqual(nodesAction: nodesAction, when: bottomBarAction)
            }
        }

        /// The anchored buttons of the revamp act while browsing, where nothing is selected, so they have
        /// to cover the folder itself rather than the empty selection.
        func testBottomBarAction_whenNotEditing_shouldUseParentNodeOnly() {
            func assertEqual(nodesAction: FolderLinkNodesAction, when bottomBarAction: FolderLinkBottomBarAction) {
                // Given
                let sut = makeSUT(handle: parentHandle)
                sut.editMode = .inactive
                sut.updateSelectedPhotos([NodeEntity(handle: 1), NodeEntity(handle: 2)])

                // When
                sut.bottomBarAction = bottomBarAction

                // Then
                XCTAssertEqual(nodesAction, sut.nodesAction)
            }

            let testcases: [(FolderLinkNodesAction, FolderLinkBottomBarAction)] = [
                (.addToCloudDrive([parentHandle]), .addToCloudDrive),
                (.makeAvailableOffline([parentHandle]), .makeAvailableOffline),
                (.downloadToFiles([parentHandle]), .downloadToFiles),
                // Save to Photos cannot actually take a folder — this pins the interim mapping, not a
                // working flow, and IOS-11735 is expected to change both it and this expectation.
                (.saveToPhotos([parentHandle]), .saveToPhotos)
            ]

            for (nodesAction, bottomBarAction) in testcases {
                assertEqual(nodesAction: nodesAction, when: bottomBarAction)
            }
        }

        private let parentHandle: HandleEntity = 100
    }

    /// The more options sheet acts on the folder rather than on a selection, so its rows always cover the
    /// folder's own handle no matter what is selected.
    @MainActor
    final class QuickActionTests: XCTestCase {
        func testQuickAction() {
            func assertEqual(nodesAction: FolderLinkNodesAction, when quickAction: FolderLinkQuickAction) {
                // Given
                let sut = makeSUT(handle: parentHandle, link: link)
                sut.editMode = .active
                sut.updateSelectedPhotos([NodeEntity(handle: 1), NodeEntity(handle: 2)])

                // When
                sut.quickAction = quickAction

                // Then
                XCTAssertEqual(nodesAction, sut.nodesAction)
            }

            let testcases: [(FolderLinkNodesAction, FolderLinkQuickAction)] = [
                (.addToCloudDrive([parentHandle]), .addToCloudDrive),
                (.makeAvailableOffline([parentHandle]), .makeAvailableOffline),
                (.sendToChat(link), .sendToChat)
            ]

            for (nodesAction, quickAction) in testcases {
                assertEqual(nodesAction: nodesAction, when: quickAction)
            }
        }

        private let parentHandle: HandleEntity = 100
        private let link = "https://mega.nz/folders/abc"
    }
    
    @MainActor
    final class NodesActionTests: XCTestCase {
        func testWhenNodesActionChangesShouldCancelEditMode() {
            // Given
            let sut = makeSUT()
            sut.editMode = .active
            
            // When
            sut.nodesAction = .addToCloudDrive([1])
            
            // Then
            XCTAssertEqual(sut.editMode, .inactive)
        }
    }
    
    @MainActor
    final class TrackingTests: XCTestCase {
        func testTrackEventWhenSortOrderChanged() {
            // Given
            let trackingUseCase = MockFolderLinkTrackingUseCase()
            let sut = makeSUT(trackingUseCase: trackingUseCase)
            XCTAssertEqual(sut.sortOrder, MEGAUIComponent.SortOrder(key: .lastModified, direction: .descending))
            
            // When
            let updatedSortOrder = MEGAUIComponent.SortOrder(key: .lastModified, direction: .ascending)
            sut.sortOrder = updatedSortOrder
            
            // Then
            XCTAssertEqual(trackingUseCase.trackedSortOrder, updatedSortOrder)
        }
        
        func testTrackEventWhenSortHeaderPressed() {
            // Given
            let trackingUseCase = MockFolderLinkTrackingUseCase()
            let sut = makeSUT(trackingUseCase: trackingUseCase)
            XCTAssertFalse(trackingUseCase.trackSortHeaderPressedCalled)
            
            // When
            sut.sortHeaderPressed()
            
            // Then
            XCTAssertTrue(trackingUseCase.trackSortHeaderPressedCalled)
        }
    }
    
    @MainActor
    final class ToggleSelectAllTests: XCTestCase {
        func testShouldToggleSelectAll() {
            // Given
            let sut = makeSUT()
            XCTAssertFalse(sut.selectAll)
            
            // When
            sut.toggleSelectAll()
            
            // Then
            XCTAssertTrue(sut.selectAll)
            
            // And when
            sut.toggleSelectAll()
            
            // Then
            XCTAssertFalse(sut.selectAll)
        }
    }
    
    @MainActor
    final class UpdateSelectedPhotosTests: XCTestCase {
        func testShouldUpdateSelectedPhotos() {
            // Given
            let sut = makeSUT()
            let photos = [
                NodeEntity(handle: 1),
                NodeEntity(handle: 2)
            ]
            
            // When
            sut.updateSelectedPhotos(photos)
            
            // Then
            XCTAssertEqual(sut.selectedPhotos, photos)
        }
    }
}
