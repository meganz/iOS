import MEGAAnalyticsiOS
import MEGAL10n
import MEGAMarkdownEditor
@testable import MEGATextEditor
import Testing

struct MarkdownTextEditorModeTests {
    @Test func modesListPlainTextThenRichText() {
        #expect(MarkdownTextEditorMode.allCases == [.plainText, .richText])
    }

    @Test func modeTitlesUseMEGAL10n() {
        #expect(MarkdownTextEditorMode.plainText.title == Strings.Localizable.MarkdownEditor.Mode.plainText)
        #expect(MarkdownTextEditorMode.richText.title == Strings.Localizable.MarkdownEditor.Mode.richText)
    }

    @Test func modeMapsToEditorModeBothWays() {
        #expect(MarkdownTextEditorMode.plainText.editorMode == .source)
        #expect(MarkdownTextEditorMode.richText.editorMode == .rich)
        #expect(MarkdownTextEditorMode(editorMode: .source) == .plainText)
        #expect(MarkdownTextEditorMode(editorMode: .rich) == .richText)
    }

    @Test func menuItemEventForRichTextIsRichTextModeMenuItemEvent() {
        #expect(MarkdownTextEditorMode.richText.menuItemEvent is TextEditorRichTextModeMenuItemEvent)
    }

    @Test func menuItemEventForPlainTextIsPlainTextModeMenuItemEvent() {
        #expect(MarkdownTextEditorMode.plainText.menuItemEvent is TextEditorPlainTextModeMenuItemEvent)
    }
}
