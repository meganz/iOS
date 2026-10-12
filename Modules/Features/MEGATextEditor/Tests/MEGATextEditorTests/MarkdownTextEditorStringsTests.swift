import MEGAL10n
import MEGAMarkdown
import MEGAMarkdownEditor
@testable import MEGATextEditor
import Testing

struct MarkdownTextEditorStringsTests {
    @Test func megaEditorStringsUseMEGAL10n() {
        let strings = MarkdownEditorStrings.mega
        #expect(strings.bold == Strings.Localizable.MarkdownEditor.Toolbar.bold)
        #expect(strings.bulletList == Strings.Localizable.MarkdownEditor.Toolbar.bulletedList)
        #expect(strings.heading1 == Strings.Localizable.MarkdownEditor.TextStyle.heading1)
        #expect(strings.body == Strings.Localizable.MarkdownEditor.TextStyle.body)
        #expect(strings.linkDialogTitle == Strings.Localizable.MarkdownEditor.LinkDialog.title)
        #expect(strings.sourceEditor == Strings.Localizable.MarkdownEditor.Accessibility.sourceEditor)
        #expect(strings.continueAtEnd == Strings.Localizable.MarkdownEditor.Accessibility.continueAtEnd)
    }

    @Test func megaEditorNoticesUseMEGAL10n() {
        let strings = MarkdownEditorStrings.mega
        #expect(strings.fileTooLargeNotice == Strings.Localizable.MarkdownEditor.Notice.fileTooLargeForRichText)
        #expect(strings.blockTooLongForRichNotice == Strings.Localizable.MarkdownEditor.Notice.sectionTooLongForRichText)
        #expect(strings.lineTooLongNotice == Strings.Localizable.MarkdownEditor.Notice.lineTooLong)
        #expect(strings.fileTooLargeToEditNotice == MarkdownEditorStrings.english.fileTooLargeToEditNotice)
    }

    @Test func megaPreviewStringsUseMEGAL10n() {
        let strings = MarkdownPreviewStrings.mega
        let english = MarkdownPreviewStrings.english
        #expect(strings.tooLarge == english.tooLarge)
        #expect(strings.shownAsPlainText == Strings.Localizable.MarkdownEditor.Preview.sectionShownAsPlainText)
    }
}
