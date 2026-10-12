@testable import MEGATextEditor
import Testing

struct MarkdownTextEditorRouteTests {
    private let limit: UInt64 = 100 * 1024 * 1024

    @Test func markdownNameWithGateOnRoutesToMarkdownFile() {
        #expect(MarkdownTextEditorRoute(fileName: "notes.md", sizeInBytes: 10, isEnabled: true) == .markdownFile)
        #expect(MarkdownTextEditorRoute(fileName: "notes.markdown", sizeInBytes: 10, isEnabled: true) == .markdownFile)
    }

    @Test func markdownNameWithGateOffRoutesToOtherFile() {
        #expect(MarkdownTextEditorRoute(fileName: "notes.md", sizeInBytes: 10, isEnabled: false) == .otherFile)
    }

    @Test func plainTextNameWithGateOnRoutesToOtherFile() {
        #expect(MarkdownTextEditorRoute(fileName: "notes.txt", sizeInBytes: 10, isEnabled: true) == .otherFile)
        #expect(MarkdownTextEditorRoute(fileName: "notes", sizeInBytes: 10, isEnabled: true) == .otherFile)
    }

    @Test func overLimitMarkdownRoutesToTooLarge() {
        #expect(MarkdownTextEditorRoute(fileName: "notes.md", sizeInBytes: limit + 1, isEnabled: true) == .tooLarge)
    }

    @Test func markdownAtLimitRoutesToMarkdownFile() {
        #expect(MarkdownTextEditorRoute(fileName: "notes.md", sizeInBytes: limit, isEnabled: true) == .markdownFile)
    }

    @Test func overLimitPlainTextRoutesToOtherFile() {
        #expect(MarkdownTextEditorRoute(fileName: "notes.txt", sizeInBytes: limit + 1, isEnabled: true) == .otherFile)
    }

    @Test func overLimitMarkdownWithGateOffRoutesToOtherFile() {
        #expect(MarkdownTextEditorRoute(fileName: "notes.md", sizeInBytes: limit + 1, isEnabled: false) == .otherFile)
    }
}
