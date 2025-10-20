import MEGADomain
import MEGADomainMock
import Testing

struct CameraUploadFileDetailsUseCaseTests {
    @Test
    func fileDetails() async throws {
        let localIdentifier = "id"
        let expectedFiles = Set([CameraUploadFileDetailsEntity(localIdentifier: localIdentifier)])
        let repository = MockCameraUploadAssetRepository(
            fileDetailsResult: .success(expectedFiles)
        )
        let sut = Self.makeSUT(cameraUploadAssetRepository: repository)
        
        #expect(try await sut.fileDetails(forLocalIdentifiers: [localIdentifier]) == expectedFiles)
    }
    
    private static func makeSUT(
        cameraUploadAssetRepository: some CameraUploadAssetRepositoryProtocol = MockCameraUploadAssetRepository()
    ) -> CameraUploadFileDetailsUseCase {
        .init(cameraUploadAssetRepository: cameraUploadAssetRepository)
    }
}
