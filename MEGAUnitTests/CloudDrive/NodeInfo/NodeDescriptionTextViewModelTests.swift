@testable import MEGA
import XCTest

final class NodeDescriptionTextViewModelTests: XCTestCase {

    func testInitState_whenSet_shouldMatchResults() {
        let description = NodeDescriptionViewModel.Description.content("Some text")
        let sut = makeSUT(description: description)

        XCTAssertEqual(sut.descriptionString, "Some text")
        XCTAssertFalse(sut.isFocused)
    }

    func testInitState_withPlaceholder_shouldMatchResults() {
        let description = NodeDescriptionViewModel.Description.placeholder("Placeholder")
        let sut = makeSUT(description: description)

        XCTAssertEqual(sut.placeholder, "Placeholder")
        XCTAssertEqual(sut.descriptionString, "")
    }

    func testUpdatedDescriptionString_withNewline_shouldRemoveLastCharacterAndSave() {
        var savedDescription = ""
        let sut = makeSUT(saveDescription: { savedDescription = $0 })

        sut.descriptionString = "Some text\n"
        sut.updatedDescriptionString(newValue: sut.descriptionString)

        XCTAssertFalse(sut.isFocused)
        XCTAssertEqual(sut.descriptionString, "Some text")
        XCTAssertEqual(savedDescription, "Some text")
    }

    func testUpdatedDescriptionString_withExceedingCharacters_shouldTruncate() {
        let sut = makeSUT(maxCharactersAllowed: 5)

        sut.updatedDescriptionString(newValue: "Exceeding text")

        XCTAssertEqual(sut.descriptionString, "Excee")
    }

    func testUpdatedDescriptionString_withEmojiAndExceedingCharacters_shouldTruncate() {
        let sut = makeSUT(maxCharactersAllowed: 5)

        sut.updatedDescriptionString(newValue: "🇧🇩hi")

        XCTAssertEqual(sut.descriptionString, "🇧🇩h")
    }

    func testUpdatedDescriptionString_withValidCharacters_shouldUpdate() {
        var updatedDescription = ""
        let sut = makeSUT(descriptionUpdated: { updatedDescription = $0 })

        sut.descriptionString = "Valid"
        sut.updatedDescriptionString(newValue: sut.descriptionString)

        XCTAssertEqual(sut.descriptionString, "Valid")
        XCTAssertEqual(updatedDescription, "Valid")
    }

    // MARK: - Helpers

    private func makeSUT(
        description: NodeDescriptionViewModel.Description = .content("Default text"),
        editingDisabled: Bool = false,
        maxCharactersAllowed: Int = 100,
        descriptionUpdated: @escaping (String) -> Void = { _ in },
        saveDescription: @escaping (String) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> NodeDescriptionTextViewModel {
        let sut = NodeDescriptionTextViewModel(
            description: description,
            editingDisabled: editingDisabled,
            maxCharactersAllowed: maxCharactersAllowed,
            descriptionUpdated: descriptionUpdated,
            saveDescription: saveDescription
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
