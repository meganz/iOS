import Combine
import ConcurrencyExtras
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGAUIKit
import Search
import SearchMock
import XCTest

struct MockMEGANotificationUseCaseProtocol: MEGANotificationUseCaseProtocol {
    func relevantAndNotSeenAlerts() -> [UserAlertEntity]? { nil }
    
    func incomingContactRequest() -> [ContactRequestEntity] { [] }
    
    func observeUserAlerts(with callback: @escaping () -> Void) { }
    
    func observeUserContactRequests(with callback: @escaping () -> Void) { }
    
    func unreadNotificationIDs() async -> [NotificationIDEntity] { [] }
}

final class MockCloudDriveViewModeMonitoringService: CloudDriveViewModeMonitoring {
    lazy var viewModes: AsyncStream<ViewModePreferenceEntity> = {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.continuation = continuation
        }
    }()

    var continuation: AsyncStream<ViewModePreferenceEntity>.Continuation?
    var nodeSource: NodeSource
    var currentViewMode: ViewModePreferenceEntity

    init(nodeSource: NodeSource, currentViewMode: ViewModePreferenceEntity) {
        self.nodeSource = nodeSource
        self.currentViewMode = currentViewMode
    }
}

class NodeBrowserViewModelTests: XCTestCase {
    
    @MainActor
    class Harness {
        
        static let titleBuilderProvidedValue = "CD title"
        
        let sut: NodeBrowserViewModel
        var savedViewModes: [ViewModePreferenceEntity] = []
        var updateTransferWidgetHandler: () -> Void

        let nodesUpdateListener: any NodesUpdateListenerProtocol
        let cloudDriveViewModeMonitoringService: MockCloudDriveViewModeMonitoringService
        let nodeUseCase: MockNodeDataUseCase

        init(
            // this may appear strange but view mode is a "bigger" enum that has mediaDiscovery/list/thumbnail
            // but PageLayout is a SearchResultsView concept which only supports list/thumbnail, hence they need to (and are) be
            // controlled separately
            defaultViewMode: ViewModePreferenceEntity = .list,
            defaultLayout: PageLayout = .list,
            node: NodeEntity,
            updateTransferWidgetHandler: @escaping () -> Void = {},
            sortOrderProvider: @escaping () -> MEGADomain.SortOrderEntity = { .defaultAsc },
            onNodeStructureChanged: @escaping () -> Void = {},
            monitorInheritedSensitivityForNode: AnyAsyncThrowingSequence<Bool, any Error> = EmptyAsyncSequence()
                .eraseToAnyAsyncThrowingSequence(),
            sensitivityChangesForNode: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
        ) {
            let nodeSource = NodeSource.node { node }
            let expectedNodes = [
                node
            ]
            let nodeUpdatesPublisher = PassthroughSubject<[NodeEntity], Never>()
            let mediaDiscoveryUseCase = MockMediaDiscoveryUseCase(
                nodeUpdates: AnyPublisher(nodeUpdatesPublisher),
                nodes: expectedNodes,
                shouldReload: true
            )
            
            var saver: (ViewModePreferenceEntity) -> Void = {_ in }
            
            self.updateTransferWidgetHandler = updateTransferWidgetHandler
            self.nodesUpdateListener = MockSDKNodesUpdateListenerRepository.newRepo
            self.cloudDriveViewModeMonitoringService = MockCloudDriveViewModeMonitoringService(
                nodeSource: nodeSource,
                currentViewMode: defaultViewMode
            )

            self.nodeUseCase = MockNodeDataUseCase(
                nodes: [node],
                monitorInheritedSensitivityForNode: monitorInheritedSensitivityForNode,
                sensitivityChangesForNode: sensitivityChangesForNode
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
                    viewDisplayMode: .unknown
                ),
                mediaDiscoveryViewModel: .init(
                    contentMode: .library,
                    parentNodeProvider: { node },
                    sortOrder: .nameAscending,
                    isAutomaticallyShown: false,
                    delegate: MockMediaDiscoveryContentDelegate(),
                    analyticsUseCase: MockMediaDiscoveryAnalyticsUseCase(),
                    mediaDiscoveryUseCase: mediaDiscoveryUseCase,
                    contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase()
                ),
                warningViewModel: nil,
                upgradeEncouragementViewModel: nil,
                adsVisibilityViewModel: nil,
                config: .default,
                nodeSource: nodeSource,
                avatarViewModel: MyAvatarViewModel(
                    megaNotificationUseCase: MockMEGANotificationUseCaseProtocol(),
                    userImageUseCase: MockUserImageUseCase(),
                    megaHandleUseCase: MockMEGAHandleUseCase()
                ),
                noInternetViewModel: NoInternetViewModel(
                    networkMonitorUseCase: MockNetworkMonitorUseCase(),
                    networkConnectionStateChanged: { _ in }
                ),
                nodeSourceUpdatesListener: NewCloudDriveNodeSourceUpdatesListener(
                    originalNodeSource: .testNode,
                    nodeUpdatesListener: nodesUpdateListener
                ),
                nodesUpdateListener: nodesUpdateListener, 
                cloudDriveViewModeMonitoringService: cloudDriveViewModeMonitoringService, 
                nodeUseCase: nodeUseCase,
                viewModeSaver: { saver($0) },
                storageFullAlertViewModel: .init(router: MockStorageFullAlertViewRouting()),
                titleBuilder: { _, _ in Self.titleBuilderProvidedValue },
                onOpenUserProfile: {},
                onUpdateSearchBarVisibility: { _ in },
                onBack: {},
                onEditingChanged: { _ in },
                updateTransferWidgetHandler: updateTransferWidgetHandler,
                sortOrderProvider: sortOrderProvider, 
                onNodeStructureChanged: onNodeStructureChanged
            )
            
