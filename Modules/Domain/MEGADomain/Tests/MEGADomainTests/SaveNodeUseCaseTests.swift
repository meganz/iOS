import MEGADomain
import MEGADomainMock
import XCTest

final class SaveNodeUseCaseTests: XCTestCase {
    private let photoTransfer = TransferEntity(
        path: "/mock/path/test.jpg",
        nodeHandle: 123,
        fileName: "test.jpg",
        appData: ">SaveInPhotosApp"
    )
    private let videoTransfer = TransferEntity(
        path: "/mock/path/test.mp4",
        nodeHandle: 123,
        fileName: "test.mp4",
        appData: ">SaveInPhotosApp"
    )
    private let nonMediaTransfer = TransferEntity(
        path: "/mock/path/test.txt",
        nodeHandle: 123,
        fileName: "test.txt"
    )
    private let invalidTransfer = TransferEntity(
        path: nil,
        nodeHandle: 123,
        fileName: nil
    )
    
    private func makeSUT(
        isURLImage: Bool = false,
        isURLVideo: Bool = false,
        movedNode: Bool = true,
        shouldFallbackToMakingOffline: Bool = true,
        photosLibraryError: SaveMediaToPhotosErrorEntity? = nil
    ) -> (SaveNodeUseCase<
        MockOfflineFilesRepository,
        MockFileCacheRepository,
        MockNodeRepository,
        MockPhotosLibraryRepository,
        MockMediaUseCase,
        MockPreferenceUseCase,
        MockTransferInventoryRepository,
        MockFileSystemRepository,
        MockSaveMediaToPhotoFailureHandler>, MockSaveMediaToPhotoFailureHandler) {
        
        let offlineFilesRepository = MockOfflineFilesRepository()
        let fileCacheRepository = MockFileCacheRepository()
        let nodeRepository = MockNodeRepository()
        let photosLibraryRepository = MockPhotosLibraryRepository(error: photosLibraryError)
        let mediaUseCase = MockMediaUseCase(isURLVideo: isURLVideo, isURLImage: isURLImage)
        let preferenceUseCase = MockPreferenceUseCase()
        let transferInventoryRepository = MockTransferInventoryRepository.newRepo
        let fileSystemRepository = MockFileSystemRepository(movedNode: movedNode)
        let saveMediaToPhotoFailureHandler = MockSaveMediaToPhotoFailureHandler(shouldFallback: shouldFallbackToMakingOffline)
        let notificationCenter = NotificationCenter.default
        
        return (
            SaveNodeUseCase(
                offlineFilesRepository: offlineFilesRepository,
                fileCacheRepository: fileCacheRepository,
                nodeRepository: nodeRepository,
                photosLibraryRepository: photosLibraryRepository,
                mediaUseCase: mediaUseCase,
                preferenceUseCase: preferenceUseCase,
                transferInventoryRepository: transferInventoryRepository,
                fileSystemRepository: fileSystemRepository,
                saveMediaToPhotoFailureHandler: saveMediaToPhotoFailureHandler,
                notificationCenter: notificationCenter
            ),
            saveMediaToPhotoFailureHandler
        )
    }
    
