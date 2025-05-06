import Foundation
import MEGADomain
import MEGADomainMock
import MEGAPreference
import Testing

struct SaveNodeUseCaseTests {
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
        photosLibraryError: SaveMediaToPhotosErrorEntity? = nil
    ) async -> (Bool, MockSaveMediaToPhotoFailureHandler) {
        let (sut, saveMediaToPhotoFailureHandler) = makeSUT(
            isURLImage: isURLImage,
            isURLVideo: isURLVideo,
            movedNode: movedNode,
            shouldFallbackToMakingOffline: shouldFallbackToMakingOffline,
            photosLibraryError: photosLibraryError
        )
        
        return (await sut.saveNode(from: transfer), saveMediaToPhotoFailureHandler)
    }
    
    @Test("Saving image to Photos should succeed")
    func testSaveNode_withImageURL_shouldSaveSuccessfully() async {
        let (result, _) = await executeSaveNode(
            transfer: photoTransfer,
            isURLImage: true
        )
        #expect(result == true)
    }
    
    @Test("Saving video to Photos should succeed")
    func testSaveNode_withVideoURL_shouldSaveSuccessfully() async {
        let (result, _) = await executeSaveNode(
            transfer: videoTransfer,
            isURLVideo: true
        )
        #expect(result == true)
    }
    
    @Test("Invalid transfer should return failure")
    func testSaveNode_withInvalidTransfer_shouldNotSaveSuccessfully() async {
        let (result, _) = await executeSaveNode(transfer: invalidTransfer)
        #expect(result == false)
    }
    
    @Test("Fallback to making offline for image should trigger fallback")
    func testSaveNode_whenFallbackForImage_shouldTriggerFallback() async {
        let (result, saveMediaToPhotoFailureHandler) = await executeSaveNode(
            transfer: photoTransfer,
            isURLImage: true,
            movedNode: false,
            shouldFallbackToMakingOffline: true,
            photosLibraryError: .imageNotSaved
        )
    
        #expect(result == false)
        #expect(saveMediaToPhotoFailureHandler.fallback_calledTimes == 1)
    }
    
    @Test("Fallback to making offline for video should trigger fallback")
    func testSaveNode_whenFallbackForVideo_shouldTriggerFallback() async {
        let (result, saveMediaToPhotoFailureHandler) = await executeSaveNode(
            transfer: videoTransfer,
            isURLVideo: true,
            movedNode: false,
            shouldFallbackToMakingOffline: true,
            photosLibraryError: .imageNotSaved
        )
        
        #expect(result == false)
        #expect(saveMediaToPhotoFailureHandler.fallback_calledTimes == 1)
    }
    
    @Test("Non-media file should not trigger fallback")
    func testSaveNode_withNonMediaFile_shouldNotTriggerFallback() async {
        let (result, saveMediaToPhotoFailureHandler) = await executeSaveNode(transfer: nonMediaTransfer)
        #expect(result == false)
        #expect(saveMediaToPhotoFailureHandler.fallback_calledTimes == 0)
    }

    @Test("Photos library error should trigger fallback")
    func testSaveNode_withPhotosLibraryError_shouldTriggerFallback() async {
        let (result, saveMediaToPhotoFailureHandler) = await executeSaveNode(
            transfer: photoTransfer,
            isURLImage: true,
            movedNode: true,
            shouldFallbackToMakingOffline: true,
            photosLibraryError: .imageNotSaved
        )
        #expect(result == false)
        #expect(saveMediaToPhotoFailureHandler.fallback_calledTimes == 1)
    }

    @Test("Configured not to fallback should not trigger fallback")
    func testSaveNode_withNoFallbackConfiguration_shouldNotTriggerFallback() async {
        let (result, saveMediaToPhotoFailureHandler) = await executeSaveNode(
            transfer: photoTransfer,
            isURLImage: true,
            movedNode: false,
            shouldFallbackToMakingOffline: false
        )
        #expect(result == true)
        #expect(saveMediaToPhotoFailureHandler.fallback_calledTimes == 0)
    }
    
    @Test("Non-media file should create offline file")
    func testSaveNode_withNonMediaFile_shouldCreateOfflineFile() async {
        let (sut, _) = makeSUT()
        
        let result = await sut.saveNode(from: nonMediaTransfer)
        #expect(result == false)
    }
}
