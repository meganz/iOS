@testable import MEGAMarkdownEditor
import Testing

@Suite("Markdown text escaper")
struct MarkdownTextEscaperTests {
    private func escaped(_ text: String, atLineStart: Bool = true, heading: Bool = false) -> String {
        var start = atLineStart
        return MarkdownTextEscaper.escape(text, atLineStart: &start, isATXHeading: heading)
    }

    @Test func plainTextStaysTheSame() {
        #expect(escaped("hello world") == "hello world")
    }

    @Test(arguments: [("a*b", "a\\*b"), ("a_b", "a\\_b"), ("a`b", "a\\`b"), ("[x]", "\\[x\\]"),
                      ("a<b", "a\\<b"), ("a|b", "a\\|b"), ("a~b", "a\\~b"), ("a\\b", "a\\\\b")])
    func inlineSyntaxIsEscaped(input: String, expected: String) {
        #expect(escaped(input, atLineStart: false) == expected)
    }

    @Test(arguments: [("# x", "\\# x"), ("> x", "\\> x"), ("- x", "\\- x"), ("+ x", "\\+ x"), ("= x", "\\= x")])
    func lineStartSyntaxIsEscapedAtLineStart(input: String, expected: String) {
        #expect(escaped(input) == expected)
    }

    @Test func lineStartSyntaxIsKeptInsideALine() {
        #expect(escaped("- x", atLineStart: false) == "- x")
    }

    @Test func atLineStartIsFalseAfterTheCall() {
        var start = true
        _ = MarkdownTextEscaper.escape("x", atLineStart: &start, isATXHeading: false)
        #expect(!start)
    }

    @Test(arguments: [("1. x", "1\\. x"), ("12) x", "12\\) x")])
    func orderedListMarkerIsEscaped(input: String, expected: String) {
        #expect(escaped(input) == expected)
    }

    @Test func hashInsideAnATXHeadingIsEscaped() {
        #expect(escaped("a #", atLineStart: false, heading: true) == "a \\#")
        #expect(escaped("a #", atLineStart: false, heading: false) == "a #")
    }

    @Test func ampersandBeforeAnEntityStartIsEscaped() {
        #expect(escaped("&amp;", atLineStart: false) == "\\&amp;")
        #expect(escaped("&#9;", atLineStart: false) == "\\&#9;")
        #expect(escaped("a & b", atLineStart: false) == "a & b")
    }

    @Test func trailingBangIsEscapedSoItCannotStartAnImage() {
        #expect(escaped("hi!", atLineStart: false) == "hi\\!")
        #expect(escaped("hi!x", atLineStart: false) == "hi!x")
    }

    @Test func schemeAndWwwAreEscapedSoTheyStayPlainText() {
        #expect(escaped("https://x", atLineStart: false) == "https\\://x")
        #expect(escaped("www.x", atLineStart: false) == "www\\.x")
    }

    @Test func escapedTextParsesBackAsTheSameText() {
        for text in ["a*b*", "# not a heading", "1. not a list", "[x](y)", "&amp; ok", "a_b_c"] {
            let blocks = loadedBlocks(escaped(text))
            #expect(blocks == [paragraph(text)], "\(text)")
        }
    }
}
