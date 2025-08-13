@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import Testing

struct SaveToPhotosViewModelTests {

    @Suite("Save To Photos Nodes")
    @MainActor
    struct SaveToPhotosNodes {
        @Test("Is paywalled should not show progress")
        func overDisQuota() async {
            let coordinator = MockSaveToPhotosCoordinator()
            let sut = makeSUT(
                coordinator: coordinator,
                overDiskQuotaChecker: MockOverDiskQuotaChecker(isPaywalled: true))
            
            await sut.saveToPhotos(nodes: [])
            
            #expect(coordinator.actions.isEmpty)
        }
        
        @Test func photoPermissionNotGivenShouldRequest() async {
            let coordinator = MockSaveToPhotosCoordinator()
            let sut = makeSUT(
                coordinator: coordinator,
                devicePermissionsHandling: MockDevicePermissionHandler(requestPhotoLibraryAccessPermissionsGranted: false))
            
            await sut.saveToPhotos(nodes: [])
            
            #expect(coordinator.actions == [.showPhotoPermissionAlert])
        }
        
        @Test func saveToPhotos() async {
            let coordinator = MockSaveToPhotosCoordinator()
            let sut = makeSUT(
                coordinator: coordinator,
                saveMediaToPhotosUseCase: MockSaveMediaToPhotosUseCase(saveToPhotosResult: .success))
            
            await sut.saveToPhotos(nodes: [])
            
            #expect(coordinator.actions == [.showProgress])
        }
        
        @Test(arguments: [SaveMediaToPhotosErrorEntity.cancelled, .fileDownloadInProgress])
        func saveToPhotosFailed(error: SaveMediaToPhotosErrorEntity) async {
            let coordinator = MockSaveToPhotosCoordinator()
            let sut = makeSUT(
                coordinator: coordinator,
                saveMediaToPhotosUseCase: MockSaveMediaToPhotosUseCase(
                    saveToPhotosResult: .failure(error)))
            
            await sut.saveToPhotos(nodes: [])
            
            var actions = [MockSaveToPhotosCoordinator.Actions.showProgress]
            if error != .cancelled {
                actions.append(.showError(error))
            }
            
            #expect(coordinator.actions == actions)
        }
    }
    
    @Suite("Save to photos file link")
    @MainActor
    struct SaveToPhotosFileLink {
        @Test(arguments: ["https://mega.nz/", "https://mega.app/"])
        func saveToPhotos(urlString: String) async throws {
            let coordinator = MockSaveToPhotosCoordinator()
            let sut = makeSUT(
                coordinator: coordinator,
                saveMediaToPhotosUseCase: MockSaveMediaToPhotosUseCase(saveToPhotosResult: .success))
            
            await sut.saveToPhotos(fileLink: .init(linkURL: try #require(URL(string: urlString))))
            
            #expect(coordinator.actions == [.showProgress])
        }
    }
    
    @Suite("Save Chat Photo")
    @MainActor
    struct SaveChatPhoto {
        @Test func saveChatPhoto() async {
            let coordinator = MockSaveToPhotosCoordinator()
            let sut = makeSUT(
                coordinator: coordinator,
                saveMediaToPhotosUseCase: MockSaveMediaToPhotosUseCase(saveToPhotosResult: .success))
            
            await sut.saveToPhotosChatNode(handle: 8, messageId: 9, chatId: 0)
            
            #expect(coordinator.actions == [.showProgress])
        }
    }
    
    @MainActor
    private static func makeSUT(
        coordinator: some SaveToPhotosCoordinatorProtocol = MockSaveToPhotosCoordinator(),
        overDiskQuotaChecker: some OverDiskQuotaChecking = MockOverDiskQuotaChecker(),
        devicePermissionsHandling: some DevicePermissionsHandling = MockDevicePermissionHandler(requestPhotoLibraryAccessPermissionsGranted: true),
        saveMediaToPhotosUseCase: any SaveMediaToPhotosUseCaseProtocol = MockSaveMediaToPhotosUseCase()
    ) -> SaveToPhotosViewModel {
        .init(
            coordinator: coordinator,
            overDiskQuotaChecker: overDiskQuotaChecker,
            devicePermissionsHandling: devicePermissionsHandling,
            saveMediaToPhotosUseCase: saveMediaToPhotosUseCase)
    }

}
