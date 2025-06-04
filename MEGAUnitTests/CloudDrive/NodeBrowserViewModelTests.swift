import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGAUIKit
import Search
import SearchMock
import SwiftUI
import XCTest

struct MockMEGANotificationUseCaseProtocol: MEGANotificationUseCaseProtocol {
    var userAlertsUpdates: AnyAsyncSequence<Void> { EmptyAsyncSequence().eraseToAnyAsyncSequence() }
    var userContactRequestsUpdates: AnyAsyncSequence<Void> { EmptyAsyncSequence().eraseToAnyAsyncSequence() }
    func relevantAndNotSeenAlerts() -> [UserAlertEntity]? { nil }
    func incomingContactRequest() -> [ContactRequestEntity] { [] }
    func unreadNotificationIDs() async -> [NotificationIDEntity] { [] }
}

final class MockCloudDriveViewModeMonitoringService: @unchecked Sendable, CloudDriveViewModeMonitoring {
    private var continuations: [AsyncStream<ViewModePreferenceEntity>.Continuation] = []
    private(set) var count = 0

    func updatedViewModes(
        with nodeSource: NodeSource,
        currentViewMode: ViewModePreferenceEntity
    ) -> AnyAsyncSequence<ViewModePreferenceEntity> {
        count += 1
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) {
            continuations.append($0)
        }
        .eraseToAnyAsyncSequence()
    }

    @MainActor
    func send(event: ViewModePreferenceEntity) {
        continuations.forEach { $0.yield(event) }
    }
}

class NodeBrowserViewModelTests: XCTestCase {
    
    @MainActor
    class Harness {
        
        static let titleBuilderProvidedValue = "CD title"
        
        let sut: NodeBrowserViewModel
        var savedViewModes: [ViewModePreferenceEntity] = []
        var updateTransferWidgetHandler: () -> Void

        let nodeUpdatesStream: AsyncStream<[NodeEntity]>
        let nodeUpdatesContinuation: AsyncStream<[NodeEntity]>.Continuation
        let cloudDriveViewModeMonitoringService: MockCloudDriveViewModeMonitoringService
        let nodeUseCase: MockNodeDataUseCase
        let tracker = MockTracker()
        let mediaDiscoveryViewModel: MediaDiscoveryContentViewModel

        init(
            // this may appear strange but view mode is a "bigger" enum that has mediaDiscovery/list/thumbnail
            // but PageLayout is a SearchResultsView concept which only supports list/thumbnail, hence they need to (and are) be
            // controlled separately
            defaultViewMode: ViewModePreferenceEntity = .list,
            defaultLayout: PageLayout = .list,
            node: NodeEntity,
            config: NodeBrowserConfig = .default,
            mockAccountStorageUseCase: MockAccountStorageUseCase = MockAccountStorageUseCase(),
            updateTransferWidgetHandler: @escaping () -> Void = {},
            sortOrderProvider: @escaping () -> MEGADomain.SortOrderEntity = { .defaultAsc },
            onNodeStructureChanged: @escaping () -> Void = {},
            monitorInheritedSensitivityForNode: AnyAsyncThrowingSequence<Bool, any Error> = EmptyAsyncSequence()
                .eraseToAnyAsyncThrowingSequence(),
            sensitivityChangesForNode: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
            tempWarningBannerViewModel: WarningBannerViewModel? = nil
        ) {
            let nodeSource = NodeSource.node { node }
            let expectedNodes = [
                node
            ]
            let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(
                nodeUpdates: [expectedNodes].async.eraseToAnyAsyncSequence(),
                nodes: expectedNodes,
                shouldReload: true
            )
            
            var saver: (ViewModePreferenceEntity) -> Void = {_ in }
            
            self.updateTransferWidgetHandler = updateTransferWidgetHandler
            (nodeUpdatesStream, nodeUpdatesContinuation) = AsyncStream<[NodeEntity]>.makeStream()
            let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: nodeUpdatesStream.eraseToAnyAsyncSequence())
            self.cloudDriveViewModeMonitoringService = MockCloudDriveViewModeMonitoringService()
            self.nodeUseCase = MockNodeDataUseCase(nodes: [node])

