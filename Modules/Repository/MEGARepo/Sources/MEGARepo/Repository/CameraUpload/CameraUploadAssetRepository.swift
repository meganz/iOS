import MEGADomain

public struct CameraUploadAssetRepository: CameraUploadAssetRepositoryProtocol {
    private let cameraUploadRecordStore: any CameraUploadRecordStore
    
    public init(cameraUploadRecordStore: some CameraUploadRecordStore) {
        self.cameraUploadRecordStore = cameraUploadRecordStore
    }
    
    public func uploads(
        startingFrom cursor: QueuedCameraUploadCursorEntity?,
        isForward: Bool,
        limit: Int?,
        statuses: [CameraAssetUploadStatusEntity],
        mediaTypes: [PhotoAssetMediaTypeEntity]
    ) async throws -> [CameraAssetUploadEntity] {
        try await cameraUploadRecordStore.fetchAssetUploads(
            startingFrom: cursor?.toQueuedCameraUploadCursorDTO(),
            isForward: isForward,
            limit: limit,
            statuses: statuses.toCameraAssetUploadStatusDTOs(),
            mediaTypes: mediaTypes.toPHAssetMediaTypes())
        .toAssetUploadRecordEntities()
    }
    
    public func fileDetails(
        forLocalIdentifiers identifiers: Set<String>
    ) async throws -> Set<CameraUploadFileDetailsEntity> {
        try await cameraUploadRecordStore.fetchAssetUploadFileNames(
            forLocalIdentifiers: identifiers)
        .toCameraUploadFileDetailsEntities()
    }
}
