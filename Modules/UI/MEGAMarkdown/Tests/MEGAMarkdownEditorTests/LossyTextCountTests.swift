@testable import MEGAMarkdownEditor
import Testing

/// Markdown cannot nest links, so a text with a link inside a link does not parse back to the same styles.
@Suite("Lossy text count")
struct LossyTextCountTests {
    private func lossyCount(_ text: RichText, previous: InlineExportCache = InlineExportCache()) -> Int {
        var exporter = MarkdownExporter(blocks: [.paragraph(text)], previous: previous)
        _ = exporter.markdown()
        return exporter.lossyTextCount
    }

    @Test func plainTextIsNotLossy() {
        #expect(lossyCount(rich("abc")) == 0)
    }

    @Test func stylesThatParseBackAreNotLossy() {
        #expect(lossyCount(rich("abc", (0..<3, .bold), (1..<2, .code))) == 0)
        #expect(lossyCount(rich("abcd", (0..<3, .code), (1..<4, .underline))) == 0)
        #expect(lossyCount(rich("abc", (0..<3, link("u")), (1..<2, .code))) == 0)
    }

    @Test func aLinkInsideALinkIsLossy() {
        #expect(lossyCount(rich("abc", (0..<3, link("u")), (1..<2, link("v")))) == 1)
    }

    @Test func twoOverlappingLinksAreLossy() {
        #expect(lossyCount(rich("abc", (0..<2, link("u")), (1..<3, link("v")))) == 1)
    }

    @Test func eachLossyTextCountsOnce() {
        var exporter = MarkdownExporter(blocks: [
            .paragraph(rich("abc", (0..<3, link("u")), (1..<2, link("v")))),
            .paragraph(rich("xyz", (0..<3, link("u")), (1..<2, link("v")))),
            .paragraph(rich("plain"))
        ])
        _ = exporter.markdown()
        #expect(exporter.lossyTextCount == 2)
    }

    @Test func aTextFromTheCacheIsNotCheckedAgain() {
        let text = rich("abc", (0..<3, link("u")), (1..<2, link("v")))
        var first = MarkdownExporter(blocks: [.paragraph(text)])
        _ = first.markdown()
        #expect(first.lossyTextCount == 1)
        #expect(lossyCount(text, previous: first.current) == 0)
    }
}
