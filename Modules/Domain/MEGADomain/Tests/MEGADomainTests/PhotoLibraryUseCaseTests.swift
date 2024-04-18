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
    
    func testMedia_withCloudDrive_shouldReturnTrue() async throws {
        let videoNodes = sampleVideoNodesForCloudDrive()
        let imageNodes = sampleImageNodesForCloudDrive()
        let photosRepo = MockPhotosLibraryRepository.newRepo
        let fileSearchRepo = MockFilesSearchRepository(photoNodes: imageNodes, videoNodes: videoNodes)
        let contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase()
        let expectedResult = videoNodes + imageNodes
        
        let usecase = PhotoLibraryUseCase(
            photosRepository: photosRepo,
            searchRepository: fileSearchRepo,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            hiddenNodesFeatureFlagEnabled: { false })
        
        let photos = try await usecase.media(for: [.allMedia, .allLocations])
        XCTAssertEqual(Set(photos), Set(expectedResult))
    }
    
    func testMedia_withCloudDriveAndExcludeSensitiveTrueViaUserSetting_shouldReturnTrue() async throws {
        let videoNodes = sampleVideoNodesForCloudDrive()
        let imageNodes = sampleImageNodesForCloudDrive()
        let photosRepo = MockPhotosLibraryRepository.newRepo
        let fileSearchRepo = MockFilesSearchRepository(photoNodes: imageNodes, videoNodes: videoNodes)
        let contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase(sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: false))
        let expectedResult = (videoNodes + imageNodes)
            .filter { !$0.isMarkedSensitive }
        
        let usecase = PhotoLibraryUseCase(
            photosRepository: photosRepo,
            searchRepository: fileSearchRepo,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            hiddenNodesFeatureFlagEnabled: { true })
        
        let photos = try await usecase.media(for: [.allMedia, .allLocations])
        XCTAssertEqual(Set(photos), Set(expectedResult))
    }
    
    func testMediaExcludeSensitive_withCloudDrive_shouldReturnTrue() async throws {
        let videoNodes = sampleVideoNodesForCloudDrive()
        let imageNodes = sampleImageNodesForCloudDrive()
        let photosRepo = MockPhotosLibraryRepository.newRepo
        let fileSearchRepo = MockFilesSearchRepository(photoNodes: imageNodes, videoNodes: videoNodes)
        let contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase(sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: true))
        let expectedResult = (videoNodes + imageNodes)
            .filter { !$0.isMarkedSensitive }
        
        let usecase = PhotoLibraryUseCase(
            photosRepository: photosRepo,
            searchRepository: fileSearchRepo,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            hiddenNodesFeatureFlagEnabled: { true })
        
        let photos = try await usecase.media(for: [.allMedia, .allLocations], excludeSensitive: true)
        XCTAssertEqual(Set(photos), Set(expectedResult))
    }
    
    func testMedia_withCameraUploads_shouldReturnTrue() async throws {
        let nodesInCameraUpload  = samplePhotoNodesFromCameraUpload()
        let nodesInMediaUpload = samplePhotoNodesFromMediaUpload()
        
        let fileSearchRepo = MockFilesSearchRepository(nodesForHandle: [
            cameraUploadNode.handle: nodesInCameraUpload,
            mediaUploadNode.handle: nodesInMediaUpload
        ])
        
        let photosRepo = MockPhotosLibraryRepository(cameraUploadNode: cameraUploadNode,
                                                     mediaUploadNode: mediaUploadNode)
        let contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase()
        
        let expectedResult = nodesInCameraUpload + nodesInMediaUpload
        let usecase = PhotoLibraryUseCase(photosRepository: photosRepo, searchRepository: fileSearchRepo, contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase, hiddenNodesFeatureFlagEnabled: { false })

        let photos = try await usecase.media(for: [.cameraUploads, .allMedia])
        XCTAssertEqual(Set(photos), Set(expectedResult))
    }
    
    func testMedia_withCameraUploadsAndExcludeSensitiveTrueViaUserSetting_shouldReturnTrue() async throws {
        let nodesInCameraUpload  = samplePhotoNodesFromCameraUpload()
        let nodesInMediaUpload = samplePhotoNodesFromMediaUpload()
        
        let fileSearchRepo = MockFilesSearchRepository(nodesForHandle: [
            cameraUploadNode.handle: nodesInCameraUpload,
            mediaUploadNode.handle: nodesInMediaUpload
        ])
        
        let photosRepo = MockPhotosLibraryRepository(cameraUploadNode: cameraUploadNode,
                                                     mediaUploadNode: mediaUploadNode)
        let contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase(sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: false))

        let expectedResult = (nodesInCameraUpload + nodesInMediaUpload)
            .filter { !$0.isMarkedSensitive }
        
        let usecase = PhotoLibraryUseCase(photosRepository: photosRepo, searchRepository: fileSearchRepo, contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase, hiddenNodesFeatureFlagEnabled: { true })

        let photos = try await usecase.media(for: [.cameraUploads, .allMedia])
        XCTAssertEqual(Set(photos), Set(expectedResult))
    }
    
    func testMediaExcludeSensitive_withCameraUploads_shouldReturnTrue() async throws {
        let nodesInCameraUpload  = samplePhotoNodesFromCameraUpload()
        let nodesInMediaUpload = samplePhotoNodesFromMediaUpload()
        
        let fileSearchRepo = MockFilesSearchRepository(nodesForHandle: [
            cameraUploadNode.handle: nodesInCameraUpload,
            mediaUploadNode.handle: nodesInMediaUpload
        ])
        
        let photosRepo = MockPhotosLibraryRepository(cameraUploadNode: cameraUploadNode,
                                                     mediaUploadNode: mediaUploadNode)
        let contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase(sensitiveNodesUserAttributeEntity: .init(onboarded: false, showHiddenNodes: false))

        let expectedResult = (nodesInCameraUpload + nodesInMediaUpload)
            .filter { !$0.isMarkedSensitive }
        
        let usecase = PhotoLibraryUseCase(photosRepository: photosRepo, searchRepository: fileSearchRepo, contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase, hiddenNodesFeatureFlagEnabled: { true })

        let photos = try await usecase.media(for: [.cameraUploads, .allMedia], excludeSensitive: true)
        XCTAssertEqual(Set(photos), Set(expectedResult))
    }
    
    func testMedia_withCloudDriveOnly_shouldReturnTrue() async throws {
        let photosRepo = MockPhotosLibraryRepository(cameraUploadNode: cameraUploadNode,
                                                     mediaUploadNode: mediaUploadNode)
        
        let videoNodes = sampleVideoNodesForCloudDrive()
        let imageNodes = sampleImageNodesForCloudDrive()
        let fileSearchRepo = MockFilesSearchRepository(photoNodes: imageNodes, videoNodes: videoNodes)
        let contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase()

        let expectedResult = (videoNodes + imageNodes)
            .filter { $0.parentHandle == 1 }
        let usecase = PhotoLibraryUseCase(photosRepository: photosRepo, searchRepository: fileSearchRepo, contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase, hiddenNodesFeatureFlagEnabled: { false })
        
        let photos = try await usecase.media(for: [.cloudDrive, .allMedia])
        XCTAssertEqual(Set(photos), Set(expectedResult))
    }
    
    func testMedia_withCloudDriveOnlyAndExcludeSensitiveTrueViaUserSetting_shouldReturnTrue() async throws {
        let photosRepo = MockPhotosLibraryRepository(cameraUploadNode: cameraUploadNode,
                                                     mediaUploadNode: mediaUploadNode)
        
        let videoNodes = sampleVideoNodesForCloudDrive()
        let imageNodes = sampleImageNodesForCloudDrive()
        let fileSearchRepo = MockFilesSearchRepository(photoNodes: imageNodes, videoNodes: videoNodes)
        let contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase()

        let expectedResult = (videoNodes + imageNodes)
            .filter { $0.parentHandle == 1 && !$0.isMarkedSensitive}
        let usecase = PhotoLibraryUseCase(photosRepository: photosRepo, searchRepository: fileSearchRepo, contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase, hiddenNodesFeatureFlagEnabled: { true })
        
        let photos = try await usecase.media(for: [.cloudDrive, .allMedia])
        XCTAssertEqual(Set(photos), Set(expectedResult))
    }
    
    func testMediaExcludeSensitive_withCloudDriveOnly_shouldReturnTrue() async throws {
        let photosRepo = MockPhotosLibraryRepository(cameraUploadNode: cameraUploadNode,
                                                     mediaUploadNode: mediaUploadNode)
        
        let videoNodes = sampleVideoNodesForCloudDrive()
        let imageNodes = sampleImageNodesForCloudDrive()
        let fileSearchRepo = MockFilesSearchRepository(photoNodes: imageNodes, videoNodes: videoNodes)
        let contentConsumptionUserAttributeUseCase = MockContentConsumptionUserAttributeUseCase()

        let expectedResult = (videoNodes + imageNodes)
            .filter { $0.parentHandle == 1 && !$0.isMarkedSensitive}
        let usecase = PhotoLibraryUseCase(photosRepository: photosRepo, searchRepository: fileSearchRepo, contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase, hiddenNodesFeatureFlagEnabled: { true })
        
        let photos = try await usecase.media(for: [.cloudDrive, .allMedia], excludeSensitive: true)
        XCTAssertEqual(Set(photos), Set(expectedResult))
    }
    
    // MARK: - Private
    
    private func sampleImageNodesForCloudDrive() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 4, parentHandle: 1, isFile: true)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 5, parentHandle: 1, isFile: true, isMarkedSensitive: true)
        let node3 = NodeEntity(nodeType: .file, name: "TestImage3.png", handle: 6, parentHandle: 2, isFile: true)
        let node4 = NodeEntity(nodeType: .file, name: "TestImage4.png", handle: 7, parentHandle: 3, isFile: true, isMarkedSensitive: true)
        
        return [node1, node2, node3, node4]
    }
    
    private func sampleVideoNodesForCloudDrive() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 8, parentHandle: 1, isFile: true)
        let node2 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 9, parentHandle: 1, isFile: true, isMarkedSensitive: true)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo3.mp4", handle: 10, parentHandle: 2, isFile: true, isMarkedSensitive: true)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo4.mp4", handle: 11, parentHandle: 3, isFile: true)
        
        return [node1, node2, node3, node4]
    }
    
    private func samplePhotoNodesFromCameraUpload() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 4, parentHandle: 2, isFile: true, isMarkedSensitive: true)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 5, parentHandle: 2, isFile: true)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 6, parentHandle: 2, isFile: true)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 7, parentHandle: 2, isFile: true, isMarkedSensitive: true)
        
        return [node1, node2, node3, node4]
    }
    
    private func samplePhotoNodesFromMediaUpload() -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle: 4, parentHandle: 3, isFile: true)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle: 5, parentHandle: 3, isFile: true, isMarkedSensitive: true)
        let node3 = NodeEntity(nodeType: .file, name: "TestVideo1.mp4", handle: 6, parentHandle: 3, isFile: true)
        let node4 = NodeEntity(nodeType: .file, name: "TestVideo2.mp4", handle: 7, parentHandle: 3, isFile: true, isMarkedSensitive: true)
        
        return [node1, node2, node3, node4]
    }
}
