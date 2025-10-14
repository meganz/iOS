import Foundation

public struct CameraAssetUploadEntity: Sendable, Equatable {
    public let localIdentifier: String
    public let creationDate: Date
    public let mediaType: PhotoAssetMediaTypeEntity
    public let status: CameraAssetUploadStatusEntity
    
    public init(
        localIdentifier: String,
        creationDate: Date,
        mediaType: PhotoAssetMediaTypeEntity,
        status: CameraAssetUploadStatusEntity
    ) {
        self.localIdentifier = localIdentifier
        self.creationDate = creationDate
        self.mediaType = mediaType
        self.status = status
    }
}
