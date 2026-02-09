import ContentLibraries
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPreference
import MEGAPreferenceMocks
import MEGASwift
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
            let tracker = MockTracker()
            let sut = makeSUT(tracker: tracker)
            #expect(sut.timelineViewModel.sortOrder == .modificationDesc)
            
            let newSortOrder = SortOrderEntity.modificationAsc
            sut.handleSortAction(newSortOrder.toSortOrderType())
            
            #expect(sut.timelineViewModel.sortOrder == newSortOrder)
            
            sut.handleSortAction(SortOrderEntity.modificationDesc.toSortOrderType())
            
            Test.assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [
                    MediaScreenSortByOldestSelectedEvent(),
                    MediaScreenSortByNewestSelectedEvent()
                ]
            )
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
    struct NavigationSubtitle {
        let state = CameraUploadStateEntity(
            stats: .init(progress: 50, pendingFilesCount: 80, pendingVideosCount: 0),
            pausedReason: nil)
        
        @Test()
        func updateNavigationTitleViewToCheckForUploads() async throws {
            let sut = makeSUTWithCameraUploads()
            
            await confirmation { confirmation in
                await confirmSubtitleUpdate(
                    sut: sut,
                    expectedSubtitle: Strings.Localizable.CameraUploads.checkingForUploads,
                    dropFirst: 1,
                    confirmation: confirmation
                )
            }
        }
        
        @Test(arguments: [
            (true, String(format: Strings.localized("cameraUploads.progress.uploading.items", comment: ""), locale: .current, 80)),
            (false, nil)
        ]) func uploading(
            isCameraUploadsEnabled: Bool,
            expectedSubtitle: String?
        ) async {
            let sut = makeSUTWithCameraUploads(
                state: state,
                isCameraUploadsEnabled: isCameraUploadsEnabled
            )
            
            await confirmation { confirmation in
                let dropCount = expectedSubtitle != nil ? 2 : 1
                await confirmSubtitleUpdate(
                    sut: sut,
                    expectedSubtitle: expectedSubtitle,
                    dropFirst: dropCount,
                    confirmation: confirmation
                )
            }
        }
        
        @Test(arguments: [
            (
                CameraUploadStateEntity(
                    stats: .init(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 0),
                    pausedReason: nil
                ),
                Strings.Localizable.CameraUploads.complete
            ),
            (
                CameraUploadStateEntity(
                    stats: .init(progress: 0.8, pendingFilesCount: 5, pendingVideosCount: 0),
                    pausedReason: nil
                ),
                String(
                    format: Strings.localized("cameraUploads.progress.uploading.items", comment: ""),
                    locale: .current, 5
                )
            ),
            (
                CameraUploadStateEntity(
                    stats: .init(progress: 0.8, pendingFilesCount: 5, pendingVideosCount: 0),
                    pausedReason: .networkIssue(.noConnection)
                ),
                String(
                    format: Strings.localized("cameraUploads.progress.paused.items", comment: ""),
                    locale: .current, 5
                )
            )
        ])
        func uploadState(
            state: CameraUploadStateEntity,
            expectedSubtitle: String
        ) async {
            let sut = makeSUTWithCameraUploads(state: state)
            
            await confirmation { confirmation in
                await confirmSubtitleUpdate(
                    sut: sut,
                    expectedSubtitle: expectedSubtitle,
                    confirmation: confirmation
                )
            }
        }
        
        @Test
        func completeToUpToDate() async throws {
            let completeState = CameraUploadStateEntity(
                stats: .init(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 0),
                pausedReason: nil
            )
            
            let sut = makeSUTWithCameraUploads(state: completeState)
            
            try await confirmation(expectedCount: 3) { confirmation in
                var expectations = [
                    Strings.Localizable.CameraUploads.checkingForUploads,
                    Strings.Localizable.CameraUploads.complete,
                    Strings.Localizable.CameraUploads.upToDate
                ]
                let subscription = sut.subtitleUpdatePublisher
                    .dropFirst()
                    .sink {
                        #expect($0 == expectations.removeFirst())
                        confirmation()
                    }
                
                await sut.monitorCameraUploads()
                try await sut.delayedUploadUpToDateTask?.value
                subscription.cancel()
            }
        }
        
        private func makeSUTWithCameraUploads(
            state: CameraUploadStateEntity? = nil,
            isCameraUploadsEnabled: Bool = true
        ) -> MediaTimelineTabContentViewModel {
            let preferenceUseCase = makePreferenceUseCase(isCameraUploadsEnabled: isCameraUploadsEnabled)
            
            if let state {
                let monitorCameraUploadUseCase = makeMonitorCameraUploadUseCase(state: state)
                return makeSUT(
                    monitorCameraUploadUseCase: monitorCameraUploadUseCase,
                    preferenceUseCase: preferenceUseCase
                )
            } else {
                return makeSUT(preferenceUseCase: preferenceUseCase)
            }
        }
        
        private func makePreferenceUseCase(isCameraUploadsEnabled: Bool) -> MockPreferenceUseCase {
            MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: isCameraUploadsEnabled]
            )
        }
        
        private func makeMonitorCameraUploadUseCase(
            state: CameraUploadStateEntity
        ) -> MockMonitorCameraUploadUseCase {
            let sequence = SingleItemAsyncSequence(item: state)
                .eraseToAnyAsyncSequence()
            return MockMonitorCameraUploadUseCase(cameraUploadState: sequence)
        }
        
        private func confirmSubtitleUpdate(
            sut: MediaTimelineTabContentViewModel,
            expectedSubtitle: String?,
            dropFirst: Int = 2,
            confirmation: Confirmation
        ) async {
            let subscription = sut.subtitleUpdatePublisher
                .dropFirst(dropFirst)
                .sink {
                    #expect($0 == expectedSubtitle)
                    confirmation()
                }
            await sut.monitorCameraUploads()
            subscription.cancel()
        }
    }
    
    @MainActor
    private static func makeSUT(
        timelineViewModel: NewTimelineViewModel = makeTimelineViewModel(),
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol = MockMonitorCameraUploadUseCase(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        tracker: some AnalyticsTracking = MockTracker()
    ) -> MediaTimelineTabContentViewModel {
        .init(
            timelineViewModel: timelineViewModel,
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            preferenceUseCase: preferenceUseCase,
            tracker: tracker)
    }
    
    @MainActor
    private static func makeTimelineViewModel(
        photoLibraryContentViewModel: PhotoLibraryContentViewModel = .init(library: PhotoLibrary()),
        photoLibraryContentViewRouter: PhotoLibraryContentViewRouter = PhotoLibraryContentViewRouter(),
        cameraUploadsSettingsViewRouter: some Routing = MockRouter(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase()
    ) -> NewTimelineViewModel {
        .init(
            photoLibraryContentViewModel: photoLibraryContentViewModel,
            photoLibraryContentViewRouter: photoLibraryContentViewRouter,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            preferenceUseCase: preferenceUseCase,
            photoLibraryUseCase: photoLibraryUseCase,
            nodeUseCase: nodeUseCase,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase
        )
    }
}
