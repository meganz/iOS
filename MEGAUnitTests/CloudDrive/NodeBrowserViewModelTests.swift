import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
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

struct MockMEGAAvatarUseCaseProtocol: MEGAAvatarUseCaseProtocol {
    func loadRemoteAvatarImage(completion: @escaping (UIImage?) -> Void) {}
    
    func getCachedAvatarImage() -> UIImage? { nil }
    
    func loadCachedAvatarImage(completion: @escaping (UIImage?) -> Void) { }
}

struct MockMEGAAvatarGeneratingUseCaseProtocol: MEGAAvatarGeneratingUseCaseProtocol {
    func avatarName() -> String? { nil }
    
    func avatarBackgroundColorHex() -> String? { nil }
}

class NodeBrowserViewModelTests: XCTestCase {
    
    class Harness {
        
        static let titleBuilderProvidedValue = "CD title"
        
        let sut: NodeBrowserViewModel
        var savedViewModes: [ViewModePreferenceEntity] = []
        var updateTransferWidgetHandler: () -> Void

        let nodesUpdateListener: any NodesUpdateListenerProtocol

        init(
            // this may appear strange but view mode is a "bigger" enum that has mediaDiscovery/list/thumbnail
            // but PageLayout is a SearchResultsView concept which only supports list/thumbnail, hence they need to (and are) be
            // controlled separately
            defaultViewMode: ViewModePreferenceEntity = .list,
            defaultLayout: PageLayout = .list,
            node: NodeEntity,
            updateTransferWidgetHandler: @escaping () -> Void = {},
            sortOrderProvider: @escaping () -> MEGADomain.SortOrderEntity = { .defaultAsc },
            onNodeStructureChanged: @escaping () -> Void = {}
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
                    mediaDiscoveryUseCase: mediaDiscoveryUseCase
                ),
                warningViewModel: nil,
                upgradeEncouragementViewModel: nil,
                adsVisibilityViewModel: nil,
                config: .default,
                nodeSource: nodeSource,
                avatarViewModel: MyAvatarViewModel(
                    megaNotificationUseCase: MockMEGANotificationUseCaseProtocol(),
                    megaAvatarUseCase: MockMEGAAvatarUseCaseProtocol(),
                    megaAvatarGeneratingUseCase: MockMEGAAvatarGeneratingUseCaseProtocol()
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
    
    func testRefreshTitle_readUsesTitleBuild_toSetTitle() {
        let harness = Harness(node: .rootNode)
        harness.sut.refreshTitle()
        XCTAssertEqual(harness.sut.title, Harness.titleBuilderProvidedValue)
    }
    
    func testViewMode_changingToList_setsSearchResultsViewModelLayout() {
        let harness = Harness(
            defaultViewMode: .thumbnail,
            defaultLayout: .thumbnail,
            node: .rootNode
        )
        harness.sut.viewMode = .list
        XCTAssertEqual(harness.sut.searchResultsViewModel.layout, .list)
    }
    
    func testViewMode_changingToThumbnail_setsSearchResultsViewModelLayout() {
        let harness = Harness(
            defaultViewMode: .list,
            defaultLayout: .list,
            node: .rootNode
        )
        harness.sut.viewMode = .thumbnail
        XCTAssertEqual(harness.sut.searchResultsViewModel.layout, .thumbnail)
    }
    
    func testViewMode_changingValue_thumbnail_callsViewModeSaver() {
        let harness = Harness(
            defaultViewMode: .list,
            defaultLayout: .list,
            node: .rootNode
        )
        harness.sut.viewMode = .thumbnail
        XCTAssertEqual(harness.savedViewModes, [.thumbnail])
    }
    
    func testViewMode_changingValue_list_callsViewModeSaver() {
        let harness = Harness(
            defaultViewMode: .list,
            defaultLayout: .list,
            node: .rootNode
        )
        harness.sut.viewMode = .mediaDiscovery
        XCTAssertEqual(harness.savedViewModes, [.mediaDiscovery])
    }
    
    func testViewMode_changingValue_mediaDiscovery_callsViewModeSaver() {
        let harness = Harness(
            defaultViewMode: .thumbnail,
            defaultLayout: .thumbnail,
            node: .rootNode
        )
        harness.sut.viewMode = .list
        XCTAssertEqual(harness.savedViewModes, [.list])
    }
    
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

    func testViewState_whenEditing_shouldChangeToEditMode() {
        let harness = Harness(node: .init())
        harness.sut.toggleSelection()
        XCTAssertTrue(harness.sut.editing)
        guard case .editing = harness.sut.viewState else {
            XCTFail("view state should be editing")
            return
        }
    }
    
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
    
    func testViewState_whenToggleSelectionToFalse_viewStateShouldBeInRegularState() {
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

    func testUpdateTransferWidget() {
        var didUpdateTransferWidget = false
        let harness = Harness(node: .init(), updateTransferWidgetHandler: { didUpdateTransferWidget = true })
        harness.sut.onViewAppear()
        XCTAssertTrue(didUpdateTransferWidget)
    }

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

    func testMatches_whenNodeSourceIsSet_shouldMatchTheSource() {
        let node = NodeEntity(handle: 100)
        let harness = Harness(node: node)
        XCTAssertTrue(harness.sut.parentNodeMatches(node: node))
    }

    private func assertChangeSortOrder(
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
}

extension NodeEntity {
    static var rootNode: NodeEntity {
        NodeEntity(name: "Cloud Drive", handle: 1)
    }
}
