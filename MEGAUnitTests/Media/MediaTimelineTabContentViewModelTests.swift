import ContentLibraries
@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPreference
import MEGAPreferenceMocks
import Testing

struct MediaTimelineTabContentViewModelTests {
    @Suite("Navigation Items Provider")
    struct NavigationItemsProvider {
        private let photos = [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)]
        
        @MainActor
        @Test
        func navigationBarUpdate() async throws {
            let timelineViewModel = makeTimelineViewModel()
            let sut = makeSUT(timelineViewModel: timelineViewModel)
            
            try await confirmation { confirmation in
                let subscription = try #require(sut.navigationBarUpdatePublisher)
                    .sink {
                        confirmation()
                    }
                
                try await Task.sleep(nanoseconds: 100_000_000)
                
                timelineViewModel.photoLibraryContentViewModel.library = photos.toPhotoLibrary(withSortType: .modificationDesc)
                
                try await Task.sleep(nanoseconds: 100_000_000)
                subscription.cancel()
            }
        }
        
        @Test
        @MainActor
        func activeEditMode() {
            let sharedResourceProvider = MockMediaTabSharedResourceProvider()
            sharedResourceProvider.editMode = .active
            let sut = makeSUT()
            sut.sharedResourceProvider = sharedResourceProvider
            
            let items = sut.navigationBarItems(for: .active)
            
            #expect(items.count == 1)
            #expect(items.first?.id == "cancel")
        }
        
        @Test()
        @MainActor
        func inactiveEditMode() {
            let sharedResourceProvider = MockMediaTabSharedResourceProvider()
            sharedResourceProvider.contextMenuConfig = .init(menuType: .menu(type: .mediaTabTimeline))
            sharedResourceProvider.contextMenuManager = .init(
                createContextMenuUseCase: MockCreateContextMenuUseCase())
            let sut = makeSUT()
            sut.sharedResourceProvider = sharedResourceProvider
            
            let items = sut.navigationBarItems(for: .inactive)
            
            #expect(items.map(\.id) == ["cameraUploadStatus", "search", "contextMenu"])
        }
    }
    
    @MainActor
    struct ContextMenuActionHandler {
        
        @Test
        func sortAction() {
            let sut = makeSUT()
            #expect(sut.timelineViewModel.sortOrder == .modificationDesc)
            
            let newSortOrder = SortOrderEntity.modificationAsc
            sut.handleSortAction(newSortOrder.toSortOrderType())
            
            #expect(sut.timelineViewModel.sortOrder == newSortOrder)
        }
        
        @Test
        func photoLocationOption() {
            let sut = makeSUT()
            #expect(sut.timelineViewModel.photoFilterOptions == [.allMedia, .allLocations])
            
            let newFilter: PhotosFilterOptionsEntity = [.images, .cloudDrive]
            sut.handlePhotoFilter(option: newFilter)
            
            #expect(sut.timelineViewModel.photoFilterOptions == newFilter)
        }
        
        @Test
        func settings() async throws {
            let cameraUploadsSettingsViewRouter = MockRouter()
            let timelineViewModel = makeTimelineViewModel(
                cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter
            )
            let sut = makeSUT(timelineViewModel: timelineViewModel)
            
            await withCheckedContinuation { continuation in
                cameraUploadsSettingsViewRouter.onStart = {
                    continuation.resume()
                }
                
                sut.handleQuickAction(.settings)
            }
            
            #expect(cameraUploadsSettingsViewRouter.startCalled == 1)
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
                
                sut.timelineViewModel.photoLibraryContentViewModel
                    .selection.setSelectedPhotos([NodeEntity(handle: 1)])
                
                try await Task.sleep(nanoseconds: 100_000_000)
                subscription.cancel()
            }
        }
        
        @Test(arguments: [
            [NodeEntity](),
            [.init(handle: 1)]
        ])
        func toolbarConfig(
            selectedPhotos: [NodeEntity]
        ) {
            let expectedConfig = MediaBottomToolbarConfig(
                actions: [.download, .manageLink, .addToAlbum, .moveToRubbishBin, .more],
                selectedItemsCount: selectedPhotos.count)
            let sut = makeSUT()
            sut.timelineViewModel.photoLibraryContentViewModel
                .selection.setSelectedPhotos(selectedPhotos)
            
            let config = sut.toolbarConfig()
            
            #expect(config == expectedConfig)
        }
    }
    
    @MainActor
    @Test
    func nodeActionDisplayMode() async throws {
        let sut = Self.makeSUT()
        
        #expect(sut.displayMode == .photosTimeline)
    }
    
    @MainActor
    @Test
    func editModeSubscription() async throws {
        let sharedResourceProvider = MockMediaTabSharedResourceProvider()
        let sut = Self.makeSUT()
        sut.sharedResourceProvider = sharedResourceProvider
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let selection = sut.timelineViewModel.photoLibraryContentViewModel.selection
        #expect(selection.editMode == .inactive)
        
        sharedResourceProvider.editMode = .active
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(selection.editMode == .active)
    }
    
    @MainActor
    private static func makeSUT(
        timelineViewModel: NewTimelineViewModel = makeTimelineViewModel()
    ) -> MediaTimelineTabContentViewModel {
        .init(
            timelineViewModel: timelineViewModel)
    }
    
    @MainActor
    private static func makeTimelineViewModel(
        photoLibraryContentViewModel: PhotoLibraryContentViewModel = .init(library: PhotoLibrary()),
        photoLibraryContentViewRouter: PhotoLibraryContentViewRouter = PhotoLibraryContentViewRouter(),
        cameraUploadsSettingsViewRouter: some Routing = MockRouter(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase()
    ) -> NewTimelineViewModel {
        .init(
            photoLibraryContentViewModel: photoLibraryContentViewModel,
            photoLibraryContentViewRouter: photoLibraryContentViewRouter,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            preferenceUseCase: preferenceUseCase,
            photoLibraryUseCase: photoLibraryUseCase,
            nodeUseCase: nodeUseCase
        )
    }
}
