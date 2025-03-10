import MEGADomain
import MEGAFoundation
import MEGAPresentation
import MEGASwift
import SwiftUI

extension NodeEntity {
    
    func toVideoCellPreviewEntity(
        thumbnailContainer: any ImageContaining,
        isDownloaded: Bool,
        searchText: String?
    ) -> VideoCellPreviewEntity {
        let description: String? = if let searchText,
                                      let description = description,
                                      searchText.isNotEmpty,
                                      description.containsIgnoringCaseAndDiacritics(searchText: searchText) {
            description
        } else {
            nil
        }

        return VideoCellPreviewEntity(
            isFavorite: isFavourite,
            imageContainer: thumbnailContainer,
            duration: TimeInterval(duration).timeString,
            title: name,
            description: description,
            searchText: searchText,
            size: FileSizeFormatter.memoryStyleString(fromByteCount: Int64(size)),
            isExported: isExported,
            label: label,
            hasThumbnail: hasThumbnail,
            isDownloaded: isDownloaded
        )
    }
}
