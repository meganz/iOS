import MEGADomain
import MEGADomainMock
import XCTest

final class PhotoLibraryUseCaseTests: XCTestCase {
    
    var cloudDriveNode: NodeEntity {
        NodeEntity(nodeType: .folder, name: "Cloud Drive", handle: 1, parentHandle: 0)
    }
    
    var cameraUploadNode: NodeEntity {
        NodeEntity(nodeType: .folder, name: "Camera Upload", handle: 2, parentHandle: 1)
    }
    
    var mediaUploadNode: NodeEntity {
        NodeEntity(nodeType: .folder, name: "Media Upload", handle: 3, parentHandle: 1)
    }
    
    // MARK: - Test cases
    
    func testAllPhotos_withCloudDrive_shouldReturnTrue() async throws {
        let videoNodes = sampleVideoNodesForCloudDrive()
        let imageNodes = sampleImageNodesForCloudDrive()
        let photosRepo = MockPhotosLibraryRepository.newRepo
        let fileSearchRepo = MockFilesSearchRepository(photoNodes: imageNodes, videoNodes: videoNodes)
        let expectedCount = videoNodes.count + imageNodes.count
        
        let usecase = PhotoLibraryUseCase(photosRepository: photosRepo, searchRepository: fileSearchRepo)
        
        do {
            let photos = try await usecase.allPhotos()
            XCTAssertTrue(photos.count == expectedCount)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    func testAllPhotos_withCameraUploads_shouldReturnTrue() async throws {
        var photosRepo = MockPhotosLibraryRepository.newRepo
        let fileSearchRepo = MockFilesSearchRepository.newRepo
        
        photosRepo.cameraUploadNode = cameraUploadNode
        photosRepo.mediaUploadNode = mediaUploadNode
        let nodesInCameraUpload  = samplePhotoNodesFromCameraUpload()
        let nodesInMediaUpload = samplePhotoNodesFromMediaUpload()
        photosRepo.nodesInCameraUpload = nodesInCameraUpload
        photosRepo.nodesInMediaUpload = nodesInMediaUpload
        
        let expectedCount = nodesInCameraUpload.count + nodesInMediaUpload.count
        let usecase = PhotoLibraryUseCase(photosRepository: photosRepo, searchRepository: fileSearchRepo)
        
        do {
            let photos = try await usecase.allPhotosFromCameraUpload()
            XCTAssertTrue(photos.count == expectedCount)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    func testAllPhotos_withCloudDriveOnly_shouldReturnTrue() async throws {
        var photosRepo = MockPhotosLibraryRepository.newRepo
        let videoNodes = sampleVideoNodesForCloudDrive()
        let imageNodes = sampleImageNodesForCloudDrive()
        let fileSearchRepo = MockFilesSearchRepository(photoNodes: imageNodes, videoNodes: videoNodes)
        
        photosRepo.cameraUploadNode = cameraUploadNode
        photosRepo.mediaUploadNode = mediaUploadNode
        
        let expectedCount = 4
        let usecase = PhotoLibraryUseCase(photosRepository: photosRepo, searchRepository: fileSearchRepo)
        
        do {
            let photos = try await usecase.allPhotosFromCloudDriveOnly()
            XCTAssertTrue(photos.count == expectedCount)
        } catch {
            assertionFailure("Unexpected exception!")
        }
    }
    
    // MARK: - Private
    
    private func sampleImageNodesForCloudDrive() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 4, parentHandle: 1)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 5, parentHandle: 1)
        let node3 = NodeEntity(nodeType: .file, name: "TestImage3.png", handle: 6, parentHandle: 2)
        let node4 = NodeEntity(nodeType: .file, name: "TestImage4.png", handle: 7, parentHandle: 3)
        
        return [node1, node2, node3, node4]
    }
    
    private func sampleVideoNodesForCloudDrive() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 4, parentHandle: 1)
        let node2 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 5, parentHandle: 1)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo3.mp4", handle: 6, parentHandle: 2)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo4.mp4", handle: 7, parentHandle: 3)
        
        return [node1, node2, node3, node4]
    }
    
    private func samplePhotoNodesFromCameraUpload() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 4, parentHandle: 2)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 5, parentHandle: 2)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 6, parentHandle: 2)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 7, parentHandle: 2)
        
        return [node1, node2, node3, node4]
    }
    
    private func samplePhotoNodesFromMediaUpload() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 4, parentHandle: 3)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 5, parentHandle: 3)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 6, parentHandle: 3)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 7, parentHandle: 3)
        
        return [node1, node2, node3, node4]
    }
}
