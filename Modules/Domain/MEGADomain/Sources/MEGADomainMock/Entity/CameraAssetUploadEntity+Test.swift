import Foundation
import MEGADomain

public extension CameraAssetUploadEntity {
    init(
        localIdentifier: String,
        creationDate: Date = .now,
        mediaType: PhotoAssetMediaTypeEntity = .unknown,
        status: CameraAssetUploadStatusEntity = .unknown,
        isTesting: Bool = true
    ) {
        self.init(
            localIdentifier: localIdentifier,
            creationDate: creationDate,
            mediaType: mediaType,
            status: status)
    }
}
