import Combine
import ContentLibraries
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPhotos
import MEGAPreference
import MEGAPreferenceMocks
import SwiftUI
import Testing

struct MediaTabViewModelTests {
    
    @MainActor
    @Test
    func editModeRequested() async throws {
        let contentViewModel = MockMediaTabContentViewModel()
        let sut = Self.makeSUT(
            tabViewModels: [.timeline: contentViewModel]
        )
        #expect(sut.editMode == .inactive)
        
        contentViewModel.editModeToggleRequested.send()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(sut.editMode == .active)
    }
    
    @MainActor
    @Test
    func navigationBarUpdatePublisher() async throws {
        let contentViewModel = MockMediaTabContentViewModel()
        let sut = Self.makeSUT(
            tabViewModels: [.timeline: contentViewModel]
        )
        
        #expect(sut.navigationBarItemViewModels.isEmpty)
        
        let expectedItems = [
            NavigationBarItemViewModel(id: "test", placement: .trailing, type: .textButton(text: "Button", action: {}))
        ]
        contentViewModel.itemViewModels = expectedItems
        contentViewModel.navigationBarUpdateSubject.send()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(sut.navigationBarItemViewModels == expectedItems)
    }
    
    @MainActor
    @Test
    func navigationTitleUpdates() async throws {
        let expectedTitle = "Updated title"
        let contentViewModel = MockMediaTabContentViewModel()
        let sut = Self.makeSUT(
            tabViewModels: [.timeline: contentViewModel]
        )
        
        contentViewModel.titleUpdateSubject.send(expectedTitle)
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(sut.navigationTitle == expectedTitle)
    }
    
    @MainActor
    struct ToolbarItemAction {
        @Test
        func handleToolbarItemAction() {
            let expectedAction = MediaBottomToolbarAction.delete
            let contentViewModel = MockMediaTabContentViewModel()
            let sut = makeSUT(
                tabViewModels: [.timeline: contentViewModel]
            )
            
            sut.handleToolbarItemAction(expectedAction)
            
            #expect(contentViewModel.handledAction == expectedAction)
        }
        
