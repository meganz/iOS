@testable import Search
import SearchMock
import XCTest

final class Array_ResultProperty_ViewTests: XCTestCase {
    func test_Sorting_vibrantFirst() {
        let properties = [
            ResultProperty(
                id: "1",
                content: .text("ABC"),
                vibrancyEnabled: false,
                placement: { _ in .prominent }
            ),
            ResultProperty(
                id: "2",
                content: .text("DEF"),
                vibrancyEnabled: true,
                placement: { _ in .prominent }
            )
        ]
        
        let prominent = properties.propertiesFor(mode: .list, placement: .prominent)
        XCTAssertEqual(prominent.map(\.id), ["2", "1"])
    }
}
