import ContentLibraries
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPreference
import MEGAPreferenceMocks
import MEGASwift
import Testing

struct NewTimelineViewModelTests {
    
    @MainActor
    @Suite
    struct LoadPhotos {
        @Test
        func defaultFilters() async throws {
            let photos = [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)]
            let photoLibraryUseCase = MockPhotoLibraryUseCase(
                allPhotos: photos
            )
            let sut = makeSUT(photoLibraryUseCase: photoLibraryUseCase)
            
            await sut.loadPhotos()
            
            #expect(sut.photoLibraryContentViewModel.library.allPhotos == photos)
        }
        
        @Test
        func savedFilters() async throws {
            let photos = [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)]
            let photoLibraryUseCase = MockPhotoLibraryUseCase(
                allPhotos: photos
            )
            let timelineUserAttribute = TimelineUserAttributeEntity(
                mediaType: .images,
                location: .cameraUploads,
                usePreference: true)
            let contentConsumptionUseCase = MockContentConsumptionUserAttributeUseCase(
                timelineUserAttributeEntity: timelineUserAttribute
            )
            let sut = makeSUT(
                photoLibraryUseCase: photoLibraryUseCase,
            contentConsumptionUserAttributeUseCase: contentConsumptionUseCase)
            
            await sut.loadPhotos()
            