        @Test
        func actionAnalyticsTracked() async throws {
            let tracker = MockTracker()
            let sut = makeSUT(
                tabViewModels: [.timeline: MockMediaTabContentViewModel()],
                tracker: tracker
            )
            // Events are not sendable so cant use params for the test
            let actions = [MediaBottomToolbarAction.shareLink, .manageLink, .download, .sendToChat, .more, .moveToRubbishBin, .addToAlbum]
            for action in actions {
                sut.handleToolbarItemAction(action)
            }
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [
                    MediaScreenLinkButtonPressedEvent(),
                    MediaScreenLinkButtonPressedEvent(),
                    MediaScreenDownloadButtonPressedEvent(),
                    MediaScreenRespondButtonPressedEvent(),
                    MediaScreenMoreButtonPressedEvent(),
                    MediaScreenTrashButtonPressedEvent(),
                    MediaScreenAlbumAddItemsButtonPressedEvent()
                ]
            )
        }
    }
    
    @MainActor
    @Test
    func handlePhotoFilter() async throws {
        let expectedOption: PhotosFilterOptionsEntity = [.allMedia, .allLocations]
        let contentViewModel = MockMediaTabContentViewModel()
        let sut = Self.makeSUT(
            tabViewModels: [.timeline: contentViewModel]
        )
        
        sut.photoFilter(option: expectedOption)
        
        #expect(contentViewModel.handledPhotosFilterOptions == expectedOption)
    }
    
    @MainActor
    @Test
    func toolbarUpdatePublisherUpdatesToolbarConfig() async throws {
        let contentViewModel = MockMediaTabContentViewModel(
            toolBarActions: [.shareLink, .delete]
        )
        let sut = Self.makeSUT(
            tabViewModels: [.timeline: contentViewModel]
        )
        
        // Enable edit mode to show toolbar
        sut.editMode = .active
        
        // Toolbar should show even with no selection (count = 0)
        #expect(sut.toolbarConfig?.selectedItemsCount == 0)
        
        let mockNodes = [
            NodeEntity(),
            NodeEntity(),
            NodeEntity()
        ]
        contentViewModel.selectedNodesForToolbarValue = mockNodes
        contentViewModel.toolbarUpdateSubject.send()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(sut.toolbarConfig?.selectedItemsCount == 3)
        #expect(sut.toolbarConfig?.actions == [.shareLink, .delete])
    }
    
    @MainActor
    struct NodeActionDisplayMode {
        @Test
        func protocolConformance() {
            let displayMode = DisplayMode.photosTimeline
            let contentViewModel = MockMediaTabContentViewModel(
                nodeActionDisplayMode: displayMode)
            let sut = makeSUT(
                tabViewModels: [.timeline: contentViewModel]
            )
            
            #expect(sut.nodeActionDisplayMode == displayMode)
        }
        
        @Test
        func nodeActionDisplayMode_cloudDrive() {
            let contentViewModel = MockMediaTabEmptyContentViewModel()
            let sut = makeSUT(
                tabViewModels: [.timeline: contentViewModel]
            )
            
            #expect(sut.nodeActionDisplayMode == .cloudDrive)
        }
    }
    
    @MainActor
    @Suite
    struct NavigationSubtitle {
        @Test
        func subtitleUpdates() async throws {
            let displayMode = DisplayMode.photosTimeline
            let contentViewModel = MockMediaTabContentViewModel(
                nodeActionDisplayMode: displayMode)
            let sut = makeSUT(
                tabViewModels: [.timeline: contentViewModel]
            )
            
            try await confirmation { confirmation in
                let expectedSubtitle = "Updated subtitle"
                
                let subscription = sut.$navigationSubtitle
                    .dropFirst()
                    .sink {
                        #expect($0 == expectedSubtitle)
                        confirmation()
                    }
                
                contentViewModel.navigationSubtitleUpdateSubject.send(expectedSubtitle)
                
                try await Task.sleep(nanoseconds: 100_000_000)
                
                subscription.cancel()
            }
        }
        
        @Test
        func editingShouldSetSubtitleToNil() async throws {
            let displayMode = DisplayMode.photosTimeline
            let contentViewModel = MockMediaTabContentViewModel(
                nodeActionDisplayMode: displayMode)
            let sut = makeSUT(
                tabViewModels: [.timeline: contentViewModel]
            )
            
            try await confirmation(expectedCount: 1) { confirmation in
                let subscription = sut.$navigationSubtitle
                    .dropFirst(2)
                    .sink {
                        #expect($0 == nil)
                        confirmation()
                    }
                
                contentViewModel.navigationSubtitleUpdateSubject.send("update")
                sut.editMode = .active
                
                try await Task.sleep(nanoseconds: 100_000_000)
                
                subscription.cancel()
            }
        }
        
        @Test
        func noProtocolConformanceShouldSetToNil() async throws {
            let contentViewModel = MockMediaTabEmptyContentViewModel()
            let sut = makeSUT(
                tabViewModels: [.timeline: contentViewModel]
            )
            
            #expect(sut.navigationSubtitle == nil)
        }
    }
    
    @Suite
    struct Analytics {
        @MainActor
        @Test
        func onAppear() {
            let tracker = MockTracker()
            let sut = makeSUT(tracker: tracker)
            
            sut.onViewAppear()
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [MediaScreenEvent()]
            )
        }
        
        @MainActor
        @Test
        func tabChange() {
            let tracker = MockTracker()
            let sut = makeSUT(tracker: tracker)
            
            sut.selectedTab = .album
            sut.selectedTab = .video
            sut.selectedTab = .playlist
            sut.selectedTab = .timeline
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [
                    MediaScreenAlbumsTabEvent(),
                    MediaScreenVideosTabEvent(),
                    MediaScreenPlaylistsTabEvent(),
                    MediaScreenTimelineTabEvent()
                ]
            )
        }
    }
    
    @MainActor
    private static func makeSUT(
        tabViewModels: [MediaTab: any MediaTabContentViewModel] = [:],
        visualMediaSearchResultsViewModel: VisualMediaSearchResultsViewModel = makeVisualMediaSearchResultsViewModel(),
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol = MockMonitorCameraUploadUseCase(),
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        cameraUploadsSettingsViewRouter: some Routing = MockRouter(),
        cameraUploadProgressRouter: some CameraUploadProgressRouting = MockCameraUploadProgressRouter(),
        tracker: some AnalyticsTracking = MockTracker()
    ) -> MediaTabViewModel {
        .init(
            tabViewModels: tabViewModels,
            visualMediaSearchResultsViewModel: visualMediaSearchResultsViewModel,
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            cameraUploadProgressRouter: cameraUploadProgressRouter,
            tracker: tracker)
    }
    
    @MainActor
    private static func makeVisualMediaSearchResultsViewModel(
        photoAlbumContainerInteractionManager: PhotoAlbumContainerInteractionManager = PhotoAlbumContainerInteractionManager(),
        visualMediaSearchHistoryUseCase: some VisualMediaSearchHistoryUseCaseProtocol = MockVisualMediaSearchHistoryUseCase(),
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol = MockMonitorAlbumsUseCase(),
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        monitorUserAlbumPhotosUseCase: some MonitorUserAlbumPhotosUseCaseProtocol = MockMonitorUserAlbumPhotosUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        albumCoverUseCase: some AlbumCoverUseCaseProtocol = MockAlbumCoverUseCase(),
        monitorPhotosUseCase: some MonitorPhotosUseCaseProtocol = MockMonitorPhotosUseCase(),
        photoSearchResultRouter: some PhotoSearchResultRouterProtocol = MockPhotoSearchResultRouter(),
        contentLibrariesConfiguration: ContentLibraries.Configuration = .init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(),
            featureFlagProvider: MockFeatureFlagProvider(list: [:]),
            nodeUseCase: MockNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: { true }),
        searchDebounceTime: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(150),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VisualMediaSearchResultsViewModel {
        .init(
            photoAlbumContainerInteractionManager: photoAlbumContainerInteractionManager,
            visualMediaSearchHistoryUseCase: visualMediaSearchHistoryUseCase,
            monitorAlbumsUseCase: monitorAlbumsUseCase,
            thumbnailLoader: thumbnailLoader,
            monitorUserAlbumPhotosUseCase: monitorUserAlbumPhotosUseCase,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            albumCoverUseCase: albumCoverUseCase,
            monitorPhotosUseCase: monitorPhotosUseCase,
            photoSearchResultRouter: photoSearchResultRouter,
            contentLibrariesConfiguration: contentLibrariesConfiguration,
            searchDebounceTime: searchDebounceTime)
    }
}

