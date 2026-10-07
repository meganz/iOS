@testable import MEGAMarkdownEditor
import Testing

@Suite("Inline text cleaner")
struct InlineTextCleanerTests {
    private func cleaned(_ text: RichText, joinsLines: Bool = false) -> RichText {
        InlineTextCleaner.cleaned(text, joinsLines: joinsLines)
    }

    @Test func cleanTextIsReturnedUnchanged() {
        let text = rich("a b\nc", (0..<1, .bold))
        #expect(cleaned(text) == text)
    }

    @Test func spacesAndTabsAtLineEdgesAreRemoved() {
        #expect(cleaned(rich("  a \t\n\t b  ")) == rich("a\nb"))
    }

    @Test func breaksAtTheTextEdgesAreRemoved() {
        #expect(cleaned(rich("\n\na\n\n")) == rich("a"))
    }

    @Test func emptyLinesCollapseToOneBreak() {
        #expect(cleaned(rich("a\n\n \nb")) == rich("a\nb"))
    }

    @Test func aTextOfOnlyWhitespaceBecomesEmpty() {
        #expect(cleaned(rich(" \n\t ")) == rich(""))
    }

    @Test func aHardBreakIsKept() {
        #expect(cleaned(rich("a\u{2028}b")) == rich("a\u{2028}b"))
    }

    @Test func joiningLinesTurnsTheBreakIntoASpace() {
        #expect(cleaned(rich("a\n\nb"), joinsLines: true) == rich("a b"))
    }

    @Test func spansMoveWithTheKeptText() {
        #expect(cleaned(rich("  ab", (2..<4, .bold))) == rich("ab", (0..<2, .bold)))
    }

    @Test func emphasisShrinksToItsVisibleText() {
        #expect(cleaned(rich(" a ", (0..<3, .italic))) == rich("a", (0..<1, .italic)))
        #expect(cleaned(rich("a  b", (1..<3, .bold))) == rich("a  b"))
    }

    @Test func spaceInsideACodeSpanAtTheLineEdgeIsKept() {
        let text = rich(" a", (0..<2, .code))
        #expect(cleaned(text) == text)
    }

    @Test func codeIsCutAtABreak() {
        #expect(cleaned(rich("a\nb", (0..<3, .code))) == rich("a\nb", (0..<1, .code), (2..<3, .code)))
    }
}
