@testable import MEGASwift
import XCTest

final class MEGASwiftTests: XCTestCase {
    private let helloMEGA = "Hello, MEGA!"
    private let helloMEGAbase64Encoded = "SGVsbG8sIE1FR0Eh"
    
    func testBase64Encoded() throws {
        let base64Encoded = try XCTUnwrap(helloMEGA.base64Encoded)
        XCTAssertEqual(base64Encoded, helloMEGAbase64Encoded)
    }
    
    func testBase64Decoded() throws {
        let string = try XCTUnwrap(helloMEGAbase64Encoded.base64Decoded)
        XCTAssertEqual(string, helloMEGA)
    }
    
    func testBase64Decoded_stringOmittingASinglePadding_shouldMatch() throws {
        let base64Encoded = "MTI6MDA"
        let string = try XCTUnwrap(base64Encoded.base64Decoded)
        XCTAssertEqual(string, "12:00")
    }
    
    func testBase64Decoded_stringOmittingMultiplePadding_shouldMatch() throws {
        let base64Encoded = "TWVldGluZyAxMzozOA"
        let string = try XCTUnwrap(base64Encoded.base64Decoded)
        XCTAssertEqual(string, "Meeting 13:38")
    }
    
    func testMemoryStyleString() {
        let oneMegaInBytes: Int64 = 1048576
        let onMegaString = "1 MB"
        XCTAssertEqual(onMegaString, String.memoryStyleString(fromByteCount: oneMegaInBytes))
    }
    
    func testSubString_withPlainString_shouldReturnCorrectString() {
        let sampleString = "This is a [A]test string[/A]"
        let helloMEGA = sampleString.subString(from: "[A]", to: "[/A]")
        XCTAssertEqual(helloMEGA, "test string")
    }
    
    func testSubString_withEmoji_shouldReturnCorrectString() {
        let sampleString = "This is a [C]🎉test🍏string🍎[/C]"
        let helloMEGA = sampleString.subString(from: "[C]", to: "[/C]")
        XCTAssertEqual(helloMEGA, "🎉test🍏string🍎")
    }
    
    func testSubString_shouldReturnNilString() {
        let sampleString = "This is a test string."
        let helloMEGA = sampleString.subString(from: "[A]", to: "[/A]")
        XCTAssertNil(helloMEGA)
    }
    
    func testSubString_withStartStringButNoEndString_shouldReturnNilString() {
        let sampleString = "This is a [A]test string."
        let helloMEGA = sampleString.subString(from: "[A]", to: "[/A]")
        XCTAssertNil(helloMEGA)
    }
    
    func testSubString_withEndStringButNoStartString_shouldReturnNilString() {
        let sampleString = "This is a test string.[/A]"
        let helloMEGA = sampleString.subString(from: "[A]", to: "[/A]")
        XCTAssertNil(helloMEGA)
    }

    func testContainsInvalidFileFolderNameCharacters_forValidFolderNameWithoutSpaces_shouldBeFalse() {
        XCTAssertFalse("NewFolder".containsInvalidFileFolderNameCharacters)
    }

    func testContainsInvalidFileFolderNameCharacters_forValidFolderNameWithSpaces_shouldBeFalse() {
        XCTAssertFalse("New Folder".containsInvalidFileFolderNameCharacters)
    }

    func testContainsInvalidFileFolderNameCharacters_forInvalidFolderNameWithPipeSymbol_shouldBeTrue() {
        XCTAssertTrue("New Folder|".containsInvalidFileFolderNameCharacters)
    }

    func testContainsInvalidFileFolderNameCharacters_forInvalidFolderNameWithStar_shouldBeTrue() {
        XCTAssertTrue("New Folder*".containsInvalidFileFolderNameCharacters)
    }

    func testContainsInvalidFileFolderNameCharacters_forInvalidFolderNameWithForwardSlash_shouldBeTrue() {
        XCTAssertTrue("New Folder/".containsInvalidFileFolderNameCharacters)
    }

    func testContainsInvalidFileFolderNameCharacters_forInvalidFolderNameWithColon_shouldBeTrue() {
        XCTAssertTrue("New Folder:".containsInvalidFileFolderNameCharacters)
    }

    func testContainsInvalidFileFolderNameCharacters_forInvalidFolderNameWithLesserThan_shouldBeTrue() {
        XCTAssertTrue("New Folder<".containsInvalidFileFolderNameCharacters)
    }

    func testContainsInvalidFileFolderNameCharacters_forInvalidFolderNameWithGreaterThan_shouldBeTrue() {
        XCTAssertTrue("New Folder>".containsInvalidFileFolderNameCharacters)
    }

    func testContainsInvalidFileFolderNameCharacters_forInvalidFolderNameWithQuestionMark_shouldBeTrue() {
        XCTAssertTrue("New Folder?".containsInvalidFileFolderNameCharacters)
    }

    func testContainsInvalidFileFolderNameCharacters_forInvalidFolderNameWithQuotation_shouldBeTrue() {
        XCTAssertTrue("New Folder\"".containsInvalidFileFolderNameCharacters)
    }

    func testContainsInvalidFileFolderNameCharacters_forInvalidFolderNameWithBackwardSlash_shouldBeTrue() {
        XCTAssertTrue("New Folder\\".containsInvalidFileFolderNameCharacters)
    }
    
    func testTrim_withWhitespaceAtBeginningAndEnd_returnsTrimmedString() {
        let string = "  Hello, MEGA!  "
        let trimmedString = string.trim
        XCTAssertEqual(trimmedString, helloMEGA)
    }
    
    func testBase64URLDecoded_withBase64URLString_returnsDecodedString() {
        let base64String = helloMEGAbase64Encoded.base64URLToBase64
        let decodedString = base64String.base64Decoded
        XCTAssertEqual(decodedString, helloMEGA)
    }
    
    func testMNZIsDecimalNumber_withNumberString_returnsTrue() {
        let numberString = "12345"
        XCTAssertTrue(numberString.mnz_isDecimalNumber)
        
        XCTAssertFalse(helloMEGA.mnz_isDecimalNumber)
    }
    
    func testMNZIsDecimalNumber_withNonNumberString_returnsFalse() {
        XCTAssertFalse(helloMEGA.mnz_isDecimalNumber)
    }
    
    func testAppendPathComponent_withBasePath_returnsAppendedPath() {
        let path = "/Users/mega/Documents"
        let appendedPath = path.append(pathComponent: "file.txt")
        XCTAssertEqual(appendedPath, "/Users/mega/Documents/file.txt")
    }
    
    func testInitialForAvatar_returnsFirstNonWhiteSpaceCharacter() {
        let string = "  Hello, World!  "
        let initial = string.initialForAvatar()
        XCTAssertEqual(initial, "H")
    }
    
    func testMatchetestMatchesRegex_withMatchingString_returnsTruesRegex() {
        XCTAssertTrue(helloMEGA.matches(regex: "Hello.*MEGA"))
        XCTAssertFalse(helloMEGA.matches(regex: "Goodbye.*MEGA"))
    }
    
    func testMatchesRegex_withNonMatchingString_returnsFalse() {
        XCTAssertFalse(helloMEGA.matches(regex: "Goodbye.*MEGA"))
    }
}
