import MEGADomain
import MEGASwiftUI

public struct VideoPlaylistCellPreviewEntity {
    let imageContainers: [any ImageContaining]
    let count: String
    let duration: String
    let title: String
    let isExported: Bool
    let type: VideoPlaylistEntityType
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
