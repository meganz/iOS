import Combine
@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing

struct MediaAlbumTabContentViewModelTests {
    
    // MARK: - Navigation Bar Items Tests
    
    @Suite("Navigation Items Provider")
    struct NavigationItemsProvider {
        
        @Test
        @MainActor
        func activeEditMode() {
            let sharedResourceProvider = MockMediaTabSharedResourceProvider()
            sharedResourceProvider.editMode = .active
            let albumListViewModel = makeAlbumListViewModel()
            let sut = makeSUT(albumListViewModel: albumListViewModel)
            sut.sharedResourceProvider = sharedResourceProvider
            
            let items = sut.navigationBarItems(for: .active)
            
            #expect(items.count == 1)
            #expect(items.first?.id == "cancel")
        }
        
        @Test(arguments: [
            (AlbumEntityType.favourite, ["cameraUploadStatus", "search"]),
            (AlbumEntityType.user, ["cameraUploadStatus", "search", "select"])
        ])
        @MainActor
        func inactiveEditMode(
            albumType: AlbumEntityType,
            expectedItems: [String]
        ) {
            let mockProvider = MockMediaTabSharedResourceProvider()
            let albumListViewModel = makeAlbumListViewModel()
            albumListViewModel.albums = [AlbumEntity(id: 1, type: albumType)]
            let sut = makeSUT(albumListViewModel: albumListViewModel)
            sut.sharedResourceProvider = mockProvider
            
            let items = sut.navigationBarItems(for: .inactive)
            
            #expect(items.map(\.id) == expectedItems)
        }
        
        @MainActor
        @Test
        func navigationBarUpdate() async throws {
            let albumListViewModel = makeAlbumListViewModel()
            let sut = makeSUT(albumListViewModel: albumListViewModel)
            
            try await confirmation { confirmation in
                let subscription = try #require(sut.navigationBarUpdatePublisher)
                    .sink {
                        confirmation()
                    }
                
                try await Task.sleep(nanoseconds: 100_000_000)
                
                albumListViewModel.albums = [AlbumEntity(id: 1, type: .user)]
                
                try await Task.sleep(nanoseconds: 100_000_000)
                subscription.cancel()
            }
        }
    }
    
    @MainActor
    @Test
    func titleUpdatePublisher() async throws {
        let provider = MockMediaTabSharedResourceProvider()
        let albumListViewModel = Self.makeAlbumListViewModel()
        let sut = Self.makeSUT(albumListViewModel: albumListViewModel)
        sut.sharedResourceProvider = provider
        
        let expectedTitleUpdates = [
            Strings.Localizable.Photos.SearchResults.Media.Section.title,
            Strings.Localizable.selectTitle,
            Strings.Localizable.General.Format.itemsSelected(1),
            Strings.Localizable.Photos.SearchResults.Media.Section.title
        ]
        try await confirmation(expectedCount: expectedTitleUpdates.count) { confirmation in
            var expectedTitleUpdates = expectedTitleUpdates
            let subscription = sut.titleUpdatePublisher
                .sink {
                    #expect($0 == expectedTitleUpdates.removeFirst())
                    confirmation()
                }
            
            try await Task.sleep(nanoseconds: 100_000_000)
            provider.editMode = .active
            
            albumListViewModel.selection.setSelectedAlbums([AlbumEntity(id: 1, type: .user)])
            
            provider.editMode = .inactive
            
            try await Task.sleep(nanoseconds: 100_000_000)
            subscription.cancel()
        }
    }
    
    @MainActor
    struct MediaTabToolbarActionsProvider {
        @Test
        func toolbarUpdatePublisher() async throws {
            let sut = makeSUT()
            
            try await confirmation { confirmation in
                let subscription = try #require(sut.toolbarUpdatePublisher)
                    .sink {
                        confirmation()
                    }
                
                sut.albumListViewModel.selection.setSelectedAlbums([.init(id: 1, type: .user)])
                
                try await Task.sleep(nanoseconds: 100_000_000)
                subscription.cancel()
            }
        }
        
        @Test(arguments: [
            ([AlbumEntity](), MediaBottomToolbarConfig(actions: [.manageLink, .delete], selectedItemsCount: 0, isAllExported: false)),
            ([AlbumEntity(id: 1, type: .user, sharedLinkStatus: .exported(true))]
             , MediaBottomToolbarConfig(actions: [.manageLink, .removeLink, .delete], selectedItemsCount: 1, isAllExported: true))
            
        ])
        func toolbarConfig(
            albums: [AlbumEntity],
            expected: MediaBottomToolbarConfig
        ) {
            let sut = makeSUT()
            sut.albumListViewModel.selection.setSelectedAlbums(albums)
            
            let config = sut.toolbarConfig()
            
            #expect(config == expected)
        }
    }
    
    @MainActor
    private static func makeSUT(
        albumListViewModel: AlbumListViewModel = makeAlbumListViewModel(),
        albumListViewRouter: some AlbumListViewRouting = AlbumListViewRouter()
    ) -> MediaAlbumTabContentViewModel {
        .init(
            albumListViewModel: albumListViewModel,
            albumListViewRouter: albumListViewRouter)
    }
    
    @MainActor
    private static func makeAlbumListViewModel(
        useCase: some AlbumListUseCaseProtocol = MockAlbumListUseCase(),
        albumModificationUseCase: some AlbumModificationUseCaseProtocol = MockAlbumModificationUseCase(),
        shareCollectionUseCase: some ShareCollectionUseCaseProtocol = MockShareCollectionUseCase(),
        tracker: some AnalyticsTracking = MockTracker(),
        monitorAlbumsUseCase: some MonitorAlbumsUseCaseProtocol = MockMonitorAlbumsUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        overDiskQuotaChecker: some OverDiskQuotaChecking = MockOverDiskQuotaChecker(),
        photoAlbumContainerViewModel: PhotoAlbumContainerViewModel? = nil,
        albumRemoteFeatureFlagProvider: some AlbumRemoteFeatureFlagProviderProtocol = MockAlbumRemoteFeatureFlagProvider()
    ) -> AlbumListViewModel {
        .init(
            usecase: useCase,
            albumModificationUseCase: albumModificationUseCase,
            shareCollectionUseCase: shareCollectionUseCase,
            tracker: tracker,
            monitorAlbumsUseCase: monitorAlbumsUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            overDiskQuotaChecker: overDiskQuotaChecker,
            alertViewModel: .init(title: "", affirmativeButtonTitle: "", destructiveButtonTitle: ""))
    }
}
