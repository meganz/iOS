import MEGADomain
import MEGAPresentation

public struct VideoPlaylistCellPreviewEntity: Sendable {
    public let thumbnail: VideoPlaylistThumbnail
    public let count: String
    public let duration: String
    public var title: String
    public let isExported: Bool
    public let type: VideoPlaylistEntityType
    
    public var shouldShowAddButton: Bool {
        type == .user
    }
    
    public var isEmpty: Bool {
        thumbnail.type == .empty
    }
    
    public init(
        thumbnail: VideoPlaylistThumbnail,
        count: String,
        duration: String,
        title: String,
        isExported: Bool,
        type: VideoPlaylistEntityType
    ) {
        self.thumbnail = thumbnail
        self.count = count
        self.duration = duration
        self.title = title
        self.isExported = isExported
        self.type = type
    }
}

extension VideoPlaylistCellPreviewEntity {
    public static let placeholder = VideoPlaylistCellPreviewEntity(
        thumbnail: VideoPlaylistThumbnail(type: .empty, imageContainers: []),
        count: "",
        duration: "",
        title: "",
        isExported: false,
        type: .user
    )
}

public enum VideoPlaylistThumbnailCoverImageType: Equatable, Sendable {
    case normal
    case allVideosHasNoThumbnails
    case empty
}
