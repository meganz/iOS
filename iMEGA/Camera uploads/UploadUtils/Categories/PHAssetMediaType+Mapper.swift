import Foundation
import Photos
import MEGADomain

extension PHAssetMediaType {
    func toMediaTypeEntity() -> MediaTypeEntity {
        switch self {
        case .image:
            return .image
        case .video:
            return .video
        default:
            return .image
        }
    }
}
