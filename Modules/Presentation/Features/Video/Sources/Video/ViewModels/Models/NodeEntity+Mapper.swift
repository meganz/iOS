import MEGADomain
import MEGAPresentation
import SwiftUI

extension NodeEntity {
    
    func toVideoCellPreviewEntity(thumbnailContainer: any ImageContaining) -> VideoCellPreviewEntity {
        VideoCellPreviewEntity(
            isFavorite: isFavourite,
            imageContainer: thumbnailContainer,
            duration: VideoDurationFormatter.formatDuration(seconds: UInt(max(duration, 0))),
            title: name,
            size: FileSizeFormatter.memoryStyleString(fromByteCount: Int64(size)),
            isExported: isExported,
            label: label
        )
    }
}
