import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing
import XCTest

final class MonitorPhotosUseCaseTests: XCTestCase {
    
    func testMonitorPhotos_noFiltersProvided_shouldReturnAllPhotos() async throws {
        let photos = [NodeEntity(name: "test1.jpg", handle: 4, hasThumbnail: true),
                      NodeEntity(name: "test4.mp4", handle: 5, hasThumbnail: false)]
        let photosRepository = MockPhotosRepository(photos: photos)
        let sut = makeSUT(photosRepository: photosRepository)
        
        var iterator = await sut.monitorPhotos(
            filterOptions: [],
            excludeSensitive: false,
            searchText: nil).makeAsyncIterator()
        
        let initialPhotos = try await iterator.next()?.get()
        XCTAssertEqual(Set(initialPhotos ?? []), Set(photos))
    }
    
    func testMonitorPhotos_onPhotoUpdateWithNoFilters_shouldReturnAllPhotosWithThumbnails() async throws {
        let photos = [NodeEntity(name: "test1.jpg", handle: 4, hasThumbnail: true),
                      NodeEntity(name: "test4.mp4", handle: 5, hasThumbnail: false)]
        let photosRepository = MockPhotosRepository(photosUpdated: makePhotosUpdatedSequenceWithItems(),
                                                    allPhotosCallOrderResult: [.success([]),
                                                                               .success(photos)])
        let sut = makeSUT(photosRepository: photosRepository)
        
        var iterator = await sut.monitorPhotos(
            filterOptions: [],
            excludeSensitive: false,
            searchText: nil).makeAsyncIterator()
        
        let initialPhotos = try await iterator.next()?.get()
        XCTAssertTrue(initialPhotos?.isEmpty ?? false)
        
        let firstUpdate = try await iterator.next()?.get()
        XCTAssertEqual(Set(firstUpdate ?? []), Set(photos))
    }
    
    func testMonitorPhotos_allLocationsAndAllMedia_shouldReturnAllPhotosWithThumbnails() async throws {
        let thumbnailPhoto = NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)
        let photos = [thumbnailPhoto,
                      NodeEntity(name: "test2.jpg", handle: 4, hasThumbnail: false)]
        let photosRepository = MockPhotosRepository(photos: photos)
        let sut = makeSUT(photosRepository: photosRepository)
        
        var iterator = await sut.monitorPhotos(
            filterOptions: [.allLocations, .allMedia],
            excludeSensitive: false,
            searchText: nil).makeAsyncIterator()
        
