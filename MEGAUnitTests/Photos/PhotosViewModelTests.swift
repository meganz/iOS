import XCTest
import MEGADomainMock
@testable import MEGA
@testable import MEGADomain

@MainActor
final class PhotosViewModelTests: XCTestCase {
    var sut: PhotosViewModel!
    
    override func setUp() {
        let publisher = PhotoUpdatePublisher(photosViewController: PhotosViewController())
        let allPhotos = sampleNodesForAllLocations()
        let allPhotosForCloudDrive = sampleNodesForCloudDriveOnly()
        let allPhotosForCameraUploads = sampleNodesForCameraUploads()
        let usecase = MockPhotoLibraryUseCase(allPhotos: allPhotos,
                                              allPhotosFromCloudDriveOnly: allPhotosForCloudDrive,
                                              allPhotosFromCameraUpload: allPhotosForCameraUploads)
        
        sut = PhotosViewModel(photoUpdatePublisher: publisher, photoLibraryUseCase: usecase, mediaUseCase: MockMediaUseCase())
    }
    
    func testLoadSortOrderType() throws {
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
    
    // MARK: - All locations test cases
    
    func testLoadingPhotos_withAllMediaAllLocations_shouldReturnTrue() async throws {
        let expectedPhotos = sampleNodesForAllLocations()
        sut.filterType = .allMedia
        sut.filterLocation = . allLocations
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodesArray, expectedPhotos)
    }
    
    func testLoadingPhotos_withImagesAllLocations_shouldReturnTrue() async throws {
        let expectedImages = sampleNodesForAllLocations().filter({ $0.name?.mnz_isImagePathExtension == true })
        sut.filterType = .images
        sut.filterLocation = . allLocations
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodesArray, expectedImages)
    }
    
    func testLoadingVideos_withImagesAllLocations_shouldReturnTrue() async throws {
        let expectedVideos = sampleNodesForAllLocations().filter({ $0.name?.mnz_isVideoPathExtension == true })
        sut.filterType = .videos
        sut.filterLocation = . allLocations
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodesArray, expectedVideos)
    }
    
    // MARK: - Cloud Drive only test cases
    
    func testLoadingPhotos_withAllMediaFromCloudDrive_shouldReturnTrue() async throws {
        let expectedPhotos = sampleNodesForCloudDriveOnly()
        sut.filterType = .allMedia
        sut.filterLocation = .cloudDrive
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodesArray, expectedPhotos)
    }
    
    func testLoadingPhotos_withImagesFromCloudDrive_shouldReturnTrue() async throws {
        let expectedImages = sampleNodesForCloudDriveOnly().filter({ $0.name?.mnz_isImagePathExtension == true })
        sut.filterType = .images
        sut.filterLocation = .cloudDrive
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodesArray, expectedImages)
    }
    
    func testLoadingPhotos_withVideosFromCloudDrive_shouldReturnTrue() async throws {
        let expectedVideos = sampleNodesForCloudDriveOnly().filter({ $0.name?.mnz_isVideoPathExtension == true })
        sut.filterType = .videos
        sut.filterLocation = .cloudDrive
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodesArray, expectedVideos)
    }
    
    // MARK: - Camera Uploads test cases
    
    func testLoadingPhotos_withAllMediaFromCameraUploads_shouldReturnTrue() async throws {
        let expectedPhotos = sampleNodesForCameraUploads()
        sut.filterType = .allMedia
        sut.filterLocation = .cameraUploads
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodesArray, expectedPhotos)
    }
    
    func testLoadingPhotos_withImagesFromCameraUploads_shouldReturnTrue() async throws {
        let expectedImages = sampleNodesForCameraUploads().filter({ $0.name?.mnz_isImagePathExtension == true })
        sut.filterType = .images
        sut.filterLocation = .cameraUploads
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodesArray, expectedImages)
    }
    
    func testLoadingPhotos_withVideosFromCameraUploads_shouldReturnTrue() async throws {
        let expectedVideos = sampleNodesForCameraUploads().filter({ $0.name?.mnz_isVideoPathExtension == true })
        sut.filterType = .videos
        sut.filterLocation = .cameraUploads
        await sut.loadPhotos()
        XCTAssertEqual(sut.mediaNodesArray, expectedVideos)
    }
    
    private func sampleNodesForAllLocations() ->[MEGANode] {
        let node1 = MockNode(handle: 1, name: "TestImage1.png", nodeType: .file, parentHandle: 0, hasThumbnail: true)
        let node2 = MockNode(handle: 2, name: "TestImage2.png", nodeType: .file, parentHandle: 1, hasThumbnail: true)
        let node3 = MockNode(handle: 3, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 2, hasThumbnail: true)
        let node4 = MockNode(handle: 4, name: "TestVideo2.mp4", nodeType: .file, parentHandle: 3, hasThumbnail: true)
        let node5 = MockNode(handle: 5, name: "TestImage1.png", nodeType: .file, parentHandle: 4, hasThumbnail: true)
        let node6 = MockNode(handle: 6, name: "TestImage2.png", nodeType: .file, parentHandle: 5, hasThumbnail: true)
        let node7 = MockNode(handle: 7, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 6, hasThumbnail: true)
        let node8 = MockNode(handle: 8, name: "TestVideo2.mp4", nodeType: .file, parentHandle: 7, hasThumbnail: true)
        
        return [node1, node2, node3, node4, node5, node6, node7, node8]
    }
    
    private func sampleNodesForCloudDriveOnly() ->[MEGANode] {
        let node1 = MockNode(handle: 1, name: "TestImage1.png", nodeType: .file, parentHandle: 0, hasThumbnail: true)
        let node2 = MockNode(handle: 2, name: "TestImage2.png", nodeType: .file, parentHandle: 1, hasThumbnail: true)
        let node3 = MockNode(handle: 3, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 2, hasThumbnail: true)
        let node4 = MockNode(handle: 4, name: "TestVideo2.mp4", nodeType: .file, parentHandle: 3, hasThumbnail: true)
        
        return [node1, node2, node3, node4]
    }
    
    private func sampleNodesForCameraUploads() ->[MEGANode] {
        let node5 = MockNode(handle: 5, name: "TestImage1.png", nodeType: .file, parentHandle: 4, hasThumbnail: true)
        let node6 = MockNode(handle: 6, name: "TestImage2.png", nodeType: .file, parentHandle: 5, hasThumbnail: true)
        let node7 = MockNode(handle: 7, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 6, hasThumbnail: true)
        let node8 = MockNode(handle: 8, name: "TestVideo2.mp4", nodeType: .file, parentHandle: 7, hasThumbnail: true)
        
        return [node5, node6, node7, node8]
    }
    
    private func photosViewModelForFeatureFlag(provider: FeatureFlagProviderProtocol) -> PhotosViewModel {
        let publisher = PhotoUpdatePublisher(photosViewController: PhotosViewController())
        let usecase = MockPhotoLibraryUseCase(allPhotos: [],
                                              allPhotosFromCloudDriveOnly: [],
                                              allPhotosFromCameraUpload: [])
        return PhotosViewModel(photoUpdatePublisher: publisher,
                               photoLibraryUseCase: usecase,
                               mediaUseCase: MockMediaUseCase(),
                               featureFlagProvider: provider)
    }
}
