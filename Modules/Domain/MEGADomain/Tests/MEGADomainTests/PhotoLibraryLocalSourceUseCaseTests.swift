import MEGADomain
import MEGADomainMock
import XCTest

final class PhotoLibraryLocalSourceUseCaseTests: XCTestCase {
    private let cameraUploadNode = NodeEntity(handle: 4)
    private let mediaUploadNode = NodeEntity(handle: 56)
    
    private lazy var cameraUploadNodes = [NodeEntity(handle: 3, parentHandle: cameraUploadNode.handle),
                                          NodeEntity(handle: 22, parentHandle: cameraUploadNode.handle)]
    
    func testPhotoLibraryContainer_cameraAndMediaSourceNode_shouldReturnCorrectNodes() async {
        let photoLibraryRepository = MockPhotoLibraryRepository(cameraUploadNode: cameraUploadNode, mediaUploadNode: mediaUploadNode)
        let sut = makeSUT(photoLibraryRepository: photoLibraryRepository)
        
        let container = await sut.photoLibraryContainer()
        
        XCTAssertEqual(container.cameraUploadNode, cameraUploadNode)
        XCTAssertEqual(container.mediaUploadNode, mediaUploadNode)
    }
    
    func testAllPhotos_shouldReturnAllPhotos() async throws {
        let photos = [NodeEntity(handle: 5),
                      NodeEntity(handle: 95),
                      NodeEntity(handle: 56)]
        let photosRepository = MockPhotosRepository(photos: photos)
        let sut = makeSUT(photosRepository: photosRepository)
        
        let allPhotos = try await sut.allPhotos()
        
        XCTAssertEqual(allPhotos, photos)
    }
    
    func testAllPhotosFromCloudDriveOnly_cameraAndMediaSourceNode_shouldReturnCorrectPhotos() async throws {
        let cloudDriveNodes = [NodeEntity(handle: 5, parentHandle: 1),
                               NodeEntity(handle: 5, parentHandle: 87)]
        let allPhotos = cameraUploadNodes + cloudDriveNodes
        
        let photoLibraryRepository = MockPhotoLibraryRepository(cameraUploadNode: cameraUploadNode)
        let photosRepository = MockPhotosRepository(photos: allPhotos)
        let sut = makeSUT(photoLibraryRepository: photoLibraryRepository,
                          photosRepository: photosRepository)
        
        let photos = try await sut.allPhotosFromCloudDriveOnly()
        
        XCTAssertEqual(photos, cloudDriveNodes)
    }
    
    func testAllPhotosFromCameraUpload_cameraAndMediaSourceNode_shouldReturnCorrectPhotos() async throws {
        let mediaUploadNodes = [NodeEntity(handle: 6, parentHandle: mediaUploadNode.handle)]
        let otherCloudDriveNodes = [NodeEntity(handle: 5, parentHandle: 77)]
        let allPhotos = cameraUploadNodes + mediaUploadNodes + otherCloudDriveNodes
        
        let photoLibraryRepository = MockPhotoLibraryRepository(cameraUploadNode: cameraUploadNode,
                                                                 mediaUploadNode: mediaUploadNode)
        let photosRepository = MockPhotosRepository(photos: allPhotos)
        let sut = makeSUT(photoLibraryRepository: photoLibraryRepository,
                          photosRepository: photosRepository)
        
        let photos = try await sut.allPhotosFromCameraUpload()
        
        XCTAssertEqual(photos, cameraUploadNodes + mediaUploadNodes)
    }
    
    private func makeSUT(photoLibraryRepository: MockPhotoLibraryRepository = MockPhotoLibraryRepository(),
                         photosRepository: MockPhotosRepository = MockPhotosRepository())
    -> PhotoLibraryLocalSourceUseCase<MockPhotoLibraryRepository, MockPhotosRepository> {
        PhotoLibraryLocalSourceUseCase(photoLibraryRepository: photoLibraryRepository,
                     photosRepository: photosRepository)
    }
}
