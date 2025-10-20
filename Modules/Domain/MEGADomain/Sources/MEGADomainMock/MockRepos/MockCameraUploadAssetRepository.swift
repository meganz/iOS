import MEGADomain

public struct MockCameraUploadAssetRepository: CameraUploadAssetRepositoryProtocol {
    private let uploadsResult: Result<[CameraAssetUploadEntity], any Error>
    private let fileDetailsResult: Result<Set<CameraUploadFileDetailsEntity>, any Error>
    
    public init(
        uploadsResult: Result<[CameraAssetUploadEntity], any Error> = .failure(GenericErrorEntity()),
        fileDetailsResult: Result<Set<CameraUploadFileDetailsEntity>, any Error> = .failure(GenericErrorEntity())
    ) {
        self.uploadsResult = uploadsResult
        self.fileDetailsResult = fileDetailsResult
    }
    
    public func uploads(
        startingFrom localIdentifier: String?,
        isForward: Bool,
        limit: Int?,
        statuses: [CameraAssetUploadStatusEntity],
        mediaTypes: [PhotoAssetMediaTypeEntity]) async throws -> [CameraAssetUploadEntity] {
            try uploadsResult.get()
        }
    
    public func fileDetails(forLocalIdentifiers identifiers: Set<String>) async throws -> Set<CameraUploadFileDetailsEntity> {
        try fileDetailsResult.get()
    }
}
