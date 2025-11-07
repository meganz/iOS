import MEGADomain

public struct MockCameraUploadFileDetailsUseCase: CameraUploadFileDetailsUseCaseProtocol {
    private let fileDetails: Set<CameraUploadFileDetailsEntity>
    private let uploadFileNameResult: Result<String, CameraUploadFileDetailsErrorEntity>
    
    public init(
        fileDetails: Set<CameraUploadFileDetailsEntity> = [],
        uploadFileNameResult: Result<String, CameraUploadFileDetailsErrorEntity> = .failure(CameraUploadFileDetailsErrorEntity.assetNotFound)
    ) {
        self.fileDetails = fileDetails
        self.uploadFileNameResult = uploadFileNameResult
    }
    
    public func fileDetails(forLocalIdentifiers identifiers: Set<String>) async throws -> Set<CameraUploadFileDetailsEntity> {
        fileDetails
    }
    
    public func uploadFileName(for assetUploadEntity: CameraAssetUploadEntity) throws(CameraUploadFileDetailsErrorEntity) -> String {
        try uploadFileNameResult.get()
    }
}
