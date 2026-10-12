import MEGAMarkdownEditor
@testable import MEGATextEditor
import Testing

@MainActor
struct MarkdownTextEditorContentStateTests {
    @Test func startsInLoadingWithEmptyText() {
        let sut = MarkdownTextEditorContentState()
        #expect(sut.screen == .loading)
        #expect(sut.text == "")
    }

    @Test func showEditorFromPreviewInPlainTextShowsEditorInRichText() {
        let sut = MarkdownTextEditorContentState()
        sut.screen = .preview
        sut.textEditorMode = .plainText
        sut.showEditor()
        #expect(sut.screen == .editor)
        #expect(sut.textEditorMode == .richText)
    }

    @Test func startsInRichTextMode() {
        let sut = MarkdownTextEditorContentState()
        #expect(sut.mode == .rich)
        #expect(sut.textEditorMode == .richText)
    }

    @Test func loadingKeepsProgress() {
        let sut = MarkdownTextEditorContentState()
        #expect(sut.loadingProgress == nil)
        sut.loadingProgress = 0.4
        #expect(sut.screen == .loading)
        #expect(sut.loadingProgress == 0.4)
    }

    @Test func flushEditorWithoutEditorDoesNothing() {
        let sut = MarkdownTextEditorContentState()
        sut.text = "kept"
        sut.flushEditor()
        #expect(sut.text == "kept")
        #expect(sut.screen == .loading)
    }
}
