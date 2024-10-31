import Combine
import ContentLibraries
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class AlbumContentPickerViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    @MainActor
    func testInit_selectionLimit_isSetTo150() {
        let sut = makeAlbumContentPickerViewModel()
        XCTAssertEqual(sut.selectLimit, 150)
    }
    
    @MainActor
    func testInit_selectionLimit_isSetTo200() {
        let sut = makeAlbumContentPickerViewModel(configuration: PhotoLibraryContentConfiguration(selectLimit: 200))
        XCTAssertEqual(sut.selectLimit, 200)
    }
    
    @MainActor
    func testOnDone_whenNoImagesSelected_shouldDismissTheScreen() async {
        let sut = makeAlbumContentPickerViewModel()
        await sut.photosLoadingTask?.value
        
        sut.onDone()
        
        XCTAssertTrue(sut.shouldDismiss)
    }
    
    @MainActor
    func testOnDone_whenItemsSelected_completionShouldReturnSelectedPhotos() async {
        let node1 = NodeEntity(name: "a.png", handle: HandleEntity(1))
        let expectedSelectedPhotos = [node1]
        
        let exp = XCTestExpectation(description: "Adding content to album should be successful")
        let sut = makeAlbumContentPickerViewModel(completion: { album, photos in
            XCTAssertNotNil(album)
            XCTAssertEqual(photos, expectedSelectedPhotos)
            exp.fulfill()
        })
        await sut.photosLoadingTask?.value
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos(expectedSelectedPhotos)
        
        sut.onDone()
        
        await sut.photosLoadingTask?.value
        XCTAssertTrue(sut.shouldDismiss)
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    @MainActor
    func testOnCancel_shouldDismissSetToTrue() {
        let viewModel = makeAlbumContentPickerViewModel()
        XCTAssertFalse(viewModel.shouldDismiss)
        
        viewModel.onCancel()
        
        XCTAssertTrue(viewModel.shouldDismiss)
    }
    
    @MainActor
    func testLoadPhotos_initLoadPhotos_shouldUpdateContentLibraryAndSortToNewest() async throws {
        let cloudPhotos = try makeSamplePhotoNodes()
        let cameraUploadPhotos = [NodeEntity(name: "TestVideo.mp4", handle: 6, hasThumbnail: true, modificationTime: try "2023-01-01T22:05:04Z".date)]
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCloudDriveOnly: cloudPhotos, allPhotosFromCameraUpload: cameraUploadPhotos)
        await sut.photosLoadingTask?.value
        let expectedPhotos = (cloudPhotos + cameraUploadPhotos).filter { $0.hasThumbnail }
            .toPhotoLibrary(withSortType: .modificationDesc)
            .allPhotos
        XCTAssertEqual(sut.photoLibraryContentViewModel.library.allPhotos, expectedPhotos)
    }
    
    @MainActor
    func testNavigationTitle_whenAddedContent_shouldReturnThreeDifferentResults() {
        let sut = makeAlbumContentPickerViewModel()
        let node1 = NodeEntity(name: "a.png", handle: HandleEntity(1))
        let node2 = NodeEntity(name: "b.png", handle: HandleEntity(2))
        
        let normalNavTitle = "Add items to “Custom Name”"
        XCTAssertEqual(sut.navigationTitle, normalNavTitle)
        
        let exp = expectation(description: "title updates when selection changes")
        exp.expectedFulfillmentCount = 3
        
        var result = [String]()
        sut.$navigationTitle
            .dropFirst(2)
            .sink {
                result.append($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([node1])
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([node1, node2])
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([])
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [
            "1 item selected",
            "2 items selected",
            normalNavTitle
        ])
    }
    
    @MainActor
    func testOnFilter_shouldSetShowFilterToTrue() {
        let sut = makeAlbumContentPickerViewModel()
        XCTAssertFalse(sut.photoLibraryContentViewModel.showFilter)
        
        sut.onFilter()
        
        XCTAssertTrue(sut.photoLibraryContentViewModel.showFilter)
    }
    
    @MainActor
    func testPhotoSourceLocation_onContentLoadForAllLocations_shouldChangeToCloudDriveIfOnlyCloudDriveItemsLoaded() async {
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCloudDriveOnly: [NodeEntity(name: "Test 1.jpg", handle: 1, hasThumbnail: true)])
        XCTAssertEqual(sut.photoSourceLocation, .allLocations)
        XCTAssertEqual(sut.photoSourceLocationNavigationTitle, "")
        await sut.photosLoadingTask?.value
        let expectedLocation: PhotosFilterLocation = .cloudDrive
        XCTAssertEqual(sut.photoSourceLocation, expectedLocation)
        XCTAssertEqual(sut.photoSourceLocationNavigationTitle, expectedLocation.localization)
    }
    
    @MainActor
    func testPhotoSourceLocation_onContentLoadForAllLocations_shouldChangeToCameraUploadIfOnlyCameraUploadItemsLoaded() async {
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCameraUpload: [NodeEntity(name: "Test 1.jpg", handle: 1, hasThumbnail: true)])
        XCTAssertEqual(sut.photoSourceLocation, .allLocations)
        XCTAssertEqual(sut.photoSourceLocationNavigationTitle, "")
        await sut.photosLoadingTask?.value
        let expectedLocation: PhotosFilterLocation = .cameraUploads
        XCTAssertEqual(sut.photoSourceLocation, expectedLocation)
        XCTAssertEqual(sut.photoSourceLocationNavigationTitle, expectedLocation.localization)
    }
    
    @MainActor
    func testPhotoSourceLocation_onContentLoadForAllLocations_shouldNotChangeIfCloudDriveAndCameraUploadItemsLoaded() async {
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCloudDriveOnly: [NodeEntity(name: "Test 1.jpg", handle: 1, hasThumbnail: true)],
                                                  allPhotosFromCameraUpload: [NodeEntity(name: "Test 2.jpg", handle: 2, hasThumbnail: true)])
        XCTAssertEqual(sut.photoSourceLocationNavigationTitle, "")
        let expectedLocation: PhotosFilterLocation = .allLocations
        XCTAssertEqual(sut.photoSourceLocation, expectedLocation)
        await sut.photosLoadingTask?.value
        XCTAssertEqual(sut.photoSourceLocation, expectedLocation)
        XCTAssertEqual(sut.photoSourceLocationNavigationTitle, expectedLocation.localization)
    }
    
    @MainActor
    func testPhotoSourceLocation_onContentLoad_shouldNotChangeSourceLocationIfItsTheSame() async {
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCloudDriveOnly: [NodeEntity(name: "Test 1.jpg", handle: 1, hasThumbnail: true)],
                                                  allPhotosFromCameraUpload: [NodeEntity(name: "Test 2.jpg", handle: 2, hasThumbnail: true)])
        XCTAssertEqual(sut.photoSourceLocation, .allLocations)
        await sut.photosLoadingTask?.value
        let exp = expectation(description: "Should not change if the same")
        exp.isInverted = true
        sut.$photoSourceLocation
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.photoLibraryContentViewModel.filterViewModel.appliedFilterLocation = .allLocations
        await sut.photosLoadingTask?.value
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.photoSourceLocation, .allLocations)
    }
    
    @MainActor
    func testPhotoSourceLocationNavigationTitle_onContentLoad_shouldNotChangeNavTitleIfItsTheSame() async {
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCloudDriveOnly: [NodeEntity(name: "Test 1.jpg", handle: 1, hasThumbnail: true)],
                                                  allPhotosFromCameraUpload: [NodeEntity(name: "Test 2.jpg", handle: 2, hasThumbnail: true)])
        let expectedLocation: PhotosFilterLocation = .allLocations
        sut.photoSourceLocationNavigationTitle = expectedLocation.localization
        XCTAssertEqual(sut.photoSourceLocation, expectedLocation)
        await sut.photosLoadingTask?.value
        let exp = expectation(description: "Should not change if the same")
        exp.isInverted = true
        sut.$photoSourceLocationNavigationTitle
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.photoLibraryContentViewModel.filterViewModel.appliedFilterLocation = expectedLocation
        await sut.photosLoadingTask?.value
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.photoSourceLocationNavigationTitle, expectedLocation.localization)
    }
    
    @MainActor
    func testContentLibrary_onContentLocationCloudDrive_shouldDisplaySortedCloudDrivePhotos() async throws {
        let cloudDrivePhotos = try makeSamplePhotoNodes()
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCloudDriveOnly: cloudDrivePhotos, allPhotosFromCameraUpload: [])
        XCTAssertEqual(sut.photoSourceLocation, .allLocations)
        await sut.photosLoadingTask?.value
        
        sut.photoLibraryContentViewModel.filterViewModel.appliedFilterLocation = .cloudDrive
        await sut.photosLoadingTask?.value
        
        let expectedPhotos = cloudDrivePhotos.filter { $0.hasThumbnail }
            .toPhotoLibrary(withSortType: .modificationDesc)
            .allPhotos
        XCTAssertEqual(sut.photoLibraryContentViewModel.library.allPhotos, expectedPhotos)
        XCTAssertEqual(sut.photoSourceLocation, .cloudDrive)
    }
    
    @MainActor
    func testContentLibrary_onContentCameraUpload_shouldDisplaySortedCameraUploadPhotos() async throws {
        let cameraUploadPhotos = try makeSamplePhotoNodes()
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCloudDriveOnly: [], allPhotosFromCameraUpload: cameraUploadPhotos)
        XCTAssertEqual(sut.photoSourceLocation, .allLocations)
        await sut.photosLoadingTask?.value
        
        sut.photoLibraryContentViewModel.filterViewModel.appliedFilterLocation = .cameraUploads
        await sut.photosLoadingTask?.value
        
        let expectedPhotos = cameraUploadPhotos.filter { $0.hasThumbnail }
            .toPhotoLibrary(withSortType: .modificationDesc)
            .allPhotos
        XCTAssertEqual(sut.photoLibraryContentViewModel.library.allPhotos, expectedPhotos)
        XCTAssertEqual(sut.photoSourceLocation, .cameraUploads)
    }
    
    @MainActor
    func testShouldRemoveFilter_onPhotoRetrieval_shouldNotHideFilterIfCloudDriveAndCameraUploadContainsPhotos() async {
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCloudDriveOnly: [NodeEntity(name: "Test 1.jpg", handle: 1, hasThumbnail: true)],
                                                  allPhotosFromCameraUpload: [NodeEntity(name: "Test 2.jpg", handle: 2, hasThumbnail: true)])
        XCTAssertTrue(sut.shouldRemoveFilter)
        await sut.photosLoadingTask?.value
        XCTAssertFalse(sut.shouldRemoveFilter)
    }
    
    @MainActor
    func testShouldRemoveFilter_onPhotoRetrieval_shouldHideFilterIfCloudDriveOnlyContainsPhotos() async {
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCloudDriveOnly: [NodeEntity(name: "Test 1.jpg", handle: 1, hasThumbnail: true)])
        XCTAssertTrue(sut.shouldRemoveFilter)
        await sut.photosLoadingTask?.value
        XCTAssertTrue(sut.shouldRemoveFilter)
    }
    
    @MainActor
    func testShouldRemoveFilter_onPhotoRetrieval_shouldHideFilterIfCameraUploadsOnlyContainsPhotos() async {
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCameraUpload: [NodeEntity(name: "Test 1.jpg", handle: 1, hasThumbnail: true)])
        XCTAssertTrue(sut.shouldRemoveFilter)
        await sut.photosLoadingTask?.value
        XCTAssertTrue(sut.shouldRemoveFilter)
    }
    
    @MainActor
    func testShouldRemoveFilter_onPhotoRetrieval_shouldNotPublishAgainIfTheSame() async {
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCameraUpload: [NodeEntity(name: "Test 1.jpg", handle: 1, hasThumbnail: true)])
        
        let exp = expectation(description: "Should not hide again")
        exp.isInverted = true
        sut.$shouldRemoveFilter
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        await sut.photosLoadingTask?.value
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertTrue(sut.shouldRemoveFilter)
    }
    
    @MainActor
    func testIsDoneButtonDisabled_onItemsSelected_shouldChangeButNotEmitDuplicates() {
        let sut = makeAlbumContentPickerViewModel()
        XCTAssertTrue(sut.isDoneButtonDisabled)
        XCTAssertTrue(sut.photoLibraryContentViewModel.selection.photos.isEmpty)
        
        let exp = expectation(description: "Should change disabled state")
        exp.expectedFulfillmentCount = 4
        var result = [Bool]()
        sut.$isDoneButtonDisabled
            .dropFirst()
            .sink {
                result.append($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        let selectedPhoto = NodeEntity(name: "photo1.jpg", handle: 1)
        let selectedPhotos = [selectedPhoto.handle: selectedPhoto]
        sut.photoLibraryContentViewModel.selection.photos = selectedPhotos
        sut.photoLibraryContentViewModel.selection.photos = selectedPhotos
        sut.photoLibraryContentViewModel.selection.photos = [:]
        sut.photoLibraryContentViewModel.selection.photos = selectedPhotos
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [true, false, true, false])
    }
    
    @MainActor
    func testIsDoneButtonDisabled_onItemsSelectedWithNewAlbum_shouldNotChangeOnItemSelection() {
        let album = AlbumEntity(id: 4, name: "Custom Name", coverNode: NodeEntity(handle: 4), count: 0, type: .user)
        let sut = AlbumContentPickerViewModel(album: album,
                                              photoLibraryUseCase:
                                                MockPhotoLibraryUseCase(),
                                              completion: { _, _ in
        }, isNewAlbum: true)
        XCTAssertFalse(sut.isDoneButtonDisabled)
        
        let exp = expectation(description: "Should not change disabled state")
        exp.isInverted = true
        sut.$isDoneButtonDisabled
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        let selectedPhoto = NodeEntity(name: "photo1.jpg", handle: 1)
        let selectedPhotos = [selectedPhoto.handle: selectedPhoto]
        sut.photoLibraryContentViewModel.selection.photos = selectedPhotos
        sut.photoLibraryContentViewModel.selection.photos = [:]
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertFalse(sut.isDoneButtonDisabled)
    }
    
    @MainActor
    func testShowSelectionLimitReachedAlert_onIsItemSelectedAfterLimitReached_shouldToggleAlert() {
        let sut = makeAlbumContentPickerViewModel()
        XCTAssertFalse(sut.showSelectionLimitReachedAlert)
        sut.photoLibraryContentViewModel.selection.isItemSelectedAfterLimitReached = true
        XCTAssertTrue(sut.showSelectionLimitReachedAlert)
    }
    
    @MainActor
    private func makeAlbumContentPickerViewModel(allPhotos: [NodeEntity] = [],
                                                 allPhotosFromCloudDriveOnly: [NodeEntity] = [],
                                                 allPhotosFromCameraUpload: [NodeEntity] = [],
                                                 completion: @escaping ((AlbumEntity, [NodeEntity]) -> Void) = {_, _ in },
                                                 configuration: PhotoLibraryContentConfiguration = PhotoLibraryContentConfiguration()) -> AlbumContentPickerViewModel {
        let album = AlbumEntity(id: 4, name: "Custom Name", coverNode: NodeEntity(handle: 4), count: 0, type: .user)
        return AlbumContentPickerViewModel(album: album,
                                           photoLibraryUseCase:
                                            MockPhotoLibraryUseCase(
                                                allPhotos: allPhotos,
                                                allPhotosFromCloudDriveOnly: allPhotosFromCloudDriveOnly,
                                                allPhotosFromCameraUpload: allPhotosFromCameraUpload),
                                           completion: completion,
                                           configuration: configuration)
    }
    
    private func makeSamplePhotoNodes() throws -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 1, parentHandle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:01:04Z".date)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 2, parentHandle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:02:04Z".date)
        let node3 = NodeEntity(nodeType: .file, name: "TestImage3.png", handle: 3, parentHandle: 1, hasThumbnail: false, modificationTime: try "2022-08-18T22:03:04Z".date)
        let node4 = NodeEntity(nodeType: .file, name: "TestImage4.png", handle: 4, parentHandle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:04:04Z".date)
        let node5 = NodeEntity(nodeType: .file, name: "TestVideo.mp4", handle: 5, parentHandle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:05:04Z".date)
        
        return [node1, node2, node3, node4, node5]
    }
}
