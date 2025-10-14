import MEGADomain

public struct CameraUploadAssetRepository {
    private let cameraUploadRecordStore: any CameraUploadRecordStore
    
    public init(cameraUploadRecordStore: some CameraUploadRecordStore) {
        self.cameraUploadRecordStore = cameraUploadRecordStore
    }
    
    public func uploads(
        startingFrom localIdentifier: String?,
        isForward: Bool,
        limit: Int?,
        statuses: [CameraAssetUploadStatusEntity],
        mediaTypes: [PhotoAssetMediaTypeEntity]
    ) async throws -> [CameraAssetUploadEntity] {
        try await cameraUploadRecordStore.fetchAssetUploads(
            startingFrom: localIdentifier,
            isForward: isForward,
            limit: limit,
            statuses: statuses.toCameraAssetUploadStatusDTOs(),
            mediaTypes: mediaTypes.toPHAssetMediaTypes())
        .toAssetUploadRecordEntities()
    }
    
    func fileDetails(
        forLocalIdentifiers identifiers: Set<String>
    ) async throws -> [CameraUploadFileDetailsEntity] {
        try await cameraUploadRecordStore.fetchAssetUploadFileNames(
            forLocalIdentifiers: identifiers)
        .toCameraUploadFileDetailsEntities()
    }
}
