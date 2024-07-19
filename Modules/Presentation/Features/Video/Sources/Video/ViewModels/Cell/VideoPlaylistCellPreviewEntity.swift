import MEGADomain
import MEGAPresentation

public struct VideoPlaylistCellPreviewEntity {
    let imageContainers: [any ImageContaining]
    let count: String
    let duration: String
    var title: String
    let isExported: Bool
    let type: VideoPlaylistEntityType
    
    var shouldShowAddButton: Bool {
        type == .user
    }
}

extension VideoPlaylistCellPreviewEntity {
    static let placeholder = VideoPlaylistCellPreviewEntity(
        imageContainers: [],
        count: "",
        duration: "",
        title: "",
        isExported: false,
        type: .user
    )
}
