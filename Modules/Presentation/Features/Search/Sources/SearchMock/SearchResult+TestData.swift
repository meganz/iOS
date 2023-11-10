import Search
import UIKit

extension SearchResult {
    public static func resultWith(
        id: ResultId,
        title: String,
        thumbnailDisplayMode: ResultCellLayout.ThumbnailMode = .vertical,
        backgroundDisplayMode: VerticalBackgroundViewMode = .preview
    ) -> Self {
        .init(
            id: id,
            thumbnailDisplayMode: thumbnailDisplayMode,
            backgroundDisplayMode: backgroundDisplayMode,
            title: title,
            description: "Desc",
            type: .node,
            properties: [],
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
