@testable import MEGATextEditor
import Testing

struct MarkdownTextEditorSizeCheckTests {
    private let limit: UInt64 = 100 * 1024 * 1024

    @Test func emptyFileIsPreviewable() {
        #expect(MarkdownTextEditorSizeCheck(sizeInBytes: 0) == .previewable)
    }

    @Test func fileAtLimitIsPreviewable() {
        #expect(MarkdownTextEditorSizeCheck(sizeInBytes: limit) == .previewable)
    }

    @Test func fileOverLimitIsTooLarge() {
        #expect(MarkdownTextEditorSizeCheck(sizeInBytes: limit + 1) == .tooLarge)
    }

    @Test func sizeOver4GiBIsTooLarge() {
        let fourGiBAndOneByte = UInt64(4) * 1024 * 1024 * 1024 + 1
        #expect(MarkdownTextEditorSizeCheck(sizeInBytes: fourGiBAndOneByte) == .tooLarge)
    }
}