        let initialPhotos = try await iterator.next()?.get()
        XCTAssertEqual(initialPhotos, [thumbnailPhoto])
    }
    
    func testMonitorPhotos_onPhotoUpdateWithAllLocations_shouldReturnAllPhotosWithThumbnails() async throws {
        let thumbnailPhoto = NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)
        let photosRepository = MockPhotosRepository(photosUpdated: makePhotosUpdatedSequenceWithItems(),
                                                    allPhotosCallOrderResult: [.success([]),
                                                                               .success([thumbnailPhoto])])
        
        let sut = makeSUT(photosRepository: photosRepository)
        
        var iterator = await sut.monitorPhotos(
            filterOptions: [.allLocations, .allMedia],
            excludeSensitive: false,
            searchText: nil).makeAsyncIterator()
        
        let initialPhotos = try await iterator.next()?.get()
        XCTAssertTrue(initialPhotos?.isEmpty ?? false)
        
        let firstUpdate = try await iterator.next()?.get()
        XCTAssertEqual(firstUpdate, [thumbnailPhoto])
    }
    
    func testMonitorPhotos_cloudDriveAndVideos_shouldReturnOnlyVideosFromCloudDrive() async throws {
        let cameraUploadNode = NodeEntity(handle: 5)
        let thumbnailVideo = NodeEntity(name: "test.mp4", handle: 1, parentHandle: 34, hasThumbnail: true)
        let photos = [thumbnailVideo,
                      NodeEntity(name: "test2.mp4", handle: 4, hasThumbnail: false),
                      NodeEntity(name: "test3.mp4", handle: 4, parentHandle: cameraUploadNode.handle, hasThumbnail: true)
        ]
        let photosRepository = MockPhotosRepository(photos: photos)
        let photoLibraryContainer = PhotoLibraryContainerEntity(
            cameraUploadNode: cameraUploadNode, mediaUploadNode: nil)
        let photoLibraryUseCase = MockPhotoLibraryUseCase(photoLibraryContainer: photoLibraryContainer)
        let sut = makeSUT(photosRepository: photosRepository,
                          photoLibraryUseCase: photoLibraryUseCase)
        
        var iterator = await sut.monitorPhotos(
            filterOptions: [.cloudDrive, .videos],
            excludeSensitive: false,
            searchText: nil).makeAsyncIterator()
        
        let initialPhotos = try await iterator.next()?.get()
        XCTAssertEqual(initialPhotos, [thumbnailVideo])
    }
    
    func testMonitorPhotos_onPhotoUpdateWithCloudDriveAndVideos_shouldReturnOnlyVideosFromCloudDrive() async throws {
        let cameraUploadNode = NodeEntity(handle: 5)
        let thumbnailVideo = NodeEntity(name: "test.mp4", handle: 1, parentHandle: 34, hasThumbnail: true)
        let photosRepository = MockPhotosRepository(photosUpdated: makePhotosUpdatedSequenceWithItems(),
                                                    allPhotosCallOrderResult: [.success([]),
                                                                               .success([thumbnailVideo])])
        let photoLibraryContainer = PhotoLibraryContainerEntity(
            cameraUploadNode: cameraUploadNode, mediaUploadNode: nil)
        let photoLibraryUseCase = MockPhotoLibraryUseCase(photoLibraryContainer: photoLibraryContainer)
        let sut = makeSUT(photosRepository: photosRepository,
                          photoLibraryUseCase: photoLibraryUseCase)
        
        var iterator = await sut.monitorPhotos(
            filterOptions: [.cloudDrive, .videos],
            excludeSensitive: false,
            searchText: nil).makeAsyncIterator()
        
        let initialPhotos = try await iterator.next()?.get()
        XCTAssertTrue(initialPhotos?.isEmpty ?? false)
        
        let firstUpdate = try await iterator.next()?.get()
        XCTAssertEqual(firstUpdate, [thumbnailVideo])
    }
    
    func testMonitorPhotos_cameraUploadAndImages_shouldReturnOnlyImagesFromCameraUploadAndMediaUploadNode() async throws {
        let cameraUploadNode = NodeEntity(handle: 5)
        let mediaUploadNode = NodeEntity(handle: 66)
        let cameraUploadImage = NodeEntity(name: "test.jpg", handle: 1,
                                           parentHandle: cameraUploadNode.handle, hasThumbnail: true)
        let mediaUploadImage = NodeEntity(name: "test2.png", handle: 87,
                                          parentHandle: mediaUploadNode.handle, hasThumbnail: true)
        let photos = [cameraUploadImage,
                      mediaUploadImage,
                      NodeEntity(name: "test1.mp4", handle: 4, hasThumbnail: false),
                      NodeEntity(name: "test3.jpg", handle: 6, parentHandle: 8, hasThumbnail: true)
        ]
        let photosRepository = MockPhotosRepository(photos: photos)
        let photoLibraryContainer = PhotoLibraryContainerEntity(
            cameraUploadNode: cameraUploadNode, mediaUploadNode: mediaUploadNode)
        let photoLibraryUseCase = MockPhotoLibraryUseCase(photoLibraryContainer: photoLibraryContainer)
        let sut = makeSUT(photosRepository: photosRepository,
                          photoLibraryUseCase: photoLibraryUseCase)
        
        var iterator = await sut.monitorPhotos(
            filterOptions: [.cameraUploads, .images],
            excludeSensitive: false,
            searchText: nil).makeAsyncIterator()
        
        let initialPhotos = try await iterator.next()?.get()
        XCTAssertEqual(Set(initialPhotos ?? []),
                       Set([cameraUploadImage, mediaUploadImage]))
    }
    
    func testMonitorPhotos_onPhotoUpdateWithCameraUploadAndImages_shouldReturnOnlyImagesFromCameraUploadAndMediaUploadNode() async throws {
        let cameraUploadNode = NodeEntity(handle: 5)
        let mediaUploadNode = NodeEntity(handle: 66)
        let cameraUploadImage = NodeEntity(name: "test.jpg", handle: 1,
                                           parentHandle: cameraUploadNode.handle, hasThumbnail: true)
        let mediaUploadImage = NodeEntity(name: "test2.png", handle: 87,
                                          parentHandle: mediaUploadNode.handle, hasThumbnail: true)
        let photosRepository = MockPhotosRepository(photosUpdated: makePhotosUpdatedSequenceWithItems(),
                                                    allPhotosCallOrderResult: [.success([]),
                                                                               .success([cameraUploadImage, mediaUploadImage])])
        let photoLibraryContainer = PhotoLibraryContainerEntity(
            cameraUploadNode: cameraUploadNode, mediaUploadNode: mediaUploadNode)
        let photoLibraryUseCase = MockPhotoLibraryUseCase(photoLibraryContainer: photoLibraryContainer)
        let sut = makeSUT(photosRepository: photosRepository,
                          photoLibraryUseCase: photoLibraryUseCase)
        
        var iterator = await sut.monitorPhotos(
            filterOptions: [.cameraUploads, .images],
            excludeSensitive: false,
            searchText: nil).makeAsyncIterator()
        
        let initialPhotos = try await iterator.next()?.get()
        XCTAssertTrue(initialPhotos?.isEmpty ?? false)
        
        let firstUpdate = try await iterator.next()?.get()
        XCTAssertEqual(Set(firstUpdate ?? []),
                       Set([cameraUploadImage, mediaUploadImage]))
    }
    
    func testMonitorPhotos_onPhotoLoadFailed_shouldReturnErrorInFailedResultType() async throws {
        let photosRepository = MockPhotosRepository(photosUpdated: makePhotosUpdatedSequenceWithItems(),
                                                    allPhotosCallOrderResult: [.failure(GenericErrorEntity())])
       
        let sut = makeSUT(photosRepository: photosRepository)
        
        var iterator = await sut.monitorPhotos(
            filterOptions: [.allLocations, .allMedia],
            excludeSensitive: false,
            searchText: nil).makeAsyncIterator()
        
        do {
            _ = try await iterator.next()?.get()
            XCTFail("Expected failure")
        } catch {
            XCTAssertTrue(error is GenericErrorEntity)
        }
    }
    
    func testMonitorPhotos_onFolderSensitivityChanged_shouldReturnAllPhotosWithThumbnails() async throws {
        let thumbnailPhoto = NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)
        let photos = [thumbnailPhoto,
                      NodeEntity(name: "test2.jpg", handle: 4, hasThumbnail: false)]
        let photosRepository = MockPhotosRepository(photos: photos)
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            folderSensitivityChanged: SingleItemAsyncSequence(item: ()).eraseToAnyAsyncSequence())
        let sut = makeSUT(
            photosRepository: photosRepository,
            sensitiveNodeUseCase: sensitiveNodeUseCase)
        
        var iterator = await sut.monitorPhotos(
            filterOptions: [.allLocations, .allMedia],
            excludeSensitive: false,
            searchText: nil).makeAsyncIterator()
        
        let initialPhotos = try await iterator.next()?.get()
        XCTAssertEqual(initialPhotos, [thumbnailPhoto])
        
        let folderUpdatePhotos = try await iterator.next()?.get()
        XCTAssertEqual(folderUpdatePhotos, [thumbnailPhoto])
    }
    
    func testMonitorPhotos_favourites_shouldApplyFiltersAndReturnOnlyFavourites() async throws {
        let favouritePhoto = NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true, isFavourite: true)
        let photos = [favouritePhoto,
                      NodeEntity(name: "test2.jpg", handle: 4, hasThumbnail: false, isFavourite: false)]
        let photosRepository = MockPhotosRepository(photos: photos)
        let sut = makeSUT(
            photosRepository: photosRepository)
        
        let options: PhotosFilterOptionsEntity = [.allLocations, .allMedia, .favourites]
        var iterator = await sut.monitorPhotos(
            filterOptions: options,
            excludeSensitive: false,
            searchText: nil).makeAsyncIterator()
        
        let initialPhotos = try await iterator.next()?.get()
        XCTAssertEqual(initialPhotos, [favouritePhoto])
    }
    
    // MARK: Private
    
    private func makeSUT(
        photosRepository: some PhotosRepositoryProtocol = MockPhotosRepository(),
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase()
    ) -> MonitorPhotosUseCase {
        MonitorPhotosUseCase(photosRepository: photosRepository,
                             photoLibraryUseCase: photoLibraryUseCase,
                             sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
    
    private func makePhotosUpdatedSequenceWithItems() -> AnyAsyncSequence<[NodeEntity]> {
        SingleItemAsyncSequence(item: [NodeEntity(name: "test99.jpg", handle: 999, hasThumbnail: true)])
            .eraseToAnyAsyncSequence()
    }
}

@Suite("MonitorPhotosUseCase Tests")
struct MonitorPhotosUseCaseTestSuite {
    @Suite("Calls to monitorPhotos(filterOptions:excludeSensitive:searchText:)")
    struct MonitorPhotos {
        
        @Test("When search text provided it should filter photos", arguments: [
            (String?.none, [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)], [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)]),
            (String?.some("Te"), [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)], [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)]),
            (String?.some("SomethingElse"), [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)], [])
        ])
        func searchTextProvided(searchText: String?, photos: [NodeEntity], expectedPhotos: [NodeEntity]) async throws {
            let photosRepository = MockPhotosRepository(photos: photos)
            let sut = MonitorPhotosUseCaseTestSuite.makeSUT(
                photosRepository: photosRepository)
            
            var iterator = await sut.monitorPhotos(
                filterOptions: [],
                excludeSensitive: false,
                searchText: searchText).makeAsyncIterator()
            
            let initialPhotos = try #require(try await iterator.next()?.get())
            #expect(Set(initialPhotos) == Set(expectedPhotos))
        }
    }
    
    private static func makeSUT(
        photosRepository: some PhotosRepositoryProtocol = MockPhotosRepository(),
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase()
    ) -> MonitorPhotosUseCase {
        MonitorPhotosUseCase(photosRepository: photosRepository,
                             photoLibraryUseCase: photoLibraryUseCase,
                             sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
}
