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
                placement: { _ in .prominent(.trailing) }
            ),
            ResultProperty(
                id: "2",
                content: .text("DEF"),
                vibrancyEnabled: true,
                placement: { _ in .prominent(.trailing) }
            )
        ]
        
        let prominent = properties.propertiesFor(mode: .list, placement: .prominent(.trailing))
        XCTAssertEqual(prominent.map(\.id), ["2", "1"])
    }
}
