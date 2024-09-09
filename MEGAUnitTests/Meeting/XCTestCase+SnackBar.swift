@testable import MEGA
import MEGASwiftUI
import XCTest

// here we compare only message and button action title, which is enough and
// not tied closely to == implementation
extension XCTestCase {
    func XCTAssertSnackBarEqual(
        _ lhs: SnackBar?,
        _ rhs: SnackBar?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs?.message, rhs?.message, file: file, line: line)
        XCTAssertEqual(lhs?.action, rhs?.action, file: file, line: line)
    }
}
