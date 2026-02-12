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
        titleUseCase: MockFolderLinkTitleUseCase = MockFolderLinkTitleUseCase(),
        trackingUseCase: MockFolderLinkTrackingUseCase = MockFolderLinkTrackingUseCase(),
        viewMode: SearchResultsViewMode = .list,
        viewModeUpdate: @escaping (SearchResultsViewMode) -> Void = { _ in }
    ) -> FolderLinkMediaDiscoveryViewModel {
        let dependency = FolderLinkMediaDiscoveryViewModel.Dependency(
            handle: handle,
            titleUseCase: titleUseCase,
            trackingUseCase: trackingUseCase
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
        
        func testShouldEnableBottomBarWhenSelectionIsNotEmpty() {
            // Given
            let sut = makeSUT()
            sut.editMode = .active
            XCTAssertTrue(sut.selectedPhotos.isEmpty)
            XCTAssertTrue(sut.bottomBarDisabled)
            
            // When
            sut.updateSelectedPhotos([NodeEntity()])
            
            // Then
            XCTAssertFalse(sut.bottomBarDisabled)
        }
        
        func testBottomBarAction() {
            func assertEqual(nodesAction: FolderLinkNodesAction, when bottomBarAction: FolderLinkBottomBarAction, with photos: [NodeEntity]) {
                // Given
                let sut = makeSUT()
                sut.updateSelectedPhotos(photos)
                
                // When
                sut.bottomBarAction = bottomBarAction
                
                // Then
                XCTAssertEqual(nodesAction, sut.nodesAction)
            }
            
            let photos = [
                NodeEntity(handle: 1),
                NodeEntity(handle: 2)
            ]
            
            let testcases: [(FolderLinkNodesAction, FolderLinkBottomBarAction)] = [
                (.addToCloudDrive([1, 2]), .addToCloudDrive),
                (.makeAvailableOffline([1, 2]), .makeAvailableOffline),
                (.saveToPhotos([1, 2]), .saveToPhotos)
            ]
            
            for (nodesAction, bottomBarAction) in testcases {
                assertEqual(nodesAction: nodesAction, when: bottomBarAction, with: photos)
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
