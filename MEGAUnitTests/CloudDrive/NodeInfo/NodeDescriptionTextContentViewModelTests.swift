@testable import MEGA
import XCTest

final class NodeDescriptionTextContentViewModelTests: XCTestCase {

    func testInitState_whenSet_shouldMatchResults() {
        let textViewEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let sut = makeSUT(editingDisabled: true, textViewEdgeInsets: textViewEdgeInsets)
        XCTAssertTrue(sut.editingDisabled)
        XCTAssertEqual(sut.textViewEdgeInsets, textViewEdgeInsets)
    }

    func testShouldEndEditing_withSingleNewlineCharacter_shouldReturnTrue() {
        let sut = makeSUT()
        XCTAssertTrue(sut.shouldEndEditing(for: "\n"))
    }

    func testShouldEndEditing_withMultipleCharacters_shouldReturnFalse() {
        let sut = makeSUT()
        XCTAssertFalse(sut.shouldEndEditing(for: "text\n"))
    }

    func testShouldChangeTextIn_whenWithinCharacterLimit_shouldReturnTrue() {
        let sut = makeSUT()
        XCTAssertTrue(sut.shouldChangeTextIn(in: NSRange(location: 0, length: 0), currentText: "current", replacementText: "text"))
    }

    func testShouldChangeTextIn_whenExceedingCharacterLimit_shouldReturnFalse() {
        let sut = makeSUT(maxCharactersAllowed: 10)
        XCTAssertFalse(sut.shouldChangeTextIn(in: NSRange(location: 0, length: 0), currentText: "current", replacementText: "additionalText"))
    }

    func testTruncateAndReplaceText_whenWithinLimit_shouldReturnUpdatedText() {
        let sut = makeSUT(maxCharactersAllowed: 20)
        let updatedText = sut.truncateAndReplaceText(
            in: NSRange(location: 0, length: 7),
            of: "current",
            with: "newText"
        )
        XCTAssertEqual(updatedText, "newText")
    }

    func testTruncateAndReplaceText_whenExceedingLimit_shouldReturnTruncatedText() {
        let sut = makeSUT(maxCharactersAllowed: 10)
        let updatedText = sut.truncateAndReplaceText(
            in: NSRange(location: 0, length: 7),
            of: "current",
            with: "veryLongReplacementText"
        )
        XCTAssertEqual(updatedText, "veryLongRe")
    }

    func testTruncateAndReplaceText_whenInvalidRange_shouldReturnNil() {
        let sut = makeSUT(maxCharactersAllowed: 10)
        let updatedText = sut.truncateAndReplaceText(
            in: NSRange(location: 20, length: 7),
            of: "current",
            with: "text"
        )
        XCTAssertNil(updatedText)
    }

    // MARK: - Helpers

    private func makeSUT(
        maxCharactersAllowed: Int = 300,
        editingDisabled: Bool = true,
        textViewEdgeInsets: UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> NodeDescriptionTextContentViewModel {
        let sut = NodeDescriptionTextContentViewModel(
            maxCharactersAllowed: maxCharactersAllowed,
            editingDisabled: editingDisabled,
            textViewEdgeInsets: textViewEdgeInsets,
            descriptionUpdated: { _ in },
            saveDescription: { _ in }
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
