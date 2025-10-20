import MEGARepo
import Photos

public struct MockCameraUploadRecordStore: CameraUploadRecordStore {
    private let assetUploadsResult: Result<[AssetUploadRecordDTO], any Error>
    private let fileNamesResult: Result<Set<AssetUploadFileNameRecordDTO>, any Error>
    
    public init(
        assetUploadsResult: Result<[AssetUploadRecordDTO], any Error> = .success([]),
        fileNamesResult: Result<Set<AssetUploadFileNameRecordDTO>, any Error> = .success([])
    ) {
        self.assetUploadsResult = assetUploadsResult
        self.fileNamesResult = fileNamesResult
    }
    
    public func fetchAssetUploads(
        startingFrom localIdentifier: String?,
        isForward: Bool, limit: Int?,
        statuses: [CameraAssetUploadStatusDTO],
        mediaTypes: [PHAssetMediaType]
    ) async throws -> [AssetUploadRecordDTO] {
        try assetUploadsResult.get()
    }
    
    public func fetchAssetUploadFileNames(forLocalIdentifiers identifiers: Set<String>) async throws -> Set<AssetUploadFileNameRecordDTO> {
        try fileNamesResult.get()
    }
}
