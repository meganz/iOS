import Foundation
@testable import MEGAFoundation
import XCTest

final class String_DateTests: XCTestCase {
    func test_date_validISO8601String_returnsCorrectDate() throws {
        let expectedDate = Date(timeIntervalSince1970: 0)

        let iso8601String = "1970-01-01T00:00:00Z"
        let actualDate = try iso8601String.date

        XCTAssertEqual(actualDate, expectedDate, "Converting a valid ISO8601 string should return the correct date")
    }

    func test_date_invalidISO8601String_throwsInvalidISO8601DateFormat() {
        let invalidISO8601String = "InvalidDate"

        XCTAssertThrowsError(try invalidISO8601String.date) { error in
            XCTAssertEqual(error as? DateFormattingError, DateFormattingError.invalidISO8601DateFormat, "Attempting to convert an invalid ISO8601 string should throw invalidISO8601DateFormat error")
        }
    }
}
