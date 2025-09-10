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
        content: .icon(image: UIImage(systemName: "wifi")!, scalable: true),
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
        previewContent: .example,
        actions: .init(
            contextAction: {_ in },
            selectionAction: {},
            previewTapAction: {}
        ),
        swipeActions: []
    )
    viewModel.thumbnailImage = TestAsset.Image.folder
    return viewModel
}
