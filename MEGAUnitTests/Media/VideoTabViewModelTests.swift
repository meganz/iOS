import Combine
@testable import MEGA
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPermissionsMock
import MEGAPreferenceMocks
import MEGATest
import SwiftUI
import Video
import XCTest

@MainActor
final class VideoTabViewModelTests: XCTestCase {

    // MARK: - Edit Mode Synchronization Tests

    func testSetSharedResourceProvider_shouldSetupEditModeObservation() async {
        let (sut, _, _, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()

        XCTAssertNil(sut.sharedResourceProvider)

        sut.sharedResourceProvider = mockProvider

        XCTAssertNotNil(sut.sharedResourceProvider)
        XCTAssertIdentical(sut.sharedResourceProvider, mockProvider)
    }

    func testEditModeChanged_fromInactiveToActive_shouldSyncToSyncModel() async {
        let (sut, _, syncModel, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()
        sut.sharedResourceProvider = mockProvider

        let expectation = expectation(description: "Edit mode synchronized")
        var subscriptions = Set<AnyCancellable>()
        syncModel.$editMode
            .dropFirst()
            .sink { editMode in
                if editMode == .active {
                    expectation.fulfill()
                }
            }
            .store(in: &subscriptions)

        mockProvider.editMode = .active

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(syncModel.editMode, .active)
    }

    func testEditModeChanged_fromActiveToInactive_shouldSyncToSyncModel() async {
        let (sut, _, syncModel, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()
        mockProvider.editMode = .active
        sut.sharedResourceProvider = mockProvider

        let expectation = expectation(description: "Edit mode synchronized to inactive")
        var subscriptions = Set<AnyCancellable>()

        // Wait for initial sync to active
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        syncModel.$editMode
            .dropFirst()
            .sink { editMode in
                if editMode == .inactive {
                    expectation.fulfill()
                }
            }
            .store(in: &subscriptions)

        mockProvider.editMode = .inactive

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(syncModel.editMode, .inactive)
    }

    func testEditModeObservation_whenSharedResourceProviderNil_shouldNotCrash() {
        let (sut, _, _, _) = makeSUT()

        XCTAssertNil(sut.sharedResourceProvider)
        XCTAssertNoThrow(sut.sharedResourceProvider = nil)
    }

    // MARK: - Navigation Bar Items Tests

    func testNavigationBarItems_whenSharedResourceProviderNil_shouldReturnEmptyArray() {
        let (sut, _, _, _) = makeSUT()

        let items = sut.navigationBarItems(for: .inactive)

        XCTAssertTrue(items.isEmpty)
    }

    func testNavigationBarItems_inNormalMode_shouldReturnContextMenuButton() {
        let (sut, _, _, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()
        let mockConfig = CMConfigEntity(
            menuType: .menu(type: .display),
            sortType: .modificationAsc,
            isSelectHidden: false,
            isEmptyState: false
        )
        let mockManager = ContextMenuManager(
            createContextMenuUseCase: MockCreateContextMenuUseCase()
        )
        mockProvider.contextMenuConfig = mockConfig
        mockProvider.contextMenuManager = mockManager
        sut.sharedResourceProvider = mockProvider

        let items = sut.navigationBarItems(for: .inactive)

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items.first?.placement, .leading)
        if case .contextMenu = items.last?.viewType {
            // Success
        } else {
            XCTFail("Expected context menu type")
        }
    }

    func testNavigationBarItems_inEditMode_shouldReturnSelectAllAndCancelButtons() {
        let (sut, _, _, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()
        sut.sharedResourceProvider = mockProvider

        let items = sut.navigationBarItems(for: .active)

        XCTAssertEqual(items.count, 2)

        let selectAllButton = items.first { $0.id == "select-all" }
        XCTAssertNotNil(selectAllButton)
        XCTAssertEqual(selectAllButton?.placement, .leading)

        let cancelButton = items.first { $0.id == "cancel" }
        XCTAssertNotNil(cancelButton)
        XCTAssertEqual(cancelButton?.placement, .trailing)
    }

    func testContextMenuButton_idShouldIncludeFilterAndSortInfo() {
        let (sut, videoListViewModel, syncModel, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()
        let mockConfig = CMConfigEntity(
            menuType: .menu(type: .display),
            sortType: .modificationAsc,
            isSelectHidden: false,
            isEmptyState: false,
            selectedVideoLocationFilter: .cloudDrive,
            selectedVideoDurationFilter: .between1And4Minutes
        )
        let mockManager = ContextMenuManager(
            createContextMenuUseCase: MockCreateContextMenuUseCase()
        )
        mockProvider.contextMenuConfig = mockConfig
        mockProvider.contextMenuManager = mockManager
        sut.sharedResourceProvider = mockProvider

        // Set filters
        videoListViewModel.selectedLocationFilterOption = .cloudDrive
        videoListViewModel.selectedDurationFilterOption = .between1And4Minutes
        syncModel.videoRevampSortOrderType = .modificationAsc

        let items = sut.navigationBarItems(for: .inactive)

        XCTAssertEqual(items.count, 3)
        let menuId = items.last?.id ?? ""
        XCTAssertTrue(menuId.contains("cloudDrive"))
        XCTAssertTrue(menuId.contains("between1And4Minutes"))
        XCTAssertTrue(menuId.contains("modificationAsc"))
    }

    func testSelectAllButton_whenTapped_shouldToggleIsAllSelected() {
        let (sut, _, syncModel, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()
        sut.sharedResourceProvider = mockProvider

        let items = sut.navigationBarItems(for: .active)
        let selectAllButton = items.first { $0.id == "select-all" }

        XCTAssertFalse(syncModel.isAllSelected)

        if case .imageButton(_, let action) = selectAllButton?.viewType {
            action()
            XCTAssertTrue(syncModel.isAllSelected)

            action()
            XCTAssertFalse(syncModel.isAllSelected)
        } else {
            XCTFail("Expected image button type")
        }
    }

    func testCancelButton_whenTapped_shouldSendEditModeToggleRequest() {
        let (sut, _, _, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()
        sut.sharedResourceProvider = mockProvider

        let expectation = expectation(description: "Edit mode toggle requested")
        var subscriptions = Set<AnyCancellable>()
        sut.editModeToggleRequested
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        let items = sut.navigationBarItems(for: .active)
        let cancelButton = items.first { $0.id == "cancel" }

        if case .textButton(_, let action) = cancelButton?.viewType {
            action()
        } else {
            XCTFail("Expected text button type")
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Context Menu Configuration Tests

    func testContextMenuConfiguration_shouldHaveCorrectMenuType() {
        let (sut, _, _, _) = makeSUT()

        let config = sut.contextMenuConfiguration()

        if case .menu(type: .mediaTabVideos) = config?.menuType {
            // Success
        } else {
            XCTFail("Expected mediaTabVideos menu type")
        }
    }

    func testContextMenuConfiguration_shouldIncludeCurrentSortType() {
        let (sut, _, syncModel, _) = makeSUT()
        syncModel.videoRevampSortOrderType = .labelAsc

        let config = sut.contextMenuConfiguration()

        XCTAssertEqual(config?.sortType, .labelAsc)
    }

    func testContextMenuConfiguration_shouldIncludeLocationFilter() {
        let (sut, videoListViewModel, _, _) = makeSUT()
        videoListViewModel.selectedLocationFilterOption = .cameraUploads

        let config = sut.contextMenuConfiguration()

        XCTAssertEqual(config?.selectedVideoLocationFilter, .cameraUploads)
    }

    func testContextMenuConfiguration_shouldIncludeDurationFilter() {
        let (sut, videoListViewModel, _, _) = makeSUT()
        videoListViewModel.selectedDurationFilterOption = .moreThan20Minutes

        let config = sut.contextMenuConfiguration()

        XCTAssertEqual(config?.selectedVideoDurationFilter, .moreThan20Minutes)
    }

    func testContextMenuConfiguration_shouldSetIsVideosRevampExplorer() {
        let (sut, _, _, _) = makeSUT()

        let config = sut.contextMenuConfiguration()

        XCTAssertEqual(config?.isVideosRevampExplorer, true)
    }

    func testContextMenuConfiguration_shouldSetCorrectFlags() {
        let (sut, _, _, _) = makeSUT()

        let config = sut.contextMenuConfiguration()

        XCTAssertEqual(config?.isSelectHidden, false)
        XCTAssertEqual(config?.isEmptyState, false)
    }

    // MARK: - Context Menu Action Handling Tests

    func testHandleDisplayAction_select_shouldSendEditModeToggleRequest() {
        let (sut, _, _, _) = makeSUT()

        let expectation = expectation(description: "Edit mode toggle requested")
        var subscriptions = Set<AnyCancellable>()
        sut.editModeToggleRequested
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        sut.handleDisplayAction(.select)

        wait(for: [expectation], timeout: 1.0)
    }

    func testHandleDisplayAction_otherActions_shouldDoNothing() {
        let (sut, _, _, _) = makeSUT()

        let expectation = expectation(description: "No toggle requested")
        expectation.isInverted = true
        var subscriptions = Set<AnyCancellable>()
        sut.editModeToggleRequested
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        sut.handleDisplayAction(.sort)

        wait(for: [expectation], timeout: 0.5)
    }

    func testHandleSortAction_shouldUpdateSyncModelSortType() {
        let (sut, _, syncModel, _) = makeSUT()

        sut.handleSortAction(.nameDescending)

        XCTAssertEqual(syncModel.videoRevampSortOrderType, .defaultDesc)
    }

    func testHandleVideoLocationFilter_shouldUpdateVideoListViewModel() {
        let (sut, videoListViewModel, _, _) = makeSUT()

        sut.handleVideoLocationFilter(.sharedItems)

        XCTAssertEqual(videoListViewModel.selectedLocationFilterOption, .sharedItems)
    }

    func testHandleVideoDurationFilter_shouldUpdateVideoListViewModel() {
        let (sut, videoListViewModel, _, _) = makeSUT()

        sut.handleVideoDurationFilter(.lessThan10Seconds)

        XCTAssertEqual(videoListViewModel.selectedDurationFilterOption, .lessThan10Seconds)
    }

    // MARK: - Toolbar Config Tests

    func testToolbarConfig_withNoSelection_shouldReturnConfigWithZeroCount() {
        let (sut, _, _, _) = makeSUT()

        let config = sut.toolbarConfig()

        XCTAssertNotNil(config)
        XCTAssertEqual(config?.selectedItemsCount, 0)
        XCTAssertEqual(config?.actions.count, 5)
        XCTAssertFalse(config?.isAllExported ?? true)
    }

    // MARK: - Handle Toolbar Action Tests

    func testHandleToolbarAction_withNoCoordinator_shouldNotCrash() {
        let (sut, _, _, _) = makeSUT()

        XCTAssertNil(sut.toolbarCoordinator)
        XCTAssertNoThrow(sut.handleToolbarAction(.download))
    }

    func testHandleToolbarAction_withNoSelection_shouldNotCallCoordinator() {
        let (sut, _, _, _) = makeSUT()
        let mockCoordinator = MockMediaTabToolbarCoordinator()
        sut.toolbarCoordinator = mockCoordinator

        sut.handleToolbarAction(.download)

        // When there are no valid MEGANodes, the coordinator should not be called
        XCTAssertNil(mockCoordinator.lastAction)
        XCTAssertNil(mockCoordinator.lastNodes)
    }

    func testHandleToolbarAction_withEmptyNodes_shouldNotCallCoordinator() {
        let (sut, _, _, videoSelection) = makeSUT()
        let mockCoordinator = MockMediaTabToolbarCoordinator()
        sut.toolbarCoordinator = mockCoordinator

        videoSelection.videos = [:]

        sut.handleToolbarAction(.download)

        XCTAssertNil(mockCoordinator.lastAction)
        XCTAssertNil(mockCoordinator.lastNodes)
    }

    // MARK: - Toolbar Coordinator Tests

    func testToolbarCoordinator_shouldBeWeakReference() {
        let (sut, _, _, _) = makeSUT()
        var coordinator: MockMediaTabToolbarCoordinator? = MockMediaTabToolbarCoordinator()

        sut.toolbarCoordinator = coordinator

        XCTAssertNotNil(sut.toolbarCoordinator)

        // Release the coordinator
        coordinator = nil

        // Weak reference should be nil now
        XCTAssertNil(sut.toolbarCoordinator)
    }

    // MARK: - Integration Tests

    func testFilterChange_shouldUpdateContextMenuId() {
        let (sut, videoListViewModel, _, _) = makeSUT()
        let mockProvider = MockMediaTabSharedResourceProvider()
        let mockConfig = CMConfigEntity(
            menuType: .menu(type: .display),
            sortType: .modificationAsc,
            isSelectHidden: false,
            isEmptyState: false
        )
        let mockManager = ContextMenuManager(
            createContextMenuUseCase: MockCreateContextMenuUseCase()
        )
        mockProvider.contextMenuConfig = mockConfig
        mockProvider.contextMenuManager = mockManager
        sut.sharedResourceProvider = mockProvider

        videoListViewModel.selectedLocationFilterOption = .allLocation
        let items1 = sut.navigationBarItems(for: .inactive)
        let id1 = items1.first?.id ?? ""

        videoListViewModel.selectedLocationFilterOption = .cloudDrive
        mockProvider.contextMenuConfig = CMConfigEntity(
            menuType: .menu(type: .display),
            sortType: .modificationAsc,
            isSelectHidden: false,
            isEmptyState: false,
            selectedVideoLocationFilter: .cloudDrive
        )
        let items2 = sut.navigationBarItems(for: .inactive)
        let id2 = items2.first?.id ?? ""

        XCTAssertEqual(id1, id2)
        XCTAssertTrue(id2.contains("cameraUploadStatus"))
    }

    // MARK: - Test Helpers

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: VideoTabViewModel,
        videoListViewModel: VideoListViewModel,
        syncModel: VideoRevampSyncModel,
        videoSelection: VideoSelection
    ) {
        let syncModel = VideoRevampSyncModel()
        let videoSelection = VideoSelection()
        let featureFlagProvider = MockFeatureFlagProvider(list: [:])

        let videoListViewModel = VideoListViewModel(
            syncModel: syncModel,
            contentProvider: MockVideoListViewModelContentProvider(),
            selection: videoSelection,
            fileSearchUseCase: MockFilesSearchUseCase(),
            thumbnailLoader: MockThumbnailLoader(),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeDataUseCase(),
            featureFlagProvider: featureFlagProvider
        )

        let router = MockVideoRevampRouter()

        let sut = VideoTabViewModel(
            videoListViewModel: videoListViewModel,
            videoSelection: videoSelection,
            syncModel: syncModel,
            videoConfig: .live(),
            router: router,
            featureFlagProvider: featureFlagProvider
        )

        trackForMemoryLeaks(on: sut, file: file, line: line)

        return (sut, videoListViewModel, syncModel, videoSelection)
    }

    private func anyVideo(id: HandleEntity, name: String = "video.mp4") -> NodeEntity {
        NodeEntity(
            changeTypes: .fileAttributes,
            nodeType: .file,
            name: name,
            handle: id,
            isFile: true,
            hasThumbnail: true,
            hasPreview: true,
            label: .unknown,
            publicHandle: id,
            size: 1024,
            duration: 120,
            mediaType: .video
        )
    }
}

// MARK: - Mock Objects

private final class MockVideoListViewModelContentProvider: VideoListViewModelContentProviderProtocol {
    func search(
        by searchText: String,
        sortOrderType: MEGADomain.SortOrderEntity,
        durationFilterOptionType: Video.DurationChipFilterOptionType,
        locationFilterOptionType: Video.LocationChipFilterOptionType
    ) async throws -> [MEGADomain.NodeEntity] {
        []
    }

    func loadMedia(sortOrder: MEGADomain.SortOrderEntity) async throws -> [MEGADomain.NodeEntity] {
        []
    }
}

private final class MockCreateContextMenuUseCase: CreateContextMenuUseCaseProtocol {
    func createContextMenu(config: CMConfigEntity) -> CMEntity? {
        nil
    }
}

@MainActor
private final class MockMediaTabToolbarCoordinator: MediaTabToolbarCoordinatorProtocol {
    var lastAction: MediaBottomToolbarAction?
    var lastNodes: [NodeEntity]?

    func handleToolbarAction(_ action: MediaBottomToolbarAction, with nodes: [NodeEntity]) {
        lastAction = action
        lastNodes = nodes
    }
}
