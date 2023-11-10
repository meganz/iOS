@testable import Search
import SearchMock
import SnapshotTesting
import XCTest
/* tests disabled until [https://jira.developers.mega.co.nz/browse/IOS-7827] is done
func testableView(
    thumbnailDisplayMode: ResultCellLayout.ThumbnailMode,
    properties: [ResultProperty] = [],
    selectionMode: Bool = false,
    selected: Bool = false
) -> SearchResultThumbnailItemView {
    
    return SearchResultThumbnailItemView(
        viewModel: testableSearchResultsViewModel(
            properties: properties,
            thumbnailDisplayMode: thumbnailDisplayMode
        )
        //            selected: .constant(selected ? [1] : []),
        //            selectionMode: .constant(selectionMode)
    )
}

final class SearchResultThumbnailItemViewTests_Horizontal: XCTestCase {
    
    let cellSizeHorizontal = SwiftUISnapshotLayout.fixed(width: 186, height: 52)
    
    func test_Horizontal_NoProperties() {
        let view = testableView(thumbnailDisplayMode: .horizontal)
        assertSnapshot(of: view, as: .image(layout: cellSizeHorizontal))
    }
    
    func test_Horizontal_NoPropertiesEditMode() {
        let view = testableView(thumbnailDisplayMode: .horizontal, selectionMode: true)
        assertSnapshot(of: view, as: .image(layout: cellSizeHorizontal))
    }
    
    func test_Horizontal_NoPropertiesEditModeSelected() {
        let view = testableView(thumbnailDisplayMode: .horizontal, selectionMode: true, selected: true)
        assertSnapshot(of: view, as: .image(layout: cellSizeHorizontal))
    }
    
    func test_Horizontal_SingleProminentProperty() {
        let view = testableView(thumbnailDisplayMode: .horizontal, properties: [propertyIcon(placement: .prominent)])
        assertSnapshot(of: view, as: .image(layout: cellSizeHorizontal))
    }
    
    func test_Horizontal_SingleSecondaryLeadingProperty() {
        let view = testableView(thumbnailDisplayMode: .horizontal, properties: [propertyIcon(placement: .secondary(.leading))])
        assertSnapshot(of: view, as: .image(layout: cellSizeHorizontal))
    }
    
    func test_Horizontal_SingleSecondaryTrailingProperty() {
        let view = testableView(thumbnailDisplayMode: .horizontal, properties: [propertyIcon(placement: .secondary(.trailing))])
        assertSnapshot(of: view, as: .image(layout: cellSizeHorizontal))
    }
    
    func test_Horizontal_SingleSecondaryTrailingEdgeProperty() {
        let view = testableView(thumbnailDisplayMode: .horizontal, properties: [propertyIcon(placement: .secondary(.trailingEdge))])
        assertSnapshot(of: view, as: .image(layout: cellSizeHorizontal))
    }
    
    // auxLine not displayed in the thumbnail
    func test_Horizontal_SingleAuxLineProperty() {
        let auxLine = ResultProperty(
            id: "id",
            content: .text("Some auxiliary text"),
            vibrancyEnabled: false,
            placement: { _ in .auxLine }
        )
        let view = testableView(thumbnailDisplayMode: .horizontal, properties: [auxLine])
        assertSnapshot(of: view, as: .image(layout: cellSizeHorizontal))
    }
}
*/
