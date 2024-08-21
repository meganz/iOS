@testable import MEGASwift
import XCTest

final class StringUTF16AdditionsTests: XCTestCase {

    func testUtf16ValidatedTruncation_withSimpleText_truncatesCorrectly() {
        let text = "Hello, world!"

        XCTAssertEqual(text.utf16ValidatedTruncation(to: 5), "Hello")
        XCTAssertEqual(text.utf16ValidatedTruncation(to: 12), "Hello, world")
        XCTAssertEqual(text.utf16ValidatedTruncation(to: 13), "Hello, world!")
    }

    func testUtf16ValidatedTruncation_withEmptyString_returnsNil() {
        let text = ""

        XCTAssertNil(text.utf16ValidatedTruncation(to: 1))
    }

    func testUtf16ValidatedTruncation_withEmoji_truncatesCorrectly() {
        let text = "Hello, world! 🌍"

        XCTAssertEqual(text.utf16ValidatedTruncation(to: 13), "Hello, world!")
        XCTAssertEqual(text.utf16ValidatedTruncation(to: 14), "Hello, world! ")
        XCTAssertEqual(text.utf16ValidatedTruncation(to: 15), "Hello, world! ")
        XCTAssertEqual(text.utf16ValidatedTruncation(to: 16), "Hello, world! 🌍")
    }

    func testUtf16ValidatedTruncation_withMultiByteCharacters_truncatesCorrectly() {
        let text = "Café"

        XCTAssertEqual(text.utf16ValidatedTruncation(to: 3), "Caf")
        XCTAssertEqual(text.utf16ValidatedTruncation(to: 4), "Café")
    }

    func testUtf16ValidatedTruncation_withZeroLength_returnsNil() {
        let text = "Hello, world!"

        XCTAssertNil(text.utf16ValidatedTruncation(to: 0))
    }

    func testUtf16ValidatedTruncation_withLengthExceedingString_returnsOriginalString() {
        let text = "Hello"

        XCTAssertEqual(text.utf16ValidatedTruncation(to: 10), "Hello")
    }
}
