import FolderLink
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAUIComponent
import Search
import SwiftUI
import XCTest

@MainActor
final class FolderLinkResultsViewModelTests {
    static func makeSUT(
        handle: HandleEntity = 0,
        link: String = "https://mega.nz/folders/abc",
        searchResultsProvidingBuilder: MockFolderLinkSearchResultsProvidingBuilder = MockFolderLinkSearchResultsProvidingBuilder(),
        titleUseCase: MockFolderLinkTitleUseCase = MockFolderLinkTitleUseCase(),
        viewModeUseCase: MockFolderLinkViewModeUseCase = MockFolderLinkViewModeUseCase(),
        editModeUseCase: MockFolderLinkEditModeUseCase = MockFolderLinkEditModeUseCase(),
        bottomBarUseCase: MockFolderLinkBottomBarUseCase = MockFolderLinkBottomBarUseCase(),
        quickActionUseCase: MockFolderLinkQuickActionUseCase = MockFolderLinkQuickActionUseCase(),
        trackingUseCase: MockFolderLinkTrackingUseCase = MockFolderLinkTrackingUseCase(),
        sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase = MockSortOrderPreferenceUseCase(),
        viewMode: SearchResultsViewMode = .list,
        viewModeUpdate: @escaping (SearchResultsViewMode) -> Void = { _ in }
    ) -> FolderLinkResultsViewModel {
        let dependency = FolderLinkResultsViewModel.Dependency(
            nodeHandle: handle,
            link: link,
            searchResultsProvidingBuilder: searchResultsProvidingBuilder,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            titleUseCase: titleUseCase,
            viewModeUseCase: viewModeUseCase,
            editModeUseCase: editModeUseCase,
            bottomBarUseCase: bottomBarUseCase,
            quickActionUseCase: quickActionUseCase,
            trackingUseCase: trackingUseCase
        )
        let viewModeBinding: Binding<SearchResultsViewMode> = Binding(
            get: { viewMode },
            set: { viewModeUpdate($0) }
        )

        return FolderLinkResultsViewModel(
            dependency: dependency,
            viewMode: viewModeBinding
        )
    }
    
    @MainActor
    final class ViewModeTests: XCTestCase {
        func testInitialViewMode() {
            for viewMode in [SearchResultsViewMode.list, .grid, .mediaDiscovery] {
                let sut = makeSUT(viewMode: viewMode)
                XCTAssertEqual(sut.viewMode, viewMode)
            }
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
            sut.editMode = .active // enter edit mode
            sut.searchResultsContainerViewModel.bridge.selectionChanged([1, 2]) // select node 1 and 2
            sut.editMode = .inactive // exit edit mode
            
            await fulfillment(of: [expectation], timeout: 1)
            
            // Then
            // titleUseCase is called 4 times: first open, enter edit mode, selection changed, exit edit mode
            XCTAssertEqual(titleUseCase.calledArguments.count, 4)
            
            subscription.cancel()
        }
    }
    
    @MainActor
    final class BottomBarTests: XCTestCase {
        func testShouldShowHideBottomBar() {
            func assertBottomBarDisable(_ disabled: Bool) {
                let bottomBarUseCase = MockFolderLinkBottomBarUseCase(bottomBarDisabled: disabled)
                let sut = makeSUT(bottomBarUseCase: bottomBarUseCase)
                XCTAssertTrue(sut.bottomBarDisabled == disabled)
            }
            
            for disabled in [true, false] {
                assertBottomBarDisable(disabled)
            }
        }
        
        func testBottomBarDisabledUpdateWhenSelectedNodessOrEditModeChanges() async {
            let expectation = XCTestExpectation(description: "$bottomBarDisabled should change when selectedNodes or editMode changes")
            expectation.expectedFulfillmentCount = 4
            let bottomBarUseCase = MockFolderLinkBottomBarUseCase()
            let sut = makeSUT(handle: 0, bottomBarUseCase: bottomBarUseCase)
            let subscription = sut
                .$title
                .sink { _ in
                    expectation.fulfill()
                }
            
            // When
            sut.editMode = .active // enter edit mode
            sut.searchResultsContainerViewModel.bridge.selectionChanged([1, 2]) // select node 1 and 2
            sut.editMode = .inactive // exit edit mode
            
            await fulfillment(of: [expectation], timeout: 1)
            
            // Then
            // shouldDisableBottomBar is called 4 times: first open, enter edit mode, selection changed, exit edit mode
            XCTAssertEqual(bottomBarUseCase.shouldDisableBottomBarCalledArguments.count, 4)
            
            subscription.cancel()
        }
        
