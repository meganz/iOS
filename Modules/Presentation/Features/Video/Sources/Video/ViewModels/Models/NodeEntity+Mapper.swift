import MEGADomain
import MEGAFoundation
import MEGAPresentation
import SwiftUI

extension NodeEntity {
    
    func toVideoCellPreviewEntity(
        thumbnailContainer: any ImageContaining,
        isDownloaded: Bool,
        description: String?
    ) -> VideoCellPreviewEntity {
        VideoCellPreviewEntity(
            isFavorite: isFavourite,
            imageContainer: thumbnailContainer,
            duration: TimeInterval(duration).timeString,
            title: name,
            description: description,
            size: FileSizeFormatter.memoryStyleString(fromByteCount: Int64(size)),
            isExported: isExported,
            label: label,
            hasThumbnail: hasThumbnail,
            isDownloaded: isDownloaded
        )
    }
}