            mediaDiscoveryViewModel = .init(
                contentMode: .library,
                parentNodeProvider: { node },
                sortOrder: .nameAscending,
                isAutomaticallyShown: false,
                delegate: MockMediaDiscoveryContentDelegate(),
                analyticsUseCase: MockMediaDiscoveryAnalyticsUseCase(),
                mediaDiscoveryUseCase: mediaDiscoveryUseCase,
                sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase()
            )

            sut = NodeBrowserViewModel(
                viewMode: defaultViewMode,
                searchResultsViewModel: .init(
                    resultsProvider: MockSearchResultsProviding(),
                    bridge: SearchBridge(
                        selection: { _ in },
                        context: { _, _ in },
                        resignKeyboard: {},
                        chipTapped: { _, _ in },
                        sortingOrder: { .nameAscending }
                    ),
                    config: .testConfig,
                    layout: defaultLayout,
                    showLoadingPlaceholderDelay: 0,
                    searchInputDebounceDelay: 0,
                    keyboardVisibilityHandler: MockKeyboardVisibilityHandler(),
                    viewDisplayMode: .unknown,
                    isSearchByNodeTagsFeatureEnabled: true,
                    listHeaderViewModel: nil,
                    isSelectionEnabled: true
                ),
                mediaDiscoveryViewModel: mediaDiscoveryViewModel,
                warningViewModel: nil,
                temporaryWarningViewModel: tempWarningBannerViewModel,
                upgradeEncouragementViewModel: nil,
                adsVisibilityViewModel: nil,
                config: config, // Pass the modified config here
                nodeSource: nodeSource,
                avatarViewModel: MyAvatarViewModel(
                    megaNotificationUseCase: MockMEGANotificationUseCaseProtocol(),
                    userImageUseCase: MockUserImageUseCase(),
                    megaHandleUseCase: MockMEGAHandleUseCase()
                ),
                noInternetViewModel: LegacyNoInternetViewModel(
                    networkMonitorUseCase: MockNetworkMonitorUseCase(),
                    networkConnectionStateChanged: { _ in }
                ),
                nodeSourceUpdatesListener: NewCloudDriveNodeSourceUpdatesListener(
                    originalNodeSource: .testNode,
                    nodeUpdatesProvider: MockNodeUpdatesProvider()
                ),
                nodeUpdatesProvider: nodeUpdatesProvider,
                cloudDriveViewModeMonitoringService: cloudDriveViewModeMonitoringService,
                nodeUseCase: nodeUseCase,
                sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                    monitorInheritedSensitivityForNode: monitorInheritedSensitivityForNode,
                    sensitivityChangesForNode: sensitivityChangesForNode
                ),
                accountStorageUseCase: mockAccountStorageUseCase, // Inject the mock here
                tracker: tracker,
                viewModeSaver: { saver($0) },
                storageFullModalAlertViewRouter: MockStorageFullModalAlertViewRouter(),
                titleBuilder: { _, _ in Self.titleBuilderProvidedValue },
                onOpenUserProfile: {},
                onUpdateSearchBarVisibility: { _ in },
                onBack: {},
                onCancel: {},
                onEditingChanged: { _ in },
                updateTransferWidgetHandler: updateTransferWidgetHandler,
                sortOrderProvider: sortOrderProvider,
                onNodeStructureChanged: onNodeStructureChanged
            )
            
