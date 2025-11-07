@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

struct CameraUploadProgressTableViewModelTests {
    @MainActor
    @Test func initialInProgressViewModels() async {
        let assetIdentifier = "localIdentifier"
        let inQueueAssetIdentifier = "inQueueLocalIdentifier"
        let fileEntity = CameraUploadFileDetailsEntity(localIdentifier: assetIdentifier)
        let cameraUploadProgressUseCase = MockCameraUploadProgressUseCase(
            inProgressFilesResult: .success([fileEntity])
        )
        let cameraUploadFileDetailsUseCase = MockCameraUploadFileDetailsUseCase()
        let photoLibraryThumbnailUseCase = MockPhotoLibraryThumbnailUseCase()
        let assetUploadEntity = CameraAssetUploadEntity(localIdentifier: inQueueAssetIdentifier)
        let paginationManager = MockPaginationManager(
            loadInitialPageResult: .init(
                firstPageIndex: 0,
                lastPageIndex: 1,
                items: [assetUploadEntity])
        )
        let thumbnailSize = CGSize(width: 32, height: 32)
        let sut = Self.makeSUT(
            cameraUploadProgressUseCase: cameraUploadProgressUseCase,
            cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            paginationManager: paginationManager
        )
        
        await sut.loadInitial()
        
        #expect(sut.inProgressSnapshotUpdate == .initialLoad([.init(
            fileEntity: fileEntity,
            cameraUploadProgressUseCase: cameraUploadProgressUseCase,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            thumbnailSize: thumbnailSize)]))
        #expect(sut.inQueueSnapshotUpdate == .initial([.init(
            assetUploadEntity: assetUploadEntity,
            cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            thumbnailSize: thumbnailSize)]))
        #expect(photoLibraryThumbnailUseCase.invocations == [.startCaching(identifiers: [assetIdentifier, inQueueAssetIdentifier], targetSize: thumbnailSize)])
    }
    
    @MainActor
    struct PhaseEventUpdates {
        private let assetIdentifier = "localIdentifier"
        private let thumbnailSize = CGSize(width: 32, height: 32)
        
        @Test("Uploading should retrieve file details and add to in Progress")
        func uploading() async {
            let phaseEvent = CameraUploadPhaseEventEntity(
                assetIdentifier: assetIdentifier, phase: .uploading)
            let fileEntity = CameraUploadFileDetailsEntity(localIdentifier: assetIdentifier)
            let cameraUploadProgressUseCase = MockCameraUploadProgressUseCase(
                cameraUploadPhaseEventUpdates: SingleItemAsyncSequence(
                    item: phaseEvent).eraseToAnyAsyncSequence(),
                inProgressFilesResult: .success([]))
            let cameraUploadFileDetailsUseCase = MockCameraUploadFileDetailsUseCase(
                fileDetails: [fileEntity]
            )
            let photoLibraryThumbnailUseCase = MockPhotoLibraryThumbnailUseCase()
            let sut = makeSUT(
                cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
                photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            )
            
            await sut.loadInitial()
            await sut.monitorActiveUploads()
            
            #expect(sut.inProgressSnapshotUpdate == .itemAdded(.init(
                fileEntity: fileEntity,
                cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
                thumbnailSize: thumbnailSize)))
        }
        
        @Test("Upload complete should remove from in progress and stop caching")
        func complete() async throws {
            let assetIdentifier = "localIdentifier"
            let phaseEvent = CameraUploadPhaseEventEntity(
                assetIdentifier: assetIdentifier, phase: .completed)
            
            let cameraUploadProgressUseCase = MockCameraUploadProgressUseCase(
                cameraUploadPhaseEventUpdates: SingleItemAsyncSequence(
                    item: phaseEvent).eraseToAnyAsyncSequence(),
                inProgressFilesResult: .success([.init(localIdentifier: assetIdentifier)]))
            let photoLibraryThumbnailUseCase = MockPhotoLibraryThumbnailUseCase()
            let sut = makeSUT(
                cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase
            )
            
            await sut.loadInitial()
            
            await sut.monitorActiveUploads()
            
            #expect(sut.inProgressSnapshotUpdate == .itemRemoved(assetIdentifier))
            
            #expect(photoLibraryThumbnailUseCase.invocations == [
                .startCaching(identifiers: [assetIdentifier], targetSize: thumbnailSize),
                .stopCaching(identifiers: [assetIdentifier], targetSize: thumbnailSize)])
        }
    }
    
    @Suite("Pagination Update")
    @MainActor
    struct PaginationUpdate {
        @Test("Handle queue section scroll triggers pagination")
        func queueSectionScrollTriggersPagination() async throws {
            let queuedItems =  makeCameraAssetUploadEntities(count: 30)
            let newItems = (30..<60).map { CameraAssetUploadEntity(localIdentifier: "item_\($0)") }
            let paginationManager = MockPaginationManager(
                loadInitialPageResult: .init(
                    firstPageIndex: 0,
                    lastPageIndex: 0,
                    items: queuedItems
                ),
                loadPageIfNeededResult: .init(
                    firstPageIndex: 0,
                    lastPageIndex: 1,
                    items: queuedItems + newItems)
            )
            
            let sut = makeSUT(
                cameraUploadProgressUseCase: MockCameraUploadProgressUseCase(
                    inProgressFilesResult: .success([])),
                paginationManager: paginationManager)
            await sut.loadInitial()
            
            await sut.handleQueueSectionScroll(
                visibleIndex: 25,
                totalVisibleItems: 31,
                isUserInitiated: true
            )
            
            #expect(await paginationManager.loadPageIfNeededCallCount == 1)
            
            guard case .updated(let updatedVMs) = sut.inQueueSnapshotUpdate else {
                Issue.record("Expected updated queue snapshot")
                return
            }
            #expect(updatedVMs.count == 60)
        }
        
        @Test("Handle queue section scroll skips when pagination in progress")
        func queueSectionScrollSkipsWhenInProgress() async throws {
            let paginationManager = MockPaginationManager(
                loadInitialPageResult: .init(
                    firstPageIndex: 0,
                    lastPageIndex: 0,
                    items: makeCameraAssetUploadEntities(count: 30)
                )
            )
            
            let sut = makeSUT(
                cameraUploadProgressUseCase: MockCameraUploadProgressUseCase(
                    inProgressFilesResult: .success([])),
                paginationManager: paginationManager)
            await sut.loadInitial()
            
            let task1 = Task {
                await sut.handleQueueSectionScroll(
                    visibleIndex: 25,
                    totalVisibleItems: 30,
                    isUserInitiated: true
                )
            }
            
            let task2 = Task {
                await sut.handleQueueSectionScroll(
                    visibleIndex: 26,
                    totalVisibleItems: 30,
                    isUserInitiated: true
                )
            }
            
            await task1.value
            await task2.value
            
            #expect(await paginationManager.loadPageIfNeededCallCount <= 2)
        }
        
        @Test("Handle queue section scroll returns early for small datasets")
        func queueSectionScrollSmallDataset() async throws {
            let paginationManager = MockPaginationManager(
                pageSize: 30,
                loadInitialPageResult: .init(
                    firstPageIndex: 0,
                    lastPageIndex: 0,
                    items: makeCameraAssetUploadEntities(count: 20)
                )
            )
            
            let sut = makeSUT(
                cameraUploadProgressUseCase: MockCameraUploadProgressUseCase(
                    inProgressFilesResult: .success([])),
                paginationManager: paginationManager)
            await sut.loadInitial()
            
            await sut.handleQueueSectionScroll(
                visibleIndex: 10,
                totalVisibleItems: 20,
                isUserInitiated: true
            )
            
            #expect(await paginationManager.loadPageIfNeededCallCount == 0)
        }
        
        @Test("Handle visible items smaller than page size")
        func visibleItemsSmallerThanPageSize() async throws {
            let paginationManager = MockPaginationManager(
                pageSize: 15,
                loadInitialPageResult: .init(
                    firstPageIndex: 0,
                    lastPageIndex: 2,
                    items: makeCameraAssetUploadEntities(count: 90)
                )
            )
            
            let sut = makeSUT(
                cameraUploadProgressUseCase: MockCameraUploadProgressUseCase(
                    inProgressFilesResult: .success([])),
                paginationManager: paginationManager)
            await sut.loadInitial()
            
            await sut.handleQueueSectionScroll(
                visibleIndex: 45,
                totalVisibleItems: 90,
                isUserInitiated: true
            )
            
            #expect(await paginationManager.loadPageIfNeededCallCount == 0)
        }
        
        @Test("Handle visible item lower than threshold",
              arguments: [(90, 200)])
        func visibleItemsLowerThanThreshold(
            visibleIndex: Int,
            totalVisibleItems: Int
        ) async throws {
            let paginationManager = MockPaginationManager(
                pageSize: 30,
                loadInitialPageResult: .init(
                    firstPageIndex: 0,
                    lastPageIndex: 2,
                    items: makeCameraAssetUploadEntities(count: totalVisibleItems)
                )
            )
            
            let sut = makeSUT(
                cameraUploadProgressUseCase: MockCameraUploadProgressUseCase(
                    inProgressFilesResult: .success([])),
                paginationManager: paginationManager)
            await sut.loadInitial()
            
            await sut.handleQueueSectionScroll(
                visibleIndex: visibleIndex,
                totalVisibleItems: totalVisibleItems,
                isUserInitiated: true
            )
            
            #expect(await paginationManager.loadPageIfNeededCallCount == 0)
        }
        
        @Test("Near bottom edge load even if its not user initiated",
              arguments: [(170, 200, 1), (30, 200, 0)])
        func nearBottomEdge(
            visibleIndex: Int,
            totalVisibleItems: Int,
            expectedLoadCount: Int
        ) async throws {
            let paginationManager = MockPaginationManager(
                pageSize: 30,
                loadInitialPageResult: .init(
                    firstPageIndex: 0,
                    lastPageIndex: 2,
                    items: makeCameraAssetUploadEntities(count: 300)
                )
            )
            
            let sut = makeSUT(
                cameraUploadProgressUseCase: MockCameraUploadProgressUseCase(
                    inProgressFilesResult: .success([])),
                paginationManager: paginationManager)
            await sut.loadInitial()
            
            await sut.handleQueueSectionScroll(
                visibleIndex: 170,
                totalVisibleItems: 200,
                isUserInitiated: false
            )
            
            #expect(await paginationManager.loadPageIfNeededCallCount == 1)
        }
        
        private func makeCameraAssetUploadEntities(count: Int) -> [CameraAssetUploadEntity] {
            (0..<count).map { index in
                CameraAssetUploadEntity(
                    localIdentifier: "item_\(index)")
            }
        }
    }
    
    @MainActor
    private static func makeSUT(
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol = MockCameraUploadProgressUseCase(),
        cameraUploadFileDetailsUseCase: some CameraUploadFileDetailsUseCaseProtocol = MockCameraUploadFileDetailsUseCase(),
        photoLibraryThumbnailUseCase: some PhotoLibraryThumbnailUseCaseProtocol = MockPhotoLibraryThumbnailUseCase(),
        paginationManager: some CameraUploadPaginationManagerProtocol = MockPaginationManager()
    ) -> CameraUploadProgressTableViewModel {
        .init(
            cameraUploadProgressUseCase: cameraUploadProgressUseCase,
            cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            paginationManager: paginationManager)
    }
}