private final class MockMediaTabContentViewModel: MediaTabContentViewModel {
    let editModeToggleRequested = PassthroughSubject<Void, Never>()
    let navigationBarUpdateSubject = PassthroughSubject<Void, Never>()
    let titleUpdateSubject = PassthroughSubject<String, Never>()
    let toolbarUpdateSubject = PassthroughSubject<Void, Never>()
    let navigationSubtitleUpdateSubject = PassthroughSubject<String?, Never>()
    
    var toolBarActions: [MediaBottomToolbarAction]?
    var itemViewModels: [NavigationBarItemViewModel]
    
    weak var toolbarCoordinator: (any MediaTabToolbarCoordinatorProtocol)?
    
    var selectedNodesForToolbarValue: [NodeEntity] = []
    
    private let _contextMenuConfiguration: CMConfigEntity?
    private let nodeActionDisplayMode: DisplayMode
    private(set) var handledAction: MediaBottomToolbarAction?
    private(set) var handledPhotosFilterOptions: PhotosFilterOptionsEntity?
    
    init(
        itemViewModels: [NavigationBarItemViewModel] = [],
        contextMenuConfiguration: CMConfigEntity? = nil,
        toolBarActions: [MediaBottomToolbarAction]? = nil,
        nodeActionDisplayMode: DisplayMode = .cloudDrive
    ) {
        self.itemViewModels = itemViewModels
        _contextMenuConfiguration = contextMenuConfiguration
        self.toolBarActions = toolBarActions
        self.nodeActionDisplayMode = nodeActionDisplayMode
    }
}

extension MockMediaTabContentViewModel: MediaTabContextMenuActionHandler { }

extension MockMediaTabContentViewModel: MediaTabNavigationBarItemProvider {
    
    var navigationBarUpdatePublisher: AnyPublisher<Void, Never>? {
        navigationBarUpdateSubject.eraseToAnyPublisher()
    }
    
    func navigationBarItems(for editMode: EditMode) -> [NavigationBarItemViewModel] {
        itemViewModels
    }
}

extension MockMediaTabContentViewModel: NodeActionDisplayModeProvider {
    var displayMode: DisplayMode {
        nodeActionDisplayMode
    }
}

extension MockMediaTabContentViewModel: MediaTabContextMenuProvider {
    func contextMenuConfiguration() -> CMConfigEntity? {
        _contextMenuConfiguration
    }
}

extension MockMediaTabContentViewModel: MediaTabToolbarActionsProvider {
    var toolbarUpdatePublisher: AnyPublisher<Void, Never>? {
        toolbarUpdateSubject.eraseToAnyPublisher()
    }
    
    func toolbarConfig() -> MediaBottomToolbarConfig? {
        let count = selectedNodesForToolbarValue.count
        guard let actions = toolBarActions else { return nil }
        
        return MediaBottomToolbarConfig(
            actions: actions,
            selectedItemsCount: count,
            isAllExported: false
        )
    }
}

extension MockMediaTabContentViewModel: MediaTabToolbarActionHandler {
    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        handledAction = action
    }
    
    func handlePhotoFilter(option: PhotosFilterOptionsEntity) {
        handledPhotosFilterOptions = option
    }
}

extension MockMediaTabContentViewModel: MediaTabNavigationTitleProvider {
    var titleUpdatePublisher: AnyPublisher<String, Never> {
        titleUpdateSubject.eraseToAnyPublisher()
    }
}

extension MockMediaTabContentViewModel: MediaTabNavigationSubtitleProvider {
    var subtitleUpdatePublisher: AnyPublisher<String?, Never> {
        navigationSubtitleUpdateSubject.eraseToAnyPublisher()
    }
}

final class MockMediaTabEmptyContentViewModel: MediaTabContentViewModel {
    
}

struct MockPhotoSearchResultRouter: PhotoSearchResultRouterProtocol {
    func didTapMoreAction(on node: HandleEntity, button: UIButton) {
        
    }
    
    func didSelectAlbum(_ album: AlbumEntity) {
        
    }
    
    func didSelectPhoto(_ photo: NodeEntity, otherPhotos: [NodeEntity]) {

    }
}
