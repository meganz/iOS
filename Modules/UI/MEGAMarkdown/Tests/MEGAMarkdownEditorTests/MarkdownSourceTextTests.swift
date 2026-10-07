@testable import MEGAMarkdownEditor
import Testing

@Suite("Markdown source text")
struct MarkdownSourceTextTests {
    @Test func plainTextKeepsItsLinesAndDropsTheLastLineEnd() {
        let source = MarkdownSourceText("a\nb\n")
        #expect(source.body == "a\nb")
        #expect(source.format == RichFileFormat(lineEnding: .lf, hasByteOrderMark: false, endsWithLineEnding: true))
    }

    @Test func aTextWithoutALastLineEndIsMarked() {
        let source = MarkdownSourceText("a")
        #expect(source.body == "a")
        #expect(!source.format.endsWithLineEnding)
    }

    @Test func emptyTextHasAnEmptyBody() {
        let source = MarkdownSourceText("")
        #expect(source.body.isEmpty)
        #expect(!source.format.endsWithLineEnding)
    }

    @Test func crlfBecomesLineFeedInTheBody() {
        let source = MarkdownSourceText("a\r\nb\r\n")
        #expect(source.body == "a\nb")
        #expect(source.format.lineEnding == .crlf)
        #expect(source.format.endsWithLineEnding)
    }

    @Test func carriageReturnBecomesLineFeedInTheBody() {
        let source = MarkdownSourceText("a\rb")
        #expect(source.body == "a\nb")
        #expect(source.format.lineEnding == .cr)
        #expect(!source.format.endsWithLineEnding)
    }

    @Test func theFirstLineEndSetsTheLineEnding() {
        let source = MarkdownSourceText("a\r\nb\nc")
        #expect(source.format.lineEnding == .crlf)
        #expect(source.body == "a\nb\nc")
    }

    @Test func theByteOrderMarkIsRemovedAndRemembered() {
        let source = MarkdownSourceText("\u{FEFF}a\n")
        #expect(source.body == "a")
        #expect(source.format.hasByteOrderMark)
    }

    @Test func aByteOrderMarkInsideTheTextStays() {
        let source = MarkdownSourceText("a\u{FEFF}b")
        #expect(source.body == "a\u{FEFF}b")
        #expect(!source.format.hasByteOrderMark)
    }

    @Test(arguments: ["a", "a\n", "a\nb\n", "a\n\nb", "a\r\nb\r\n", "a\rb\r", "\u{FEFF}a\n", "\u{FEFF}a\r\nb", "\n\na\n\n"])
    func fileGivesBackTheOriginalText(original: String) {
        let source = MarkdownSourceText(original)
        #expect(MarkdownSourceText.file(body: source.body, format: source.format) == original)
    }

    @Test func fileWritesTheFormatAroundANewBody() {
        let format = RichFileFormat(lineEnding: .crlf, hasByteOrderMark: true, endsWithLineEnding: true)
        #expect(MarkdownSourceText.file(body: "x\ny", format: format) == "\u{FEFF}x\r\ny\r\n")
    }

    @Test func fileDoesNotAddALineEndToAnEmptyBody() {
        let format = RichFileFormat(lineEnding: .lf, hasByteOrderMark: false, endsWithLineEnding: true)
        #expect(MarkdownSourceText.file(body: "", format: format).isEmpty)
    }

    @Test func fileMakesMixedLineEndingsUniform() {
        let source = MarkdownSourceText("a\r\nb\nc")
        #expect(MarkdownSourceText.file(body: source.body, format: source.format) == "a\r\nb\r\nc")
    }

    @Test(arguments: ["\n", "\n\n", "\r\n"])
    func aFileOfOnlyLineEndsSavesAsAnEmptyFile(original: String) {
        #expect(RichMarkdownConverter.load(original).exported.isEmpty)
    }
}
