import Foundation
@testable import MEGATextEditor
import Testing

struct MarkdownTextEditorTextTests {
    @Test func validUTF8DecodesToText() {
        let data = Data("# Title\nCafé 日本語".utf8)
        #expect(MarkdownTextEditorText.decode(data) == "# Title\nCafé 日本語")
    }

    @Test func invalidUTF8DecodesToNil() {
        // 0xFF can never appear in UTF-8.
        let data = Data([0x61, 0xFF, 0x62])
        #expect(MarkdownTextEditorText.decode(data) == nil)
    }

    @Test func emptyDataDecodesToEmptyText() {
        #expect(MarkdownTextEditorText.decode(Data()) == "")
    }
}
