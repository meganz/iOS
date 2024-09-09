@testable import MEGA
import MEGAL10n
import XCTest

final class NodeDescriptionCellViewModelTests: XCTestCase {

    func testInitState_whenSet_shouldMatchGivenParameters() {
        let textViewEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        let sut = makeSUT(editingDisabled: { true }, textViewEdgeInsets: textViewEdgeInsets)
        XCTAssertTrue(sut.editingDisabled())
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

    func testTruncateAndReplaceText_whenWithinLimitWithEmoji_shouldReturnUpdatedText() {
        let sut = makeSUT(maxCharactersAllowed: 20)
        let updatedText = sut.truncateAndReplaceText(
            in: NSRange(location: 0, length: 7),
            of: "current",
            with: "🚀"
        )
        XCTAssertEqual(updatedText, "🚀")
    }

    func testTruncateAndReplaceText_whenExceedingLimitWithEmoji_shouldReturnTruncatedText() {
        let sut = makeSUT(maxCharactersAllowed: 5)
        let updatedText = sut.truncateAndReplaceText(
            in: NSRange(location: 0, length: 7),
            of: "current",
            with: "🚀🌍🌕"
        )
        XCTAssertEqual(updatedText, "🚀🌍")
    }

    func testTruncateAndReplaceText_whenReplacingWithEmojiSequence_shouldReturnValidTruncation() {
        let sut = makeSUT(maxCharactersAllowed: 2)
        let updatedText = sut.truncateAndReplaceText(
            in: NSRange(location: 0, length: 2),
            of: "Hi",
            with: "🚀"
        )
        XCTAssertEqual(updatedText, "🚀")
    }

    func testDescriptionUpdatedClosure_whenTriggered_shouldCallClosure() {
        var wasCalled = false
        let sut = makeSUT(descriptionUpdated: { _ in wasCalled = true })
        sut.descriptionUpdated("Test")
        XCTAssertTrue(wasCalled)
    }

    func testSaveDescriptionClosure_whenTriggered_shouldCallClosure() {
        var wasCalled = false
        let sut = makeSUT(saveDescription: { _ in wasCalled = true })
        sut.saveDescription("Test")
        XCTAssertTrue(wasCalled)
    }
    
    func testDisplayTest_withNilDescription_whenEditingIsTrue_shouldReturnEmptyString() {
        let sut = makeSUT(descriptionProvider: { .init(content: nil) })
        let output = sut.displayText(isEditing: true)
        XCTAssertEqual(output, "")
    }
    
    func testDisplayTest_withNilDescription_whenEditingIsFalse_shouldReturnEmptyString() {
        let sut = makeSUT(descriptionProvider: { .init(content: nil) })
        let output = sut.displayText(isEditing: false)
        XCTAssertEqual(output, sut.placeholderText)
    }
    
    func testDisplayTest_withContentDescription_whenEditingIsTrue_shouldReturnEmptyString() {
        let sut = makeSUT(descriptionProvider: { .init(content: "desc") })
        let output = sut.displayText(isEditing: true)
        XCTAssertEqual(output, "desc")
    }
    
    func testDisplayTest_withContentDescription_whenEditingIsFalse_shouldReturnEmptyString() {
        let sut = makeSUT(descriptionProvider: { .init(content: "desc") })
        let output = sut.displayText(isEditing: false)
        XCTAssertEqual(output, "desc")
    }
    
    func testPlaceholderText_whenHasOnlyAccessTrue_shouldDisplayReadOnlyPlaceholder() {
        let sut = makeSUT(hasReadOnlyAccess: { true })
        XCTAssertEqual(sut.placeholderText, Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly)
    }
    
    func testPlaceholderText_whenHasOnlyAccessTrue_shouldDisplayReadWritePlaceholder() {
        let sut = makeSUT(hasReadOnlyAccess: { false })
        XCTAssertEqual(sut.placeholderText, Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readWrite)
    }
    
    func testIsPlaceholder_whenDescriptionIsContent_shouldReturnFalse() {
        let sut = makeSUT(descriptionProvider: { .init(content: "desc") })
        XCTAssertFalse(sut.isPlaceholder)
    }
    
    func testIsPlaceholder_whenDescriptionIsPlaceholder_shouldReturnTrue() {
        let sut = makeSUT(descriptionProvider: { .init(content: nil) })
        XCTAssertTrue(sut.isPlaceholder)
    }

    // MARK: - Helpers

    private func makeSUT(
        maxCharactersAllowed: Int = 300,
        editingDisabled: @escaping () -> Bool = { true },
        textViewEdgeInsets: UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0),
        descriptionProvider: @escaping () -> NodeDescriptionCellControllerModel.Description? = { .init(content: "") },
        hasReadOnlyAccess: @escaping () -> Bool = { true },
        descriptionUpdated: @escaping (String) -> Void = { _ in },
        saveDescription: @escaping (String) -> Void = { _ in },
        isTextViewFocused: @escaping (Bool) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> NodeDescriptionCellViewModel {
        let sut = NodeDescriptionCellViewModel(
            maxCharactersAllowed: maxCharactersAllowed,
            editingDisabled: editingDisabled,
            textViewEdgeInsets: textViewEdgeInsets, 
            descriptionProvider: descriptionProvider,
            hasReadOnlyAccess: hasReadOnlyAccess,
            descriptionUpdated: descriptionUpdated,
            saveDescription: saveDescription, 
            isTextViewFocused: isTextViewFocused
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
