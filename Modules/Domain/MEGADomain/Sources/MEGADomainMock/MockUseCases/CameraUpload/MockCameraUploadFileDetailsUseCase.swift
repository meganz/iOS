import MEGADomain

public struct MockCameraUploadFileDetailsUseCase: CameraUploadFileDetailsUseCaseProtocol {
    private let fileDetails: Set<CameraUploadFileDetailsEntity>
    
    public init(fileDetails: Set<CameraUploadFileDetailsEntity> = []) {
        self.fileDetails = fileDetails
    }
    
    public func fileDetails(forLocalIdentifiers identifiers: Set<String>) async throws -> Set<CameraUploadFileDetailsEntity> {
        fileDetails
    }
}