            saver = { self.savedViewModes.append($0) }
        }
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
        harness.nodesUpdateListener.onNodesUpdateHandler?(nodes)
        await fulfillment(of: [exp], timeout: 1.0)
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
        await assertViewMode(with: harness, expectedOrder: [.list, .list])
    }

    @MainActor
    func testUpdateViewModeIfNeeded_whenViewModeIsChanged_shouldReturnUpdatedValue() async {
        let harness = Harness(
            defaultViewMode: .list,
            node: NodeEntity(handle: 100)
        )
        await assertViewMode(with: harness, expectedOrder: [.list, .thumbnail])
    }
    
    @MainActor
    func testSortOrderChange() async {
        await withMainSerialExecutor {
            // given
            let harness = Harness(
                defaultViewMode: .list,
                node: NodeEntity(handle: 100)
            )
            
            harness.sut.cloudDriveContextMenuFactory = makeContextMenuFactory(nodeUseCase: harness.nodeUseCase, isSensitive: true)
            await Task.megaYield()
            
            let firstSortOrderExp = expectation(description: "Waiting for first sort order")
            
            // When we change the sortOrder `sut.updateContextMenu()` will produce 2 NodeBrowserContextMenuViewFactory objects, thus the 2 expected fulfilllment count
            let secondSortOrderExp = expectation(description: "Waiting for second sort order")
            secondSortOrderExp.expectedFulfillmentCount = 2
            var outputSortOrders = [MEGADomain.SortOrderEntity]()
            
            let cancellable = harness.sut.$contextMenuViewFactory
                .map { $0?.makeNavItemsFactory().sortOrder }
                .receive(on: DispatchQueue.main)
                .sink {
                    guard let sortOrder = $0 else { return }
                    outputSortOrders.append(sortOrder)
                    if outputSortOrders.count == 1 {
                        firstSortOrderExp.fulfill()
                    } else {
                        secondSortOrderExp.fulfill()
                    }
                }
            
            // when
            harness.sut.changeSortOrder(.nameAscending) // This doesn't trigger `updateContextMenu()`
            await fulfillment(of: [firstSortOrderExp], timeout: 1)
            
            // then
            XCTAssertEqual(outputSortOrders.compactMap { $0 }, [.defaultAsc])
            
            // and when
            harness.sut.changeSortOrder(.favourite) // This does trigger `updateContextMenu()`
            await fulfillment(of: [secondSortOrderExp], timeout: 1)
            
            // and then
            XCTAssertEqual(outputSortOrders.compactMap { $0 }, [.defaultAsc, .favouriteAsc, .favouriteAsc])
            
            cancellable.cancel()
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
    private func assertViewMode(with harness: Harness, expectedOrder: [ViewModePreferenceEntity]) async {
        await withMainSerialExecutor {
            let expectation = expectation(description: "wait for the view mode to update")
            var viewModes: [ViewModePreferenceEntity] = []
            let cancellable = harness
                .sut
                .$viewMode
                .sink { updatedViewMode in
                    viewModes.append(updatedViewMode)
                    if viewModes == expectedOrder {
                        expectation.fulfill()
                    }
                }

            await Task.megaYield()
            harness.cloudDriveViewModeMonitoringService.continuation?.yield(expectedOrder[1])
            await fulfillment(of: [expectation], timeout: 1.0)
            cancellable.cancel()
        }
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
            sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: .none),
            nodeUseCase: nodeUseCase
        )
    }
}

extension NodeEntity {
    static var rootNode: NodeEntity {
        NodeEntity(name: "Cloud Drive", handle: 1)
    }
}
