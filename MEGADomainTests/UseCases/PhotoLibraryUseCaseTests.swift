import XCTest
@testable import MEGA

final class PhotoLibraryUseCaseTests: XCTestCase {
    
    var cloudDriveNode: MockNode {
        MockNode(handle: 1, name: "Cloud Drive", nodeType: .folder, parentHandle: 0)
    }
    
    var cameraUploadNode: MockNode {
        MockNode(handle: 2, name: "Camera Upload", nodeType: .folder, parentHandle: 1)
    }
    
    var mediaUploadNode: MockNode {
        MockNode(handle: 3, name: "Media Upload", nodeType: .folder, parentHandle: 1)
    }
    
    // MARK: - Test cases
    
    func testAllPhotos_withCloudDrive_shouldReturnTrue() async throws {
        let photosRepo = MockPhotosLibraryRepository.newRepo
        let fileSearchRepo = MockFilesSearchRepository.newRepo
        
        let videoNodes = sampleVideoNodesForCloudDrive()
        let imageNodes = sampleImageNodesForCloudDrive()
        fileSearchRepo.videoNodes = videoNodes
        fileSearchRepo.imageNodes = imageNodes
        
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
        let fileSearchRepo = MockFilesSearchRepository.newRepo
        let videoNodes = sampleVideoNodesForCloudDrive()
        let imageNodes = sampleImageNodesForCloudDrive()
        
        photosRepo.cameraUploadNode = cameraUploadNode
        photosRepo.mediaUploadNode = mediaUploadNode
        fileSearchRepo.videoNodes = videoNodes
        fileSearchRepo.imageNodes = imageNodes
        
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
    
    private func sampleImageNodesForCloudDrive() ->[MEGANode] {
        let node1 = MockNode(handle: 4, name: "TestImage1.png", nodeType: .file, parentHandle: 1)
        let node2 = MockNode(handle: 5, name: "TestImage2.png", nodeType: .file, parentHandle: 1)
        let node3 = MockNode(handle: 6, name: "TestImage3.png", nodeType: .file, parentHandle: 2)
        let node4 = MockNode(handle: 7, name: "TestImage4.png", nodeType: .file, parentHandle: 3)
        
        return [node1, node2, node3, node4]
    }
    
    private func sampleVideoNodesForCloudDrive() ->[MEGANode] {
        let node1 = MockNode(handle: 4, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 1)
        let node2 = MockNode(handle: 5, name: "TestVideo2.mp4", nodeType: .file, parentHandle: 1)
        let node3 = MockNode(handle: 6, name: "TestVideo3.mp4", nodeType: .file, parentHandle: 2)
        let node4 = MockNode(handle: 7, name: "TestVideo4.mp4", nodeType: .file, parentHandle: 3)
        
        return [node1, node2, node3, node4]
    }
    
    private func samplePhotoNodesFromCameraUpload() ->[MEGANode] {
        let node1 = MockNode(handle: 4, name: "TestImage1.png", nodeType: .file, parentHandle: 2)
        let node2 = MockNode(handle: 5, name: "TestImage2.png", nodeType: .file, parentHandle: 2)
        let node3 = MockNode(handle: 6, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 2)
        let node4 = MockNode(handle: 7, name: "TestVideo2.mp4", nodeType: .file, parentHandle: 2)
        
        return [node1, node2, node3, node4]
    }
    
    private func samplePhotoNodesFromMediaUpload() ->[MEGANode] {
        let node1 = MockNode(handle: 4, name: "TestImage1.png", nodeType: .file, parentHandle: 3)
        let node2 = MockNode(handle: 5, name: "TestImage2.png", nodeType: .file, parentHandle: 3)
        let node3 = MockNode(handle: 6, name: "TestVideo1.mp4", nodeType: .file, parentHandle: 3)
        let node4 = MockNode(handle: 7, name: "TestVideo2.mp4", nodeType: .file, parentHandle: 3)
        
        return [node1, node2, node3, node4]
    }
}
