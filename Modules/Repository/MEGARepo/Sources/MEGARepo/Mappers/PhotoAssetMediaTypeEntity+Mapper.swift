import MEGADomain
import Photos

extension PhotoAssetMediaTypeEntity {
    func toPHAssetMediaType() -> PHAssetMediaType {
        switch self {
        case .unknown: .unknown
        case .image: .image
        case .video: .video
        case .audio: .audio
        }
    }
}

extension [PhotoAssetMediaTypeEntity] {
    func toPHAssetMediaTypes() -> [PHAssetMediaType] {
        map { $0.toPHAssetMediaType() }
    }
}

extension PHAssetMediaType {
    func toPhotoAssetMediaTypeEntity() -> PhotoAssetMediaTypeEntity {
        switch self {
        case .unknown: .unknown
        case .image: .image
        case .video: .video
        case .audio: .audio
        @unknown default: .unknown
        }
    }
}
