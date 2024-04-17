import XCTest
@testable import MEGASwift

enum TestEnum: String, CaseIterable {
    case case1
    case case2
    case case3
}

final class CaseIterableAdditionsTests: XCTestCase {
    func testAllValues() {
        let expectedValues: [String] = ["case1", "case2", "case3"]
        XCTAssertEqual(TestEnum.allValues, expectedValues)
    }
}
