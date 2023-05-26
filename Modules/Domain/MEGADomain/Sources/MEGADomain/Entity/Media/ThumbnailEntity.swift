import Foundation

public enum ThumbnailTypeEntity: Sendable {
    case thumbnail
    case preview
    case original
}

public struct ThumbnailEntity: Sendable {
    public let url: URL
    public let type: ThumbnailTypeEntity
    
    public init(url: URL, type: ThumbnailTypeEntity) {
        self.url = url
        self.type = type
    }
}