actor MockPaginationManager: CameraUploadPaginationManagerProtocol {
    let pageSize: Int
    
    private let loadInitialPageResult: PaginationUpdate
    private let loadPageIfNeededResult: PaginationUpdate?
    private(set) var removedItems: [CameraUploadLocalIdentifierEntity] = []
    private(set) var resetCalled = false
    private(set) var cancelAllCalled = false
    private(set) var loadPageIfNeededCallCount = 0
    
    init(
        pageSize: Int = 30,
        loadInitialPageResult: PaginationUpdate = PaginationUpdate(firstPageIndex: 0, lastPageIndex: 0, items: []),
        loadPageIfNeededResult: PaginationUpdate? = nil
    ) {
        self.pageSize = pageSize
        self.loadInitialPageResult = loadInitialPageResult
        self.loadPageIfNeededResult = loadPageIfNeededResult
    }
    
    func loadInitialPage() async -> PaginationUpdate {
        loadInitialPageResult
    }
    
    func loadPageIfNeeded(itemIndex: Int) async -> PaginationUpdate? {
        loadPageIfNeededCallCount += 1
        return loadPageIfNeededResult
    }
    
    func removeItemFromPages(localIdentifier: CameraUploadLocalIdentifierEntity) {
        removedItems.append(localIdentifier)
    }
    
    func reset() {
        resetCalled = true
    }
    
    func cancelAll() {
        cancelAllCalled = true
    }
}
