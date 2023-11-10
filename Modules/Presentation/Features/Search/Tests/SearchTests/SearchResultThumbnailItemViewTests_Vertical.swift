@testable import Search
import SearchMock
import SnapshotTesting
import XCTest
/* tests disabled until [https://jira.developers.mega.co.nz/browse/IOS-7827] is done
final class SearchResultThumbnailItemViewTests_Vertical: XCTestCase {
    
    let cellsSizeVertical = SwiftUISnapshotLayout.fixed(width: 186, height: 215)
    
    func test_Vertical_NoProperties() {
        let view = testableView(thumbnailDisplayMode: .vertical)
        assertSnapshot(of: view, as: .image(layout: cellsSizeVertical))
    }
    
    func test_Vertical_NoPropertiesEditMode() {
        let view = testableView(thumbnailDisplayMode: .vertical, selectionMode: true)
        assertSnapshot(of: view, as: .image(layout: cellsSizeVertical))
    }
    
    func test_Vertical_NoPropertiesEditModeSelected() {
        let view = testableView(thumbnailDisplayMode: .vertical, selectionMode: true, selected: true)
        assertSnapshot(of: view, as: .image(layout: cellsSizeVertical))
    }
    
    func test_Vertical_SingleProminentProperty() {
        let view = testableView(thumbnailDisplayMode: .vertical, properties: [propertyIcon(placement: .prominent)])
        assertSnapshot(of: view, as: .image(layout: cellsSizeVertical))
    }
    
    func test_Vertical_SingleSecondaryLeadingProperty() {
        let view = testableView(thumbnailDisplayMode: .vertical, properties: [propertyIcon(placement: .secondary(.leading))])
        assertSnapshot(of: view, as: .image(layout: cellsSizeVertical))
    }
    
    func test_Vertical_SingleSecondaryTrailingProperty() {
        let view = testableView(thumbnailDisplayMode: .vertical, properties: [propertyIcon(placement: .secondary(.trailing))])
        assertSnapshot(of: view, as: .image(layout: cellsSizeVertical))
    }
    
    func test_Vertical_SingleSecondaryTrailingEdgeProperty() {
        let view = testableView(thumbnailDisplayMode: .vertical, properties: [propertyIcon(placement: .secondary(.trailingEdge))])
        assertSnapshot(of: view, as: .image(layout: cellsSizeVertical))
    }
    
    // auxLine not displayed in the thumbnail
    func test_Vertical_SingleAuxLineProperty() {
        let auxLine = ResultProperty(
            id: "id",
            content: .text("Some auxiliary text"),
            vibrancyEnabled: false,
            placement: { _ in .auxLine }
        )
        let view = testableView(thumbnailDisplayMode: .vertical, properties: [auxLine])
        assertSnapshot(of: view, as: .image(layout: cellsSizeVertical))
    }
}
*/