        func testBottomBarAction_whenEditModeIsInactive_shouldIncludeParentNodeOnly() {
            func assertEqual(nodesAction: FolderLinkNodesAction, when bottomBarAction: FolderLinkBottomBarAction) {
                // Given
                let sut = makeSUT(handle: parentHandle)
                sut.editMode = .inactive
                sut.searchResultsContainerViewModel.bridge.selectionChanged(childrenHandles)
                
                // When
                sut.bottomBarAction = bottomBarAction
                
                // Then
                XCTAssertEqual(nodesAction, sut.nodesAction)
            }
            
            let parentHandle: HandleEntity = 0
            let childrenHandles: Set<HandleEntity> = [1, 2]
            
            let testcases: [(FolderLinkNodesAction, FolderLinkBottomBarAction)] = [
                (.addToCloudDrive([parentHandle]), .addToCloudDrive),
                (.makeAvailableOffline([parentHandle]), .makeAvailableOffline),
                (.saveToPhotos([parentHandle]), .saveToPhotos)
            ]
            
            for (nodesAction, bottomBarAction) in testcases {
                assertEqual(nodesAction: nodesAction, when: bottomBarAction)
            }
        }
        
        func testBottomBarAction_whenEditModeIsActive_shouldIncludeSelectedChildrenNodes() {
            func assertEqual(nodesAction: FolderLinkNodesAction, when bottomBarAction: FolderLinkBottomBarAction) {
                // Given
                let sut = makeSUT(handle: parentHandle)
                sut.editMode = .active
                sut.searchResultsContainerViewModel.bridge.selectionChanged(childrenHandles)
                
                // When
                sut.bottomBarAction = bottomBarAction
                
                // Then
                XCTAssertEqual(nodesAction, sut.nodesAction)
            }
            
            let parentHandle: HandleEntity = 0
            let childrenHandles: Set<HandleEntity> = [1, 2]
            
            let testcases: [(FolderLinkNodesAction, FolderLinkBottomBarAction)] = [
                (.addToCloudDrive(childrenHandles), .addToCloudDrive),
                (.makeAvailableOffline(childrenHandles), .makeAvailableOffline),
                (.saveToPhotos(childrenHandles), .saveToPhotos)
            ]
            
            for (nodesAction, bottomBarAction) in testcases {
                assertEqual(nodesAction: nodesAction, when: bottomBarAction)
            }
        }
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
            
            // When
            let updatedSortOrder = MEGAUIComponent.SortOrder(key: .lastModified, direction: .ascending)
            sut.sortOrder = updatedSortOrder
            
            // Then
            XCTAssertEqual(trackingUseCase.trackedSortOrder, updatedSortOrder)
        }
    }
    
    @MainActor
    final class PersistSortOrderTests: XCTestCase {
        func testPersistChangedSortOrder() {
            // Given
            let preferenceUseCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .sizeAsc)
            let handle: HandleEntity = 0
            let sut = makeSUT(sortOrderPreferenceUseCase: preferenceUseCase)
            XCTAssertEqual(preferenceUseCase.sortOrder(for: handle), .sizeAsc)
            
            // When
            let updatedSortOrder = MEGAUIComponent.SortOrder(key: .lastModified, direction: .ascending)
            sut.sortOrder = updatedSortOrder
            
            // Then
            XCTAssertEqual(preferenceUseCase.sortOrder(for: handle), updatedSortOrder.toDomainSortOrderEntity())
        }
    }
    
    @MainActor
    final class QuickActionTests: XCTestCase {
        func testAddToCloudDriveAction() {
            // Given
            let handle: HandleEntity = 0
            let sut = makeSUT(handle: handle)
            
            // When
            sut.quickAction = .addToCloudDrive
            
            // Then
            XCTAssertEqual(sut.nodesAction, .addToCloudDrive([handle]))
        }
        
        func testMakeAvailableOfflineAction() {
            // Given
            let handle: HandleEntity = 0
            let sut = makeSUT(handle: handle)
            
            // When
            sut.quickAction = .makeAvailableOffline
            
            // Then
            XCTAssertEqual(sut.nodesAction, .makeAvailableOffline([handle]))
        }
        
        func testSendToChatAction() {
            // Given
            let link = "https://mega.nz/folders/some_hash"
            let sut = makeSUT(link: link)
            
            // When
            sut.quickAction = .sendToChat
            
            // Then
            XCTAssertEqual(sut.nodesAction, .sendToChat(link))
        }
    }
    
    @MainActor
    final class SearchTests: XCTestCase {
        func testWhenSearchTextChangesShouldNotifySearchModule() async {
            // Given
            let expectation = XCTestExpectation(description: "Should notify Search module when search text changes")
            let sut = makeSUT()
            var receivedSearchText: String?
            sut.searchResultsContainerViewModel.bridge.queryChanged = {
                receivedSearchText = $0
                expectation.fulfill()
            }
            
            // When
            let newSearchText = "some text"
            sut.searchText = newSearchText
            await fulfillment(of: [expectation], timeout: 1)
            
            XCTAssertEqual(receivedSearchText, newSearchText)
        }
    }
}

