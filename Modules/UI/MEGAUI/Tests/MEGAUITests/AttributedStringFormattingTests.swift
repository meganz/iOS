@testable import MEGAUI
import XCTest

final class AttributedStringFormattingTests: XCTestCase {
    let expectedURL = "http://www.a-given-url.com"
    let expectedBoldString = "bold"
    
    private func makeSUT(input: String) -> AttributedString {
        var attributedString = AttributedString(input)
        attributedString = attributedString.convertURLsToClickableLinks()
        attributedString = attributedString.applyBoldFormattingFromHTMLTags()
        return attributedString
    }
    
    private func checkURL(
        in attributedString: AttributedString,
        expectedURL: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if let range = attributedString.range(of: expectedURL) {
            XCTAssertEqual(
                attributedString[range].link,
                URL(string: expectedURL),
                "Expected link attribute with URL \(expectedURL) in substring \(expectedURL), but found \(String(describing: attributedString[range].link))",
                file: file,
                line: line
            )
        } else {
            XCTFail(
                "Substring \(expectedURL) not found in the attributed string",
                file: file,
                line: line
            )
        }
    }
    
    private func checkBoldFormatting(
        in attributedString: AttributedString,
        expectedBoldString: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if let range = attributedString.range(of: expectedBoldString) {
            XCTAssertEqual(
                attributedString[range].inlinePresentationIntent,
                .stronglyEmphasized,
                "Expected strongly emphasised attribute in substring \(expectedBoldString)",
                file: file,
                line: line
            )
        } else {
            XCTFail(
                "Substring \(expectedBoldString) not found in the attributed string",
                file: file,
                line: line
            )
        }
    }

    func testConvertURLsToClickableLinks_withValidURL_setsLinkAttribute() {
        let testString = "Check out \(expectedURL) for more information."
        let attributedString = makeSUT(input: testString)
        
        checkURL(
            in: attributedString,
            expectedURL: expectedURL
        )
    }

    func testApplyBoldFormattingFromHTMLTags_withBoldTags_appliesStronglyEmphasizedAttribute() {
        let testString = "This is a <b>\(expectedBoldString)</b> statement."
        let attributedString = makeSUT(input: testString)
        
        checkBoldFormatting(
            in: attributedString,
            expectedBoldString: expectedBoldString
        )
    }
    
    func testBothCases_withURLAndBoldTags_appliesBothAttributes() {
        let testString = "Check out \(expectedURL) for a <b>\(expectedBoldString)</b> example."
        let attributedString = makeSUT(input: testString)
        
        checkURL(
            in: attributedString,
            expectedURL: expectedURL
        )
        
        checkBoldFormatting(
            in: attributedString,
            expectedBoldString: expectedBoldString
        )
    }
}
