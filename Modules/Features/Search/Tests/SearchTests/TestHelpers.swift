@testable import Search
import UIKit

enum TestAsset {
    private static func image(name: String) -> UIImage {
        let path = Bundle.module.path(forResource: name, ofType: nil)
        return UIImage(contentsOfFile: path!)!
    }
    enum Image {
        static let folder = image(name: "folder.png")
        static let scenery = image(name: "scenery.png")
    }
}

func propertyIcon(placement: PropertyPlacement) -> ResultProperty {
    .init(
        id: "id",
        content: .icon(image: UIImage(systemName: "wifi")!, layoutConfig: .init(scalable: true, size: 12)),
        vibrancyEnabled: false,
        placement: { _ in placement }
    )
}

@MainActor
func testableSearchResultsViewModel(
    properties: [ResultProperty] = [],
    backgroundDisplayMode: VerticalBackgroundViewMode = .preview
) -> SearchResultRowViewModel {
    let viewModel = SearchResultRowViewModel(
        result: .previewResult(
            idx: 1,
            backgroundDisplayMode: backgroundDisplayMode,
            properties: properties
        ),
        query: { nil },
        rowAssets: .example,
        colorAssets: .example,
        actions: .init(
            contextAction: {_ in },
            selectionAction: {},
            revampLongPress: {}
        ),
        swipeActions: []
    )
    viewModel.thumbnailImage = TestAsset.Image.folder
    return viewModel
}

extension SearchResult {
    static func previewResult(
        idx: UInt64,
        backgroundDisplayMode: VerticalBackgroundViewMode = .icon,
        properties: [ResultProperty] = []
    ) -> Self {
        .init(
            id: idx,
            isFolder: false,
            backgroundDisplayMode: backgroundDisplayMode,
            title: "title\(idx)",
            note: nil,
            tags: [],
            isSensitive: false,
            hasThumbnail: false,
            description: { _ in "desc\(idx)" },
            type: .node,
            properties: properties,
            thumbnailImageData: { UIImage(systemName: "rectangle")!.pngData()! },
            swipeActions: { _ in [] }
        )
    }
}
