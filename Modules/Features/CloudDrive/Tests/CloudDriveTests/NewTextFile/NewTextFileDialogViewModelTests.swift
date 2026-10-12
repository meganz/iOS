@testable import CloudDrive
import MEGAL10n
import MEGASwift
import Testing

@MainActor
struct NewTextFileDialogViewModelTests {
    private func makeSUT() -> NewTextFileDialogViewModel {
        NewTextFileDialogViewModel(onCreate: { _ in }, onCancel: {})
    }

    private final class Calls {
        var created: [String] = []
        var cancelCount = 0
    }

    private func makeSUT(calls: Calls) -> NewTextFileDialogViewModel {
        NewTextFileDialogViewModel(onCreate: { calls.created.append($0) }, onCancel: { calls.cancelCount += 1 })
    }

    @Test func startsWithTxtNameAndBoxUnchecked() {
        let sut = makeSUT()
        #expect(sut.fileName == ".txt")
        #expect(sut.isRichTextChecked == false)
    }

    @Test func checkingBoxReplacesExtensionWithMd() {
        let sut = makeSUT()
        sut.setFileName("notes.txt")
        sut.isRichTextChecked = true
        #expect(sut.fileName == "notes.md")
        #expect(sut.isRichTextChecked == true)
    }

    @Test func checkingBoxOnNameWithoutExtensionAppendsMd() {
        let sut = makeSUT()
        sut.setFileName("notes")
        sut.isRichTextChecked = true
        #expect(sut.fileName == "notes.md")
    }

    @Test func typingMarkdownExtensionChecksBox() {
        let sut = makeSUT()
        sut.setFileName("notes.md")
        #expect(sut.isRichTextChecked == true)
    }

    @Test func typingMarkdownExtensionKeepsTheTypedName() {
        let sut = makeSUT()
        sut.setFileName("notes.markdown")
        #expect(sut.isRichTextChecked == true)
        #expect(sut.fileName == "notes.markdown")
    }

    @Test func typingOtherExtensionUnchecksBox() {
        let sut = makeSUT()
        sut.isRichTextChecked = true
        sut.setFileName("notes.md")
        sut.setFileName("notes.txt")
        #expect(sut.isRichTextChecked == false)
        #expect(sut.fileName == "notes.txt")
    }

    @Test func uncheckingRestoresLastPlainExtension() {
        let sut = makeSUT()
        sut.setFileName("notes.log")
        sut.isRichTextChecked = true
        #expect(sut.fileName == "notes.md")
        sut.isRichTextChecked = false
        #expect(sut.fileName == "notes.log")
        #expect(sut.isRichTextChecked == false)
    }

    @Test func uncheckingWithoutEarlierExtensionRestoresTxt() {
        let sut = makeSUT()
        sut.setFileName("notes")
        sut.isRichTextChecked = true
        sut.isRichTextChecked = false
        #expect(sut.fileName == "notes.txt")
    }

    @Test func typingMarkdownExtensionKeyByKeyThenUncheckingRestoresTxt() {
        let sut = makeSUT()
        for name in ["n", "n.", "n.m", "n.md"] {
            sut.setFileName(name)
        }
        #expect(sut.isRichTextChecked == true)
        sut.isRichTextChecked = false
        #expect(sut.fileName == "n.txt")
    }

    @Test func checkingBoxWithEmptyExtensionKeepsSavedExtension() {
        let sut = makeSUT()
        sut.setFileName("notes.log")
        sut.isRichTextChecked = true
        // The user removes the extension and checks the box again.
        sut.setFileName("notes.")
        sut.isRichTextChecked = true
        #expect(sut.fileName == "notes.md")
        sut.isRichTextChecked = false
        #expect(sut.fileName == "notes.log")
    }

    @Test(arguments: ["", "   ", "a/b.txt", "a?b.txt"])
    func createIsDisabledForEmptyOrInvalidName(name: String) {
        let sut = makeSUT()
        sut.setFileName(name)
        #expect(sut.isCreateEnabled == false)
    }

    @Test func createIsEnabledForValidName() {
        let sut = makeSUT()
        sut.setFileName("notes.txt")
        #expect(sut.isCreateEnabled)
        #expect(sut.hasInvalidCharacters == false)
    }

    @Test func invalidNameShowsErrorTitle() {
        let sut = makeSUT()
        #expect(sut.title == Strings.Localizable.newTextFile)

        sut.setFileName("a?b.txt")

        #expect(sut.title == Strings.Localizable.General.Error.charactersNotAllowed(String.Constants.invalidFileFolderNameCharactersToDisplay))
        #expect(sut.title != Strings.Localizable.newTextFile)
    }

    @Test func createSendsTrimmedFileName() {
        let calls = Calls()
        let sut = makeSUT(calls: calls)
        sut.setFileName("  notes.md  ")

        sut.didTapCreate()

        #expect(calls.created == ["notes.md"])
    }

    @Test func returnWithValidNameCreatesFile() {
        let calls = Calls()
        let sut = makeSUT(calls: calls)
        sut.setFileName("notes.txt")

        sut.didSubmit()

        #expect(calls.created == ["notes.txt"])
    }

    @Test func returnWithInvalidNameDoesNothing() {
        let calls = Calls()
        let sut = makeSUT(calls: calls)
        sut.setFileName("a/b.txt")

        sut.didSubmit()

        #expect(calls.created.isEmpty)
    }

    @Test func cancelCallsCancelHandler() {
        let calls = Calls()
        let sut = makeSUT(calls: calls)

        sut.didTapCancel()

        #expect(calls.cancelCount == 1)
        #expect(calls.created.isEmpty)
    }
}
