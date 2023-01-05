import Foundation

public enum ThumbnailTypeEntity {
    case thumbnail
    case preview
    case original
}

public struct ThumbnailEntity {
    public let url: URL
    public let type: ThumbnailTypeEntity
    
    public init(url: URL, type: ThumbnailTypeEntity) {
        self.url = url
        self.type = type
    }
}