            #expect(sut.photoFilterOptions == timelineUserAttribute.toPhotoFilterOptionsEntity())
        }
        
        @Test func empty() async throws {
            let photoLibraryUseCase = MockPhotoLibraryUseCase()
            let sut = makeSUT(photoLibraryUseCase: photoLibraryUseCase)
            
            await sut.loadPhotos()
            
            #expect(sut.showEmptyStateView)
        }
    }
    
    @MainActor
    @Suite("Node Updates")
    struct NodeUpdates {
        @Test("Non visual media node updates should not trigger an update")
        func nonVisualMediaNodeUpdate() async throws {
            let nodeUpdates = SingleItemAsyncSequence(
                item: [NodeEntity(handle: 1, hasThumbnail: false)])
                .eraseToAnyAsyncSequence()
            let photoLibraryUseCase = MockPhotoLibraryUseCase()
            
            let sut = makeSUT(
                photoLibraryUseCase: photoLibraryUseCase,
                nodeUseCase: MockNodeUseCase(
                    nodeUpdates: nodeUpdates)
            )
            await sut.loadPhotos()
            
            await sut.monitorUpdates()
            try await sut.currentNodeUpdateTask?.value
            
            await #expect(photoLibraryUseCase.messages == [.media])
        }
        
        @Test("Visual media node should trigger updates")
        func visualMediaUpdatesTriggerLoad() async throws {
            let nodeUpdates = SingleItemAsyncSequence(
                item: [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)])
                .eraseToAnyAsyncSequence()
            let expectedPhotos = [
                NodeEntity(name: "test15.jpg", handle: 15, hasThumbnail: true)
            ]
            let photoLibraryUseCase = MockPhotoLibraryUseCase(
                allPhotos: expectedPhotos
            )
            let sut = makeSUT(
                photoLibraryUseCase: photoLibraryUseCase,
                nodeUseCase: MockNodeUseCase(
                    nodeUpdates: nodeUpdates)
            )
            await sut.loadPhotos()
            
            await sut.monitorUpdates()
            try await sut.currentNodeUpdateTask?.value
            
            #expect(sut.photoLibraryContentViewModel.library.allPhotos == expectedPhotos)
            await #expect(photoLibraryUseCase.messages == [.media, .media])
            #expect(sut.currentNodeUpdateTask == nil)
        }
    }
    
    @MainActor
    @Suite("Empty View")
    struct EmptyView {
        @Test("Camera upload enabled ensure correct no media found empty type returned")
        func emptyViewCameraUploadEnabled() {
            let sut = makeSUT(preferenceUseCase: MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: true]))
            sut.updatePhotoFilter(option: .allMedia)
            sut.updatePhotoFilter(option: .allLocations)
            
            let emptyScreenType = sut.emptyScreenTypeToShow()
            
            #expect(emptyScreenType == .noMediaFound)
        }
        
        @Test("Ensure the correct empty view type is shown for filter when camera upload is not enabled",
              arguments: [
                (filterType: PhotosFilterOptionsEntity.allMedia,
                 filterLocation: PhotosFilterOptionsEntity.allLocations, expectedViewType: PhotosEmptyScreenViewType.enableCameraUploads),
                (filterType: .allMedia, filterLocation: .cloudDrive, expectedViewType: .noMediaFound),
                (filterType: .allMedia, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads),
                (filterType: .images, filterLocation: .allLocations, expectedViewType: .enableCameraUploads),
                (filterType: .images, filterLocation: .cloudDrive, expectedViewType: .noImagesFound),
                (filterType: .images, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads),
                (filterType: .videos, filterLocation: .allLocations, expectedViewType: .enableCameraUploads),
                (filterType: .videos, filterLocation: .cloudDrive, expectedViewType: .noVideosFound),
                (filterType: .videos, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads)
              ])
        func emptyViewType(
            filterType: PhotosFilterOptionsEntity,
            filterLocation: PhotosFilterOptionsEntity,
            expectedViewType: PhotosEmptyScreenViewType
        ) async throws {
            let sut = makeSUT(preferenceUseCase: MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false]))
            sut.updatePhotoFilter(option: filterType)
            sut.updatePhotoFilter(option: filterLocation)
            
            let emptyScreenType = sut.emptyScreenTypeToShow()
            
            #expect(emptyScreenType == expectedViewType)
        }
    }
    
    @MainActor
    @Test
    func updateSortOrder() async throws {
        let photos = [
            NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)
        ]
        let photoLibraryContentViewModel = PhotoLibraryContentViewModel(
            library: photos.toPhotoLibrary(withSortType: .modificationDesc))
        
        let sut = Self.makeSUT(
            photoLibraryContentViewModel: photoLibraryContentViewModel
        )
        
        try await confirmation { confirmation in
            let cancellable = photoLibraryContentViewModel
                .$library
                .sink { _ in
                    confirmation()
                }
            
            sut.updateSortOrder(.modificationDesc)
            
            try await sut.sortPhotoLibraryTask?.value
            cancellable.cancel()
        }
    }
    
    @MainActor
    @Test
    func updatePhotoFilter() {
        let sut = Self.makeSUT()
        let taskId = sut.loadPhotosTaskId
        #expect(sut.photoFilterOptions == [.allMedia, .allLocations])
        
        let newFilter: PhotosFilterOptionsEntity = [.images, .allLocations]
        sut.updatePhotoFilter(option: newFilter)
        
        #expect(sut.photoFilterOptions == newFilter)
        #expect(sut.loadPhotosTaskId != taskId)
    }
    
    @MainActor
    @Test(arguments: [
        (PhotosFilterOptions.allLocations, true, false),
        (PhotosFilterOptions.allLocations, false, false),
        (PhotosFilterOptions.cloudDrive, false, true)
    ])
    func enableCameraBannerAction(
        location: PhotosFilterOptions,
        cameraUploadEnabled: Bool,
        actionShouldRoute: Bool
    ) {
        let cameraUploadsSettingsViewRouter = MockRouter()
        let sut = Self.makeSUT(
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            preferenceUseCase: MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: cameraUploadEnabled]))
        
        let action = sut.enableCameraUploadsBannerAction(filterLocation: location)
        if actionShouldRoute {
            action?()
            #expect(cameraUploadsSettingsViewRouter.startCalled == 1)
        } else {
            #expect(action == nil)
        }
    }
    
    @MainActor
    @Test
    func saveFilters() async throws {
        let contentConsumption = MockContentConsumptionUserAttributeUseCase()
        let sut = Self.makeSUT(
            contentConsumptionUserAttributeUseCase: contentConsumption
        )
        sut.updatePhotoFilter(option: .images)
        sut.updatePhotoFilter(option: .cameraUploads)
        
        await sut.saveFilters()
        
        #expect(contentConsumption.savedTimelineUserAttribute == .init(mediaType: .images, location: .cameraUploads, usePreference: true))
    }
    
    @MainActor
    @Test
    func filterChangesTrackAnalyticsCorrectly() {
        let tracker = MockTracker()
        let sut = Self.makeSUT(
            tracker: tracker
        )
        sut.updatePhotoFilter(option: .images)
        sut.updatePhotoFilter(option: .videos)
        sut.updatePhotoFilter(option: .allMedia)
        sut.updatePhotoFilter(option: .cloudDrive)
        sut.updatePhotoFilter(option: .cameraUploads)
        sut.updatePhotoFilter(option: .allLocations)
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                MediaScreenFilterImagesSelectedEvent(),
                MediaScreenFilterVideosSelectedEvent(),
                MediaScreenFilterAllMediaSelectedEvent(),
                MediaScreenFilterCloudDriveSelectedEvent(),
                MediaScreenFilterCameraUploadsSelectedEvent(),
                MediaScreenFilterAllLocationsSelectedEvent()
            ]
        )
    }
    
    @MainActor
    private static func makeSUT(
        photoLibraryContentViewModel: PhotoLibraryContentViewModel = .init(library: PhotoLibrary()),
        photoLibraryContentViewRouter: PhotoLibraryContentViewRouter = PhotoLibraryContentViewRouter(),
        cameraUploadsSettingsViewRouter: some Routing = MockRouter(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase(),
        tracker: some AnalyticsTracking = MockTracker()
    ) -> NewTimelineViewModel {
        .init(
            photoLibraryContentViewModel: photoLibraryContentViewModel,
            photoLibraryContentViewRouter: photoLibraryContentViewRouter,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            preferenceUseCase: preferenceUseCase,
            photoLibraryUseCase: photoLibraryUseCase,
            nodeUseCase: nodeUseCase,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            tracker: tracker
        )
    }
}
