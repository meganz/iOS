import Foundation
import MEGADomain
import Photos

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
