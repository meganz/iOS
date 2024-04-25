import MEGASwiftUI
import SwiftUI

extension VideoPlaylistCellPreviewEntity {
    
    static func preview(isExported: Bool) -> VideoPlaylistCellPreviewEntity {
        VideoPlaylistCellPreviewEntity(
            imageContainers: [
                ImageContainer(image: sampleImage, type: .thumbnail),
                ImageContainer(image: sampleImage, type: .thumbnail),
                ImageContainer(image: sampleImage, type: .thumbnail),
                ImageContainer(image: sampleImage, type: .thumbnail)
            ],
            count: "48 videos",
            duration: "02:11:21",
            title: "My custom playlist",
            isExported: isExported
        )
    }
    
    private static var sampleImage: Image {
        PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image
    }
}
