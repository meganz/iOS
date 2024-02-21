import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import Search
import SearchMock
import XCTest

struct MockMEGANotificationUseCaseProtocol: MEGANotificationUseCaseProtocol {
    func relevantAndNotSeenAlerts() -> [UserAlertEntity]? { nil }
    
    func incomingContactRequest() -> [ContactRequestEntity] { [] }
    
    func observeUserAlerts(with callback: @escaping () -> Void) { }
    
    func observeUserContactRequests(with callback: @escaping () -> Void) { }
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
        
        init(
            // this may appear strange but view mode is a "bigger" enum that has mediaDiscovery/list/thumbnail
            // but PageLayout is a SearchResultsView concept which only supports list/thumbnail, hence they need to (and are) be
            // controlled separately
            defaultViewMode: ViewModePreferenceEntity = .list,
            defaultLayout: PageLayout = .list,
            node: NodeEntity
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
            
            sut = NodeBrowserViewModel(
                viewMode: defaultViewMode,
                searchResultsViewModel: .init(
                    resultsProvider: MockSearchResultsProviding(),
                    bridge: SearchBridge(
                        selection: { _ in },
                        context: { _, _ in },
                        resignKeyboard: {},
                        chipTapped: { _, _ in }
                    ),
                    config: .testConfig,
                    layout: defaultLayout,
                    showLoadingPlaceholderDelay: 0,
                    searchInputDebounceDelay: 0,
                    keyboardVisibilityHandler: MockKeyboardVisibilityHandler()
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
                config: .default,
                nodeSource: nodeSource,
                avatarViewModel: MyAvatarViewModel(
                    megaNotificationUseCase: MockMEGANotificationUseCaseProtocol(),
                    megaAvatarUseCase: MockMEGAAvatarUseCaseProtocol(),
                    megaAvatarGeneratingUseCase: MockMEGAAvatarGeneratingUseCaseProtocol()
                ), 
                viewModeSaver: { saver($0) },
                storageFullAlertViewModel: .init(router: MockStorageFullAlertViewRouting()),
                titleBuilder: { _, _ in Self.titleBuilderProvidedValue },
                onOpenUserProfile: {},
                onUpdateSearchBarVisibility: { _ in },
                onBack: {}, 
                onEditingChanged: { _ in }
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
}

extension NodeEntity {
    static var rootNode: NodeEntity {
        NodeEntity(name: "Cloud Drive", handle: 1)
    }
}
