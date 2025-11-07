import Foundation

public struct CameraAssetUploadEntity: Sendable, Equatable {
    public let localIdentifier: String
    public let creationDate: Date
    public let mediaType: PhotoAssetMediaTypeEntity
    public let mediaSubType: PhotoAssetMediaSubtypeEntity
    public let status: CameraAssetUploadStatusEntity
    
    public init(
        localIdentifier: String,
        creationDate: Date,
        mediaType: PhotoAssetMediaTypeEntity,
        mediaSubType: PhotoAssetMediaSubtypeEntity,
        status: CameraAssetUploadStatusEntity
    ) {
        self.localIdentifier = localIdentifier
        self.creationDate = creationDate
        self.mediaType = mediaType
        self.mediaSubType = mediaSubType
        self.status = status
    }
}
