import XCTest
@testable import MEGA

final class PhotosViewModelTests: XCTestCase {
    var photosViewModel: PhotosViewModel?
    
    override func setUp() {
        let publisher = PhotoUpdatePublisher(photosViewController: PhotosViewController())
        let allPhotos = sampleNodesForAllLocations()
        let allPhotosForCloudDrive = sampleNodesForCloudDriveOnly()
        let allPhotosForCameraUploads = sampleNodesForCameraUploads()
        let usecase = MockPhotoLibraryUseCase(allPhotos: allPhotos,
                                              allPhotosFromCloudDriveOnly: allPhotosForCloudDrive,
                                              allPhotosFromCameraUpload: allPhotosForCameraUploads)
        
        photosViewModel = PhotosViewModel(photoUpdatePublisher: publisher, photoLibraryUseCase: usecase)
    }
    
    private func mediaNodesSorted() -> [MEGANode] {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
        
        return [
            MockNode(handle: 1, name: "TestImage.png", nodeType: .file, parentHandle:0, modificationTime: today),
            MockNode(handle: 2, name: "TestVideo1.mp4", nodeType: .file, parentHandle:0),
            MockNode(handle: 2, name: "TestImage2.jpg", nodeType: .file, parentHandle:1, modificationTime: yesterday)
        ]
    }
    
    private func mediaNodesReverseSorted() -> [MEGANode] {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)
        
