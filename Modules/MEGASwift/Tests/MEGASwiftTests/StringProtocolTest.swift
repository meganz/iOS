import XCTest

final class StringProtocolTests: XCTestCase {
    func testEndIndex() throws {
        let palindrome = "temp%temp"
        
        let index = try XCTUnwrap(palindrome.endIndex(of: "%"))
        let leftText = palindrome[..<palindrome.index(before: index)]
        let rightText = palindrome[index...]
        
        XCTAssertEqual(leftText, rightText)
        XCTAssertNil(palindrome.endIndex(of: "a"))
        
        let validIndex = palindrome.endIndex(of: "T", options: .caseInsensitive)
        let invalidIndex = palindrome.endIndex(of: "T")
        let anotherIndex = try XCTUnwrap(validIndex)
    
        XCTAssertNotNil(validIndex)
        XCTAssertNil(invalidIndex)
        XCTAssertEqual(palindrome[..<anotherIndex], "t")
    }
}
