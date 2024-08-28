import MEGAPresentation
import SwiftUI

extension VideoPlaylistCellPreviewEntity {
    
    static func preview(isExported: Bool, imageContainers: [any ImageContaining] = []) -> VideoPlaylistCellPreviewEntity {
        VideoPlaylistCellPreviewEntity(
            thumbnail: VideoPlaylistThumbnail(type: .normal, imageContainers: []),
            count: "48 videos",
            duration: "02:11:21",
            title: "My custom playlist",
            isExported: isExported,
            type: .favourite
        )
    }
    
    private static var sampleImage: Image {
        PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image
    }
}
