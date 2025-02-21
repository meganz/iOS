@testable import MEGA

import MEGADomain
import MEGADomainMock
import MEGAPermissionsMock
import Testing

@Suite("Home recent actions test suite")
struct HomeRecentActionViewModelTests {

    private static func makeSUT(
        isPhotoPermissionGranted: Bool = false,
        nodeFavouriteActionUseCase: some NodeFavouriteActionUseCaseProtocol = MockNodeFavouriteActionUseCase(),
        saveMediaToPhotosUseCase: some SaveMediaToPhotosUseCaseProtocol = MockSaveMediaToPhotosUseCase(saveToPhotosResult: .failure(SaveMediaToPhotosErrorEntity.nodeNotFound)),
        transferWidgetResponder: some TransferWidgetResponderProtocol = MockTransferWidgetResponder(),
        analyticsEventUseCase: some AnalyticsEventUseCaseProtocol = MockAnalyticsEventUseCase()
    ) -> HomeRecentActionViewModel {
        HomeRecentActionViewModel(
            permissionHandler: MockDevicePermissionHandler(requestPhotoLibraryAccessPermissionsGranted: isPhotoPermissionGranted),
            nodeFavouriteActionUseCase: nodeFavouriteActionUseCase,
            saveMediaToPhotosUseCase: saveMediaToPhotosUseCase,
            transferWidgetResponder: transferWidgetResponder,
            analyticsEventUseCase: analyticsEventUseCase
        )
    }
    
    @Suite("Save to Photos action")
    struct SaveToPhotosAction {
        @Test(
            "Show permission error when no permission is granted for saving photo to album"
        )
        func saveToPhotoAlbumWithNoPermissionGranted() async throws {
            let expectedError: DevicePermissionDeniedError = .photos
            var receivedError: DevicePermissionDeniedError?
            
            try await confirmation("Should give an error") { confirm in
                let sut = makeSUT(isPhotoPermissionGranted: false)
                
                sut.notifyUpdate = { viewModel in
                    receivedError = viewModel.error
                    
                    #expect(sut.error == expectedError)
                    confirm()
                }
                
                sut.saveToPhotoAlbum(of: NodeEntity())
                try await sut.saveToPhotoAlbumTask?.value
            }

            #expect(receivedError == expectedError)
        }
        
        @Test(
            "Save photo to album without error"
        )
        func saveToPhotoAlbumSuccessfully() async throws {
            try await assertSaveToPhotoAlbum(saveToPhotosResult: .success, expectedEvent: nil)
        }
        
        @Test(
            "Save photo to album with failed result",
            arguments: [
                (SaveMediaToPhotosErrorEntity.cancelled, nil),
                (SaveMediaToPhotosErrorEntity.fileDownloadInProgress, AnalyticsEventEntity.download(.saveToPhotos)),
                (SaveMediaToPhotosErrorEntity.downloadFailed, AnalyticsEventEntity.download(.saveToPhotos))
            ]
        )
        func saveToPhotoAlbumWithFailedResult(
            error: SaveMediaToPhotosErrorEntity,
            expectedEvent: AnalyticsEventEntity?
        ) async throws {
            try await assertSaveToPhotoAlbum(saveToPhotosResult: .failure(error), expectedEvent: expectedEvent)
        }
        
        // MARK: - Test Helper
        private func assertSaveToPhotoAlbum(
            saveToPhotosResult: Result<Void, SaveMediaToPhotosErrorEntity>,
            expectedEvent: AnalyticsEventEntity?
        ) async throws {
            let mockAnalyticsEventUseCase = MockAnalyticsEventUseCase()
            let mockSaveMediaToPhotosUseCase = MockSaveMediaToPhotosUseCase(saveToPhotosResult: saveToPhotosResult)
            let mockTransferWidgetResponder = MockTransferWidgetResponder()
            let sut = makeSUT(
                isPhotoPermissionGranted: true,
                saveMediaToPhotosUseCase: mockSaveMediaToPhotosUseCase,
                transferWidgetResponder: mockTransferWidgetResponder,
                analyticsEventUseCase: mockAnalyticsEventUseCase
            )
            
            sut.notifyUpdate = { _ in
                Issue.record("notifyUpdate should not be called")
            }
            sut.saveToPhotoAlbum(of: NodeEntity())
            try await sut.saveToPhotoAlbumTask?.value
            
            #expect(sut.error == nil)
            #expect(mockAnalyticsEventUseCase.type == expectedEvent)
            #expect(mockTransferWidgetResponder.bringProgressToFrontKeyWindowIfNeededCalled == 1)
            #expect(mockSaveMediaToPhotosUseCase.saveToPhotosCalledCount == 1)
        }
    }
    
    @Suite("Toggle favourite node action")
    struct FavouriteRecentNodeAction {
        @Test(
            "Set to favourite or unfavourite node",
            arguments: [
                (true, 0, 1),
                (false, 1, 0)
            ]
        )
        func toggleFavouriteNode(
            isFavourite: Bool,
            favoriteCalledCount: Int,
            unFavoriteCalledCount: Int
        ) async throws {
            let mockNodeFavouriteActionUseCase = MockNodeFavouriteActionUseCase()
            let sut = makeSUT(nodeFavouriteActionUseCase: mockNodeFavouriteActionUseCase)

            sut.toggleFavourite(of: NodeEntity(isFavourite: isFavourite))
            try await sut.toggleFavouriteTask?.value

            #expect(mockNodeFavouriteActionUseCase.favoriteCalledCount == favoriteCalledCount)
            #expect(mockNodeFavouriteActionUseCase.unFavoriteCalledCount == unFavoriteCalledCount)
        }
    }
    
    @Suite("Inputs protocol")
    struct HomeRecentActionViewModelInputs {
        @Test
        func sutConformsToHomeRecentActionViewModelInputs() {
            let sut = makeSUT()
            
            #expect(sut.inputs === sut, "The inputs property should return the ViewModel instance itself.")
        }
    }
}
