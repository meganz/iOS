import Foundation
import Photos

public struct AssetUploadRecordDTO: Sendable {
    public let localIdentifier: String
    public let creationDate: Date?
    public let mediaType: PHAssetMediaType?
    public let mediaSubtypes: Int?
    public let additionalMediaSubtypes: Int?
    public let status: CameraAssetUploadStatusDTO?
    
    public init(
        localIdentifier: String,
        creationDate: Date?,
        mediaType: PHAssetMediaType?,
        mediaSubtypes: Int?,
        additionalMediaSubtypes: Int?,
        status: CameraAssetUploadStatusDTO?
    ) {
        self.localIdentifier = localIdentifier
        self.creationDate = creationDate
        self.mediaType = mediaType
        self.mediaSubtypes = mediaSubtypes
        self.additionalMediaSubtypes = additionalMediaSubtypes
        self.status = status
    }
}