    private func executeSaveNode(
        transfer: TransferEntity,
        isURLImage: Bool = false,
        isURLVideo: Bool = false,
        movedNode: Bool = true,
        shouldFallbackToMakingOffline: Bool = true,
        photosLibraryError: SaveMediaToPhotosErrorEntity? = nil,
        expectationDescription: String,
        validation: @escaping (Result<Bool, SaveMediaToPhotosErrorEntity>, MockSaveMediaToPhotoFailureHandler) -> Void
    ) {
        let (sut, saveMediaToPhotoFailureHandler) = makeSUT(
            isURLImage: isURLImage,
            isURLVideo: isURLVideo,
            movedNode: movedNode,
            shouldFallbackToMakingOffline: shouldFallbackToMakingOffline,
            photosLibraryError: photosLibraryError
        )
        let expectation = self.expectation(description: expectationDescription)
        
        sut.saveNode(from: transfer) { result in
            validation(result, saveMediaToPhotoFailureHandler)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testSaveNode_withImageURL_shouldSaveSuccessfully() {
        executeSaveNode(
            transfer: photoTransfer,
            isURLImage: true,
            expectationDescription: "Saving image to Photos should succeed"
        ) { result, _ in
            switch result {
            case .success(let success):
                XCTAssertTrue(success)
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
    }
    
    func testSaveNode_withVideoURL_shouldSaveSuccessfully() {
        executeSaveNode(
            transfer: videoTransfer,
            isURLVideo: true,
            expectationDescription: "Saving video to Photos should succeed"
        ) { result, _ in
            switch result {
            case .success(let success):
                XCTAssertTrue(success)
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
    }
    
    func testSaveNode_withInvalidTransfer_shouldNotSaveSuccessfully() {
        executeSaveNode(
            transfer: invalidTransfer,
            expectationDescription: "Invalid transfer should return failure"
        ) { result, _ in
            switch result {
            case .success(let success):
                XCTAssertFalse(success)
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
    }
    
    func testSaveNode_whenFallbackForImage_shouldTriggerFallback() {
        executeSaveNode(
            transfer: photoTransfer,
            isURLImage: true,
            movedNode: false,
            shouldFallbackToMakingOffline: true,
            photosLibraryError: .imageNotSaved,
            expectationDescription: "Fallback to making offline for image should trigger fallback"
        ) { result, saveMediaToPhotoFailureHandler in
            switch result {
            case .success(let success):
                XCTAssertFalse(success)
                XCTAssertEqual(saveMediaToPhotoFailureHandler.fallback_calledTimes, 1)
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
    }
    
    func testSaveNode_whenFallbackForVideo_shouldTriggerFallback() {
        executeSaveNode(
            transfer: videoTransfer,
            isURLVideo: true,
            movedNode: false,
            shouldFallbackToMakingOffline: true,
            photosLibraryError: .imageNotSaved,
            expectationDescription: "Fallback to making offline for video should trigger fallback"
        ) { result, saveMediaToPhotoFailureHandler in
            switch result {
            case .success(let success):
                XCTAssertFalse(success)
                XCTAssertEqual(saveMediaToPhotoFailureHandler.fallback_calledTimes, 1)
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
    }
    
    func testSaveNode_withNonMediaFile_shouldNotTriggerFallback() {
        executeSaveNode(
            transfer: nonMediaTransfer,
            expectationDescription: "Non-media file should not trigger fallback"
        ) { result, saveMediaToPhotoFailureHandler in
            switch result {
            case .success(let success):
                XCTAssertFalse(success)
                XCTAssertEqual(saveMediaToPhotoFailureHandler.fallback_calledTimes, 0)
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
    }

    func testSaveNode_withPhotosLibraryError_shouldTriggerFallback() {
        executeSaveNode(
            transfer: photoTransfer,
            isURLImage: true,
            movedNode: true,
            shouldFallbackToMakingOffline: true,
            photosLibraryError: .imageNotSaved,
            expectationDescription: "Photos library error should trigger fallback"
        ) { result, saveMediaToPhotoFailureHandler in
            switch result {
            case .success(let success):
                XCTAssertFalse(success)
                XCTAssertEqual(saveMediaToPhotoFailureHandler.fallback_calledTimes, 1)
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
    }

    func testSaveNode_withNoFallbackConfiguration_shouldNotTriggerFallback() {
        executeSaveNode(
            transfer: photoTransfer,
            isURLImage: true,
            movedNode: false,
            shouldFallbackToMakingOffline: false,
            expectationDescription: "Configured not to fallback should not trigger fallback"
        ) { result, saveMediaToPhotoFailureHandler in
            switch result {
            case .success(let success):
                XCTAssertTrue(success)
                XCTAssertEqual(saveMediaToPhotoFailureHandler.fallback_calledTimes, 0)
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
    }
    
    func testSaveNode_withNonMediaFile_shouldCreateOfflineFile() {
        let (sut, _) = makeSUT()
        let expectation = self.expectation(description: "Non-media file should create offline file")
        
        sut.saveNode(from: nonMediaTransfer) { result in
            switch result {
            case .success(let success):
                XCTAssertFalse(success)
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success but got failure")
            }
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
