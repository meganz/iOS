@testable import Search
import SearchMock
import SnapshotTesting
import XCTest

/* tests disabled until [https://jira.developers.mega.co.nz/browse/IOS-7827] is done
final class SearchResultRowViewTests: XCTestCase {
    
    func testableView(
        properties: [ResultProperty] = [],
        selectionMode: Bool = false,
        selected: Bool = false
    ) -> SearchResultRowView {
        
        return SearchResultRowView(
            viewModel: testableSearchResultsViewModel(
                properties: properties
            ),
            selected: .constant(selected ? [1] : []),
            selectionMode: .constant(selectionMode)
        )
    }
    
    let rowSize = SwiftUISnapshotLayout.fixed(width: 320, height: 60)
    
    func testNoProperties() {
        let view = testableView()
        assertSnapshot(of: view, as: .image(layout: rowSize))
    }
    
    func testNoPropertiesEditMode() {
        let view = testableView(selectionMode: true)
        assertSnapshot(of: view, as: .image(layout: rowSize))
    }
    
    func testNoPropertiesEditModeSelected() {
        let view = testableView(selectionMode: true, selected: true)
        assertSnapshot(of: view, as: .image(layout: rowSize))
    }
    
    func testSingleProminentProperty() {
        let view = testableView(properties: [propertyIcon(placement: .prominent)])
        assertSnapshot(of: view, as: .image(layout: rowSize))
    }
    
    func testSingleSecondaryLeadingProperty() {
        let view = testableView(properties: [propertyIcon(placement: .secondary(.leading))])
        assertSnapshot(of: view, as: .image(layout: rowSize))
    }
    
    func testSingleSecondaryTrailingPropertyEdit() {
        let view = testableView(properties: [propertyIcon(placement: .secondary(.trailing))])
        assertSnapshot(of: view, as: .image(layout: rowSize))
    }
    
    func testSingleSecondaryTrailingEdgeProperty() {
        let view = testableView(properties: [propertyIcon(placement: .secondary(.trailingEdge))])
        assertSnapshot(of: view, as: .image(layout: rowSize))
    }
    
    func testSingleAuxLineProperty() {
        let auxLine = ResultProperty(
            id: "id",
            content: .text("Some auxiliary text"),
            vibrancyEnabled: false,
            placement: { _ in .auxLine }
        )
        let view = testableView(properties: [auxLine])
        assertSnapshot(of: view, as: .image(layout: rowSize))
    }
}
*/
