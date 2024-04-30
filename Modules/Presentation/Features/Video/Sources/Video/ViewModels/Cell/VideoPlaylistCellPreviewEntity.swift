import MEGASwiftUI

struct VideoPlaylistCellPreviewEntity {
    let imageContainers: [any ImageContaining]
    let count: String
    let duration: String
    let title: String
    let isExported: Bool
}

extension VideoPlaylistCellPreviewEntity {
    static let placeholder = VideoPlaylistCellPreviewEntity(
        imageContainers: [],
        count: "",
        duration: "",
        title: "",
        isExported: false
    )
}
