import Search
import UIKit

extension SearchResult {
    public static func resultWith(
        id: ResultId,
        title: String,
        properties: [ResultProperty] = [],
        thumbnailDisplayMode: ResultCellLayout.ThumbnailMode = .vertical,
        backgroundDisplayMode: VerticalBackgroundViewMode = .preview
    ) -> Self {
        .init(
            id: id,
            thumbnailDisplayMode: thumbnailDisplayMode,
            backgroundDisplayMode: backgroundDisplayMode,
            title: title,
            description: { _ in "Desc" },
            type: .node,
            properties: properties,
            thumbnailImageData: { UIImage(systemName: "scribble")!.pngData()! }
        )
    }
    public static func resultWith(id: ResultId) -> Self {
        .resultWith(
            id: id,
            title: "title_\(id)"
        )
    }
}

extension SearchResultSelection {
    public static func resultSelectionWith(
        id: ResultId,
        title: String,
        properties: [ResultProperty] = [],
        thumbnailDisplayMode: ResultCellLayout.ThumbnailMode = .vertical,
        backgroundDisplayMode: VerticalBackgroundViewMode = .preview,
        siblings: [ResultId] = []
    ) -> Self {
        .init(
            result: .resultWith(
                id: id,
                title: title,
                properties: properties,
                thumbnailDisplayMode: thumbnailDisplayMode,
                backgroundDisplayMode: backgroundDisplayMode
            ),
            siblingsProvider: { siblings }
        )
    }
    public static func resultSelectionWith(id: ResultId) -> Self {
        .resultSelectionWith(
            id: id,
            title: "title_\(id)"
        )
    }
}