            saver = { self.savedViewModes.append($0) }
        }
        
        func invokeNodeUpdates(_ updatedNodes: [NodeEntity]) {
            nodeUpdatesContinuation.yield(updatedNodes)
        }
    }
    
    @MainActor
    func testOnViewAppear_shouldTrackCloudDriveScreenEvent() {
        let harness = Harness(node: .init())
        harness.sut.onViewAppear()
        XCTAssertTrue(
            harness.tracker.trackedEventIdentifiers.contains(where: { $0.eventName == CloudDriveScreenEvent().eventName })
        )
    }
    
    @MainActor
    func testRefreshTitle_readUsesTitleBuild_toSetTitle() {
        let harness = Harness(node: .rootNode)
        harness.sut.refreshTitle()
        XCTAssertEqual(harness.sut.title, Harness.titleBuilderProvidedValue)
    }
    
    @MainActor
    func testViewMode_changingToList_setsSearchResultsViewModelLayout() {
        let harness = Harness(
            defaultViewMode: .thumbnail,
            defaultLayout: .thumbnail,
            node: .rootNode
        )
        harness.sut.viewMode = .list
        XCTAssertEqual(harness.sut.searchResultsViewModel.layout, .list)
    }
    
    @MainActor
    func testViewMode_changingToThumbnail_setsSearchResultsViewModelLayout() {
        let harness = Harness(
            defaultViewMode: .list,
            defaultLayout: .list,
            node: .rootNode
        )
        harness.sut.viewMode = .thumbnail
        XCTAssertEqual(harness.sut.searchResultsViewModel.layout, .thumbnail)
    }
    
    @MainActor
    func testViewMode_changingValue_thumbnail_callsViewModeSaver() {
        let harness = Harness(
            defaultViewMode: .list,
            defaultLayout: .list,
            node: .rootNode
        )
        harness.sut.viewMode = .thumbnail
        XCTAssertEqual(harness.savedViewModes, [.thumbnail])
    }
    
    @MainActor func testViewMode_changingValue_list_callsViewModeSaver() {
        let harness = Harness(
            defaultViewMode: .list,
            defaultLayout: .list,
            node: .rootNode
        )
        harness.sut.viewMode = .mediaDiscovery
        XCTAssertEqual(harness.savedViewModes, [.mediaDiscovery])
    }
    
    @MainActor func testViewMode_changingValue_mediaDiscovery_callsViewModeSaver() {
        let harness = Harness(
            defaultViewMode: .thumbnail,
            defaultLayout: .thumbnail,
            node: .rootNode
        )
        harness.sut.viewMode = .list
        XCTAssertEqual(harness.savedViewModes, [.list])
    }
    
    @MainActor
    func testViewMode_changingValue_mediaDiscovery_mediaDiscoveryViewNotNil() {
        let harness = Harness(
            defaultViewMode: .thumbnail,
            defaultLayout: .thumbnail,
            node: .rootNode
        )
        XCTAssertNil(harness.sut.viewModeAwareMediaDiscoveryViewModel)
        harness.sut.viewMode = .mediaDiscovery
        XCTAssertNotNil(harness.sut.viewModeAwareMediaDiscoveryViewModel)
    }

    @MainActor
    func testViewState_whenEditing_shouldChangeToEditMode() {
        let harness = Harness(node: .init())
        harness.sut.toggleSelection()
        XCTAssertTrue(harness.sut.editing)
        guard case .editing = harness.sut.viewState else {
            XCTFail("view state should be editing")
            return
        }
    }
    
    @MainActor
    func testViewState_whenToggleSelectionToTrue_viewStateShouldBeInEditingState() {
        // given
        let harness = Harness(node: .init())
        
        // when
        harness.sut.setEditMode(true)
        
        // then
        XCTAssertTrue(harness.sut.editing)
        guard case .editing = harness.sut.viewState else {
            XCTFail("view state should be editing")
            return
        }
    }
    
    @MainActor func testViewState_whenToggleSelectionToFalse_viewStateShouldBeInRegularState() {
        // given
        let harness = Harness(node: .init())
        
        // when
        harness.sut.setEditMode(false)
        
        // then
        XCTAssertFalse(harness.sut.editing)
        guard case .regular = harness.sut.viewState else {
            XCTFail("view state should be regular")
            return
        }
    }

    @MainActor
    func testChangeSortOrder_forAllCases_shouldMatchExpectedResult() {
        [
            (.nameAscending, .defaultAsc),
            (.nameDescending, .defaultDesc),
            (.largest, .sizeDesc),
            (.smallest, .sizeAsc),
            (.newest, .modificationDesc),
            (.oldest, .modificationAsc),
            (.label, .labelAsc),
            (.favourite, .favouriteAsc)
        ].forEach { (sortOrderType, sortOrderEntity) in
            assertChangeSortOrder(
                with: sortOrderType,
                expectedSortOrderEntity: sortOrderEntity
            )
        }
    }

    @MainActor
    func testInitForSortOrder_forAllCases_shouldMatchExpectedResult() {
        MEGADomain.SortOrderEntity.allValid.forEach { sortOrder in
            let harness = Harness(node: .init(), sortOrderProvider: { sortOrder })
            XCTAssertEqual(
                harness.sut.sortOrder,
                sortOrder,
                "Expected \(sortOrder) but received \(harness.sut.sortOrder)"
            )
        }
    }

    @MainActor
    func testUpdateTransferWidget() {
        var didUpdateTransferWidget = false
        let harness = Harness(node: .init(), updateTransferWidgetHandler: { didUpdateTransferWidget = true })
        harness.sut.onViewAppear()
        XCTAssertTrue(didUpdateTransferWidget)
    }

    @MainActor
    func testEditMode_whenChangingTheEditing_shouldAlsoChangeTheEditMode() {
        let harness = Harness(node: .init())
        let exp = expectation(description: "Wait for editing mode to be enabled")
        let editModeSubscription = harness
            .sut
            .$editMode
            .dropFirst()
            .sink { editMode in
                guard editMode.isEditing else {
                    XCTFail("Edit mode should be enabled")
                    return
                }

                exp.fulfill()
            }
        harness.sut.editing = true
        wait(for: [exp], timeout: 1.0)
        editModeSubscription.cancel()
    }

    @MainActor
    func testOnNodesUpdateHandler_whenANodeIsRemovedFromTree_shouldInvokeOnRemove() async {
        let exp = expectation(description: "Wait for on remove to be triggered")
        let nodes: [NodeEntity] = [
            .init(),
            .init(changeTypes: [.removed])
        ]
        
        let harness = Harness(node: nodes[1], onNodeStructureChanged: exp.fulfill)
        
        harness.invokeNodeUpdates(nodes)
        
        await fulfillment(of: [exp], timeout: 10.0)
    }

    @MainActor
    func testMatches_whenNodeSourceIsSet_shouldMatchTheSource() {
        let node = NodeEntity(handle: 100)
        let harness = Harness(node: node)
        XCTAssertTrue(harness.sut.parentNodeMatches(node: node))
    }

    @MainActor
    func testUpdateViewModeIfNeeded_whenViewModeIsNotChanged_shouldReturnOriginalValue() async {
        let harness = Harness(defaultViewMode: .list, node: NodeEntity(handle: 100))
        await assertViewMode(with: harness, originalViewMode: .list, updatedViewMode: .list)
    }

    @MainActor
    func testUpdateViewModeIfNeeded_whenViewModeIsChanged_shouldReturnUpdatedValue() async {
        let harness = Harness(
            defaultViewMode: .list,
            node: NodeEntity(handle: 100)
        )
        await assertViewMode(with: harness, originalViewMode: .list, updatedViewMode: .thumbnail)
    }
    
    @MainActor
    func testSortOrderChange_forList() async {
        // given
        let harness = Harness(
            defaultViewMode: .list,
            node: NodeEntity(handle: 100)
        )

        harness.sut.cloudDriveContextMenuFactory = makeContextMenuFactory(nodeUseCase: harness.nodeUseCase, isSensitive: true)
        await waitForContextMenuSortOrderChange(.defaultAsc, in: harness) // wait for the default value
        harness.sut.changeSortOrder(.favourite) // update sort order
        await waitForContextMenuSortOrderChange(.favouriteAsc, in: harness) // wait for the updated value
    }

    @MainActor
    func testSortOrderChange_forMediaDiscovery() async {
        // given
        for sortOrder in [SortOrderType.newest, .oldest] {
            let harness = Harness(
                defaultViewMode: .mediaDiscovery,
                node: NodeEntity(handle: 100)
            )

            harness.sut.cloudDriveContextMenuFactory = self.makeContextMenuFactory(nodeUseCase: harness.nodeUseCase, isSensitive: true)
            harness.sut.changeSortOrder(sortOrder) // change sort order
            try? await Task.sleep(nanoseconds: 10_000_000)
            XCTAssertEqual(harness.sut.sortOrder, .defaultAsc) // the actual sortOrder doesn't change with .mediaDiscovery view mode
            XCTAssertEqual(harness.mediaDiscoveryViewModel.sortOrder, sortOrder)

//            await waitForContextMenuSortOrderChange(sortOrder.toSortOrderEntity(), in: harness)
        }
    }

    @MainActor
    func testCloudDriveContextMenuFactory_whenSensitiveNodeIsTrue_shouldUpdateMenuViewFactoryWithHiddenAsTrue() async {
        await assertCloudDriveContextMenuFactory(withNodeAsSensitive: true)
    }

    @MainActor
    func testCloudDriveContextMenuFactory_whenSensitiveNodeIsFalse_shouldUpdateMenuViewFactoryWithHiddenAsFalse() async {
        await assertCloudDriveContextMenuFactory(withNodeAsSensitive: false)
    }

    @MainActor
    func assertCloudDriveContextMenuFactory(withNodeAsSensitive isSensitive: Bool) async {
        let node = NodeEntity(handle: 100)
        let harness = Harness(node: node)

        // Making sure that the async sequence is created
        while harness.cloudDriveViewModeMonitoringService.count != 1 {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        let exp = expectation(description: "wait for refresh menu to trigger")

        let cancellable = harness.sut.$contextMenuViewFactory.sink { updatedFactory in
            if updatedFactory?.makeNavItemsFactory().isHidden == isSensitive {
                exp.fulfill()
            }
        }

        harness.sut.cloudDriveContextMenuFactory = makeContextMenuFactory(nodeUseCase: harness.nodeUseCase, isSensitive: isSensitive)

        await fulfillment(of: [exp], timeout: 1.0)
        cancellable.cancel()
    }

    @MainActor
    func testListenToNodeSensitivityChanges_whenNodeIsMarkedSensitiveDueToInheritedSensitivityChanges_shouldTriggerUpdate() async {
        await assertListenToNodeSensitivityChangesWhenInheritedSensitivityChanges(
            initialSensitivityState: false,
            updatedSensitivityState: true
        )
    }

    @MainActor
    func testListenToNodeSensitivityChanges_whenNodeIsMarkedInSensitiveDueToInheritedSensitivityChanges_shouldTriggerUpdate() async {
        await assertListenToNodeSensitivityChangesWhenInheritedSensitivityChanges(
            initialSensitivityState: true,
            updatedSensitivityState: false
        )
    }

    @MainActor
    func testListenToNodeSensitivityChanges_whenNodeIsMarkedSensitiveDueToSensitivityChangesForNode_shouldTriggerUpdate() async {
        await assertListenToNodeSensitivityChangesWhenSensitivityChangesForNode(
            initialSensitivityState: false,
            updatedSensitivityState: true
        )
    }

    @MainActor
    func testListenToNodeSensitivityChanges_whenNodeIsMarkedInSensitiveDueToSensitivityChangesForNode_shouldTriggerUpdate() async {
        await assertListenToNodeSensitivityChangesWhenSensitivityChangesForNode(
            initialSensitivityState: false,
            updatedSensitivityState: true
        )
    }
    
    @MainActor
    func testMonitorStorageStatusUpdates_withCustomConfig_shouldUpdateCurrentBanner() async {
        let expectedStatusUpdate: StorageStatusEntity = .full
        let asyncStream = makeAsyncStream(for: [])

        let mockAccountStorageUseCase = MockAccountStorageUseCase(
            onStorageStatusUpdates: asyncStream,
            currentStorageStatus: .full
        )
        
        var config = NodeBrowserConfig.default
        config.warningViewModel = WarningBannerViewModel(warningType: .fullStorageOverQuota)
        config.displayMode = .cloudDrive

        let harness = Harness(node: .init(), config: config, mockAccountStorageUseCase: mockAccountStorageUseCase)
        
        harness.sut.onViewAppear()
        
        let expectation = XCTestExpectation(description: "Wait for all status updates")
        
        Task {
            for await status in asyncStream {
                XCTAssertTrue(status == expectedStatusUpdate)
            }
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertEqual(harness.sut.currentBannerViewModel?.warningType, .fullStorageOverQuota)
    }
    
    @MainActor
    func testMonitorStorageStatusUpdates_withDefaultConfig_shouldUpdateCurrentBanner() async {
        let mockAccountStorageUseCase = MockAccountStorageUseCase(
            onStorageStatusUpdates: makeAsyncStream(for: []),
            currentStorageStatus: .full
        )
        let tempWarningBannerVM = WarningBannerViewModel(warningType: .fullStorageOverQuota)
        
        var config = NodeBrowserConfig.default
        config.displayMode = .cloudDrive
        
        let harness = Harness(
            node: .init(),
            config: config,
            mockAccountStorageUseCase: mockAccountStorageUseCase,
            tempWarningBannerViewModel: tempWarningBannerVM
        )
        
        harness.sut.onViewAppear()
    
        XCTAssertEqual(harness.sut.currentBannerViewModel?.warningType, tempWarningBannerVM.warningType)
    }
    
    @MainActor
    private func makeHarness(
        shouldShowStorageBanner: Bool = true,
        isFromSharedItem: Bool = false,
        currentStatus: StorageStatusEntity = .noStorageProblems,
        displayMode: DisplayMode? = nil
    ) -> (Harness, MockAccountStorageUseCase) {
        let mockAccountStorageUseCase = MockAccountStorageUseCase(shouldShowStorageBanner: shouldShowStorageBanner)
        var config = NodeBrowserConfig.default
        config.isFromSharedItem = isFromSharedItem
        config.displayMode = displayMode
        return (
            Harness(
                node: .init(),
                config: config,
                mockAccountStorageUseCase: mockAccountStorageUseCase
            ), mockAccountStorageUseCase
        )
    }
    
    @MainActor
    func testUpdateTemporaryBanner_whenStorageStatusTransitions_shouldDisplayCorrectBannersOrRemoveThem() async {
        let (harness, _) = makeHarness()
        
        harness.sut.updateTemporaryBanner(status: .almostFull)
        
        XCTAssertEqual(harness.sut.currentBannerViewModel?.warningType, .almostFullStorageOverQuota)
        
        harness.sut.updateTemporaryBanner(status: .full)
        
        XCTAssertEqual(harness.sut.currentBannerViewModel?.warningType, .fullStorageOverQuota)
        
        harness.sut.updateTemporaryBanner(status: .noStorageProblems)
        
        XCTAssertNil(harness.sut.currentBannerViewModel)
    }
    
    @MainActor
    func testRefreshStorageStatus_whenStorageStatusChanges_shouldUpdateBannerVisibility() async {
        let (harness, mockAccountStorageUseCase) = makeHarness(displayMode: .cloudDrive)
        
        mockAccountStorageUseCase._currentStorageStatus = .almostFull
        harness.sut.refreshStorageBanners()
        
        XCTAssertEqual(harness.sut.currentBannerViewModel?.warningType, .almostFullStorageOverQuota)
        
        mockAccountStorageUseCase._currentStorageStatus = .full
        harness.sut.refreshStorageBanners()
        
        XCTAssertEqual(harness.sut.currentBannerViewModel?.warningType, .fullStorageOverQuota)
        
        mockAccountStorageUseCase._currentStorageStatus = .noStorageProblems
        harness.sut.refreshStorageBanners()
        
        XCTAssertNil(harness.sut.currentBannerViewModel)
    }
    
    @MainActor
    func testRefreshStorageStatus_withSharedItemConfig_shouldNotDisplayBanner() {
        let (harness, _) = makeHarness(currentStatus: .full)
        
        harness.sut.refreshStorageBanners()
        
        XCTAssertNil(harness.sut.currentBannerViewModel, "No banner should be shown for shared items.")
    }
    
    @MainActor
    func testCurrentBannerViewModel_withCloudDriveDisplayMode_shouldDisplayBanner() async {
        let (harness, mockAccountStorageUseCase) = makeHarness(displayMode: .cloudDrive)
        
        mockAccountStorageUseCase._currentStorageStatus = .almostFull
        harness.sut.refreshStorageBanners()
        
        XCTAssertEqual(harness.sut.currentBannerViewModel?.warningType, .almostFullStorageOverQuota)
    }
    
    @MainActor
    func testCurrentBannerViewModel_withBackupDisplayMode_shouldDisplayBanner() async {
        let (harness, mockAccountStorageUseCase) = makeHarness(displayMode: .cloudDrive)
        
        mockAccountStorageUseCase._currentStorageStatus = .full
        harness.sut.refreshStorageBanners()
        
        XCTAssertEqual(harness.sut.currentBannerViewModel?.warningType, .fullStorageOverQuota)
    }
    
    @MainActor
    func testCurrentBannerViewModel_withNonCloudDriveDisplayModes_shouldNotDisplayBanner() async {
        let nonCloudDriveDisplayModes: [DisplayMode] = [.rubbishBin, .sharedItem, .nodeInfo, .nodeVersions, .folderLink, .fileLink, .nodeInsideFolderLink, .recents, .publicLinkTransfers, .transfers, .transfersFailed, .chatAttachment, .chatSharedFiles, .previewDocument, .textEditor, .backup, .mediaDiscovery, .photosFavouriteAlbum, .photosAlbum, .photosTimeline, .previewPdfPage, .albumLink, .videoPlaylistContent
        ]
        
        for displayMode in nonCloudDriveDisplayModes {
            assertNoBannerIsDisplayed(for: displayMode)
        }
    }
    
    @MainActor
    private func assertNoBannerIsDisplayed(for displayMode: DisplayMode) {
        let (harness, _) = makeHarness(
            shouldShowStorageBanner: true,
            currentStatus: .almostFull,
            displayMode: displayMode
        )
        harness.sut.onViewAppear()
        XCTAssertNil(harness.sut.currentBannerViewModel, "No banner should be shown for \(displayMode).")
    }

    @MainActor
    func testUpdatedViewModesTask_whenUpdatedMultipleTimes_shouldCancelPreviouslyCreatedTasks() async {
        let harness = Harness(node: .init())
        harness.sut.viewMode = .thumbnail
        harness.sut.viewMode = .list
        harness.sut.viewMode = .thumbnail
        harness.sut.viewMode = .list
        harness.sut.viewMode = .thumbnail
        harness.sut.viewMode = .list

        // Making sure that the async sequence is created
        while harness.cloudDriveViewModeMonitoringService.count != 7 {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        let expectation = expectation(description: "wait for view mode to be updated")
        let cancellable = harness
            .sut
            .$viewMode
            .dropFirst()
            .sink { viewMode in
                if viewMode == .thumbnail {
                    expectation.fulfill()
                }
            }

        harness.cloudDriveViewModeMonitoringService.send(event: .thumbnail)
        await fulfillment(of: [expectation], timeout: 2.0)
        cancellable.cancel()
    }

    private func makeAsyncStream(for updates: [StorageStatusEntity]) -> AnyAsyncSequence<StorageStatusEntity> {
        AsyncStream { continuation in
            for update in updates {
                continuation.yield(update)
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
    }
    
    @MainActor
    private func assertListenToNodeSensitivityChangesWhenSensitivityChangesForNode(
        initialSensitivityState: Bool,
        updatedSensitivityState: Bool
    ) async {
        await assertListenToNodeSensitivityChanges(
            initialSensitivityState: initialSensitivityState,
            updatedSensitivityState: updatedSensitivityState
        ) { node in
            let sensitivityChangesForNode = SingleItemAsyncSequence(item: true)
                .eraseToAnyAsyncSequence()
            return Harness(node: node, sensitivityChangesForNode: sensitivityChangesForNode)
        }
    }

    @MainActor
    private func assertListenToNodeSensitivityChangesWhenInheritedSensitivityChanges(
        initialSensitivityState: Bool,
        updatedSensitivityState: Bool
    ) async {
        await assertListenToNodeSensitivityChanges(
            initialSensitivityState: initialSensitivityState,
            updatedSensitivityState: updatedSensitivityState
        ) { node in
            let monitorInheritedSensitivityForNode = SingleItemAsyncSequence(item: true)
                .eraseToAnyAsyncThrowingSequence()
            return Harness(node: node, monitorInheritedSensitivityForNode: monitorInheritedSensitivityForNode)
        }
    }

    @MainActor
    private func assertListenToNodeSensitivityChanges(
        initialSensitivityState: Bool,
        updatedSensitivityState: Bool,
        makeHarness: (NodeEntity) -> Harness
    ) async {
        let node = NodeEntity(handle: 100, isMarkedSensitive: initialSensitivityState)
        let updatedNode = NodeEntity(handle: 100, isMarkedSensitive: updatedSensitivityState)
        let harness = makeHarness(node)

        let exp = expectation(description: "Wait for node source to update")
        var updatedNodeSource: NodeSource?
        harness.nodeUseCase.nodes = [updatedNode]
        let cancellable = harness
            .sut
            .$nodeSource
            .dropFirst()
            .sink { nodeSource in
                updatedNodeSource = nodeSource
                exp.fulfill()
            }
        harness.sut.onViewAppear()
        await fulfillment(of: [exp], timeout: 1.0)
        cancellable.cancel()
        XCTAssertEqual(updatedNodeSource?.parentNode?.isMarkedSensitive, updatedSensitivityState)
    }

    @MainActor
    private func assertViewMode(
        with harness: Harness,
        originalViewMode: ViewModePreferenceEntity,
        updatedViewMode: ViewModePreferenceEntity
    ) async {
        let expectation = expectation(description: "wait for the view mode to update")
        let cancellable = harness
            .sut
            .$viewMode
            .dropFirst()
            .sink { viewMode in
                if viewMode == updatedViewMode {
                    expectation.fulfill()
                }
            }

        Task.detached {
            await harness.cloudDriveViewModeMonitoringService.send(event: updatedViewMode)
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        cancellable.cancel()
    }

    @MainActor
    private func waitForContextMenuSortOrderChange(_ sortOrder: MEGADomain.SortOrderEntity, in harness: Harness) async {
        let exp = expectation(description: "Wait for the context menu sort order to update")

        let cancellable = harness.sut.$contextMenuViewFactory
            .map { $0?.makeNavItemsFactory().sortOrder }
            .receive(on: DispatchQueue.main)
            .removeDuplicates(by: {
                switch ($0, $1) {
                case (sortOrder, sortOrder):
                    return true
                default:
                    return false
                }
            })
            .sink {
                if $0 == sortOrder {
                    exp.fulfill()
                }
            }

        await fulfillment(of: [exp], timeout: 1)
        cancellable.cancel()
    }

    @MainActor private func assertChangeSortOrder(
        with sortOrderType: SortOrderType,
        expectedSortOrderEntity: MEGADomain.SortOrderEntity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let harness = Harness(node: .init())
        harness.sut.changeSortOrder(sortOrderType)
        guard case expectedSortOrderEntity = harness.sut.sortOrder else {
            XCTFail(
                "Expected \(expectedSortOrderEntity) but returned \(harness.sut.sortOrder)",
                file: file,
                line: line
            )
            return
        }
    }
    
    private func makeContextMenuFactory(
        nodeUseCase: some NodeUseCaseProtocol,
        isSensitive: Bool
    ) -> CloudDriveContextMenuFactory {
        CloudDriveContextMenuFactory(
            config: NodeBrowserConfig(),
            contextMenuManager: ContextMenuManager(createContextMenuUseCase: MockCreateContextMenuUseCase()),
            contextMenuConfigFactory: CloudDriveContextMenuConfigFactory(
                backupsUseCase: MockBackupsUseCase(),
                nodeUseCase: nodeUseCase
            ),
            nodeSensitivityChecker: MockNodeSensitivityChecker(isSensitive: isSensitive),
            nodeUseCase: nodeUseCase
        )
    }
}

extension NodeEntity {
    static var rootNode: NodeEntity {
        NodeEntity(name: "Cloud Drive", handle: 1)
    }
}
