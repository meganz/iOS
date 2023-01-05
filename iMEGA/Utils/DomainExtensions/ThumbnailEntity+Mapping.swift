import MEGADomain
import MEGASwiftUI

extension ThumbnailEntity {
    func toURLImageContainer() -> URLImageContainer? {
        URLImageContainer(imageURL: url, type: type.toImageType())
    }
}

extension ThumbnailTypeEntity {
    func toImageType() -> ImageType {
        switch self {
        case .thumbnail:
            return .thumbnail
        case .preview:
            return .preview
        case .original:
            return .original
        }
    }
}