        return [
            MockNode(handle: 2, name: "TestImage2.jpg", nodeType: .file, parentHandle:1, modificationTime: yesterday),
            MockNode(handle: 1, name: "TestImage.png", nodeType: .file, parentHandle:0, modificationTime: today),
            MockNode(handle: 2, name: "TestVideo1.mp4", nodeType: .file, parentHandle:0)
        ]
    }
    
    func testLoadSortOrderType() throws {
        guard let sut = photosViewModel else { return }
        
        Helper.save(.defaultAsc, for: PhotosViewModel.SortingKeys.cameraUploadExplorerFeed.rawValue)
        let sortTypeUnknown = sut.sortOrderType(forKey: .cameraUploadExplorerFeed)
        XCTAssert(sortTypeUnknown == .newest)
        
        Helper.save(.modificationAsc, for: PhotosViewModel.SortingKeys.cameraUploadExplorerFeed.rawValue)
        let sortTypeOldest = sut.sortOrderType(forKey: .cameraUploadExplorerFeed)
        XCTAssert(sortTypeOldest == .oldest)
        
        Helper.save(.modificationDesc, for: PhotosViewModel.SortingKeys.cameraUploadExplorerFeed.rawValue)
        let sortTypeNewest = sut.sortOrderType(forKey: .cameraUploadExplorerFeed)
        XCTAssert(sortTypeNewest == .newest)
    }
    
    func testReorderPhotos() throws {
        guard let sut = photosViewModel else { return }
        
        sut.mediaNodesArray = mediaNodesSorted()
        
        sut.cameraUploadExplorerSortOrderType = .nameAscending
        XCTAssert(sut.mediaNodesArray == mediaNodesSorted())
        
        sut.cameraUploadExplorerSortOrderType = .newest
        XCTAssert(sut.mediaNodesArray == mediaNodesSorted())
        
        sut.cameraUploadExplorerSortOrderType = .oldest
        XCTAssert(sut.mediaNodesArray == mediaNodesReverseSorted())
    }
    
    // MARK: - All locations test cases
    
    func testLoadingPhotos_withAllMediaAllLocations_shouldReturnTrue() async throws {
        guard let photoVM = photosViewModel else { return }
        
        let expectedPhotos = sampleNodesForAllLocations()
        photoVM.filterType = .allMedia
        photoVM.filterLocation = . allLocations
        
        do {
            let photos = try await photoVM.loadFilteredPhotos()
            XCTAssertTrue(photos.count == expectedPhotos.count)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    func testLoadingPhotos_withImagesAllLocations_shouldReturnTrue() async throws {
        guard let photoVM = photosViewModel else { return }
        
        let expectedImages = sampleNodesForAllLocations().filter({ $0.name?.mnz_isImagePathExtension == true })
        photoVM.filterType = .images
        photoVM.filterLocation = . allLocations
        
        do {
            let photos = try await photoVM.loadFilteredPhotos()
            XCTAssertTrue(photos.count == expectedImages.count)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    func testLoadingVideos_withImagesAllLocations_shouldReturnTrue() async throws {
        guard let photoVM = photosViewModel else { return }
        
        let expectedVideos = sampleNodesForAllLocations().filter({ $0.name?.mnz_isVideoPathExtension == true })
        photoVM.filterType = .videos
        photoVM.filterLocation = . allLocations
        
        do {
            let photos = try await photoVM.loadFilteredPhotos()
            XCTAssertTrue(photos.count == expectedVideos.count)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    // MARK: - Cloud Drive only test cases
    
    func testLoadingPhotos_withAllMediaFromCloudDrive_shouldReturnTrue() async throws {
        guard let photoVM = photosViewModel else { return }
        
        let expectedPhotos = sampleNodesForCloudDriveOnly()
        photoVM.filterType = .allMedia
        photoVM.filterLocation = .cloudDrive
        
        do {
            let photos = try await photoVM.loadFilteredPhotos()
            XCTAssertTrue(photos.count == expectedPhotos.count)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    func testLoadingPhotos_withImagesFromCloudDrive_shouldReturnTrue() async throws {
        guard let photoVM = photosViewModel else { return }
        
        let expectedImages = sampleNodesForCloudDriveOnly().filter({ $0.name?.mnz_isImagePathExtension == true })
        photoVM.filterType = .images
        photoVM.filterLocation = .cloudDrive
        
        do {
            let photos = try await photoVM.loadFilteredPhotos()
            XCTAssertTrue(photos.count == expectedImages.count)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    func testLoadingPhotos_withVideosFromCloudDrive_shouldReturnTrue() async throws {
        guard let photoVM = photosViewModel else { return }
        
        let expectedVideos = sampleNodesForCloudDriveOnly().filter({ $0.name?.mnz_isVideoPathExtension == true })
        photoVM.filterType = .videos
        photoVM.filterLocation = .cloudDrive
        
        do {
            let photos = try await photoVM.loadFilteredPhotos()
            XCTAssertTrue(photos.count == expectedVideos.count)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    // MARK: - Camera Uploads test cases
    
    func testLoadingPhotos_withAllMediaFromCameraUploads_shouldReturnTrue() async throws {
        guard let photoVM = photosViewModel else { return }
        
        let expectedPhotos = sampleNodesForCameraUploads()
        photoVM.filterType = .allMedia
        photoVM.filterLocation = .cameraUploads
        
        do {
            let photos = try await photoVM.loadFilteredPhotos()
            XCTAssertTrue(photos.count == expectedPhotos.count)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    func testLoadingPhotos_withImagesFromCameraUploads_shouldReturnTrue() async throws {
        guard let photoVM = photosViewModel else { return }
        
        let expectedImages = sampleNodesForCameraUploads().filter({ $0.name?.mnz_isImagePathExtension == true })
        photoVM.filterType = .images
        photoVM.filterLocation = .cameraUploads
        
        do {
            let photos = try await photoVM.loadFilteredPhotos()
            XCTAssertTrue(photos.count == expectedImages.count)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    func testLoadingPhotos_withVideosFromCameraUploads_shouldReturnTrue() async throws {
        guard let photoVM = photosViewModel else { return }
        
        let expectedVideos = sampleNodesForCameraUploads().filter({ $0.name?.mnz_isVideoPathExtension == true })
        photoVM.filterType = .videos
        photoVM.filterLocation = .cameraUploads
        
        do {
            let photos = try await photoVM.loadFilteredPhotos()
            XCTAssertTrue(photos.count == expectedVideos.count)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    private func sampleNodesForAllLocations() ->[MEGANode] {
        let node1 = MockNode(handle: 1, name: "TestImage1.png", nodeType: .file, parentHandle: 0)
        let node2 = MockNode(handle: 2, name: "TestImage2.png", nodeType: .file, parentHandle: 1)
        let node3 = MockNode(handle: 3, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 2)
        let node4 = MockNode(handle: 4, name: "TestVideo2.mp4", nodeType: .file, parentHandle: 3)
        let node5 = MockNode(handle: 5, name: "TestImage1.png", nodeType: .file, parentHandle: 4)
        let node6 = MockNode(handle: 6, name: "TestImage2.png", nodeType: .file, parentHandle: 5)
        let node7 = MockNode(handle: 7, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 6)
        let node8 = MockNode(handle: 8, name: "TestVideo2.mp4", nodeType: .file, parentHandle: 7)
        
        return [node1, node2, node3, node4, node5, node6, node7, node8]
    }
    
    private func sampleNodesForCloudDriveOnly() ->[MEGANode] {
        let node1 = MockNode(handle: 1, name: "TestImage1.png", nodeType: .file, parentHandle: 0)
        let node2 = MockNode(handle: 2, name: "TestImage2.png", nodeType: .file, parentHandle: 1)
        let node3 = MockNode(handle: 3, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 2)
        let node4 = MockNode(handle: 4, name: "TestVideo2.mp4", nodeType: .file, parentHandle: 3)
        
        return [node1, node2, node3, node4]
    }
    
    private func sampleNodesForCameraUploads() ->[MEGANode] {
        let node5 = MockNode(handle: 5, name: "TestImage1.png", nodeType: .file, parentHandle: 4)
        let node6 = MockNode(handle: 6, name: "TestImage2.png", nodeType: .file, parentHandle: 5)
        let node7 = MockNode(handle: 7, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 6)
        let node8 = MockNode(handle: 8, name: "TestVideo2.mp4", nodeType: .file, parentHandle: 7)
        
        return [node5, node6, node7, node8]
    }
}
