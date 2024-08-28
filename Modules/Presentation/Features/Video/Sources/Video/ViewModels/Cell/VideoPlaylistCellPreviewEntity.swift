import MEGADomain
import MEGAPresentation

public struct VideoPlaylistCellPreviewEntity {
    let thumbnail: VideoPlaylistThumbnail
    let count: String
    let duration: String
    var title: String
    let isExported: Bool
    let type: VideoPlaylistEntityType
    
    var shouldShowAddButton: Bool {
        type == .user
    }
    
    var isEmpty: Bool {
        thumbnail.type == .empty
    }
}

extension VideoPlaylistCellPreviewEntity {
    static let placeholder = VideoPlaylistCellPreviewEntity(
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
