@testable import MEGAMarkdownEditor
import Testing

@Suite("Inline markup writer")
struct InlineMarkupWriterTests {
    private func write(
        _ text: RichText,
        context: InlineWriter.Context = .paragraph,
        usesHTML: Bool = false
    ) -> String {
        InlineMarkupWriter(text: text, context: context, usesHTML: usesHTML).write()
    }

    // MARK: - Markers

    @Test func plainTextHasNoMarkers() {
        #expect(write(rich("abc")) == "abc")
    }

    @Test(arguments: [
        (RichSpanStyle.bold, "**a**b"), (.italic, "*a*b"), (.strikethrough, "~~a~~b"), (.underline, "<u>a</u>b"), (.code, "`a`b")
    ])
    func eachStyleHasItsMarkdownMarker(style: RichSpanStyle, expected: String) {
        #expect(write(rich("ab", (0..<1, style))) == expected)
    }

    @Test(arguments: [
        (RichSpanStyle.bold, "<strong>a</strong>b"), (.italic, "<em>a</em>b"), (.strikethrough, "<del>a</del>b"),
        (.underline, "<u>a</u>b"), (.code, "<code>a</code>b")
    ])
    func eachStyleHasItsHTMLTag(style: RichSpanStyle, expected: String) {
        #expect(write(rich("ab", (0..<1, style)), usesHTML: true) == expected)
    }

    @Test func anItalicOpenedRightAfterABoldCloserUsesUnderscores() {
        #expect(write(rich("ab", (0..<1, .italic), (1..<2, .bold))) == "*a*__b__")
    }

    @Test func theAsteriskStaysWhenAWordCharacterFollows() {
        #expect(write(rich("abc", (0..<1, .italic), (1..<2, .bold))) == "*a***b**c")
    }

    // MARK: - Code

    @Test func codeTextIsNotEscapedInMarkdown() {
        #expect(write(rich("a*b", (0..<3, .code))) == "`a*b`")
    }

    @Test func codeTextIsEscapedWhenWrittenAsHTML() {
        #expect(write(rich("a*b", (0..<3, .code)), usesHTML: true) == "<code>a\\*b</code>")
    }

    @Test func backticksInCodeGetALongerFence() {
        #expect(write(rich("a`b", (0..<3, .code))) == "``a`b``")
        #expect(write(rich("a``b", (0..<4, .code))) == "```a``b```")
    }

    @Test func codeThatStartsOrEndsWithABacktickIsPadded() {
        #expect(write(rich("`", (0..<1, .code))) == "`` ` ``")
    }

    @Test func codeWithASpaceAtBothEndsIsPadded() {
        #expect(write(rich(" a ", (0..<3, .code))) == "`  a  `")
    }

    @Test func codeOfOnlySpacesIsNotPadded() {
        #expect(write(rich("  ", (0..<2, .code))) == "`  `")
    }

    // MARK: - Links

    @Test func aLinkWritesTextAndDestination() {
        #expect(write(rich("ab", (0..<1, link("u")))) == "[a](u)b")
    }

    @Test func aLinkTitleIsQuoted() {
        #expect(write(rich("ab", (0..<1, link("u", title: "t")))) == "[a](u \"t\")b")
    }

    @Test func aLinkDestinationWithASpaceGetsBrackets() {
        #expect(write(rich("a", (0..<1, link("a b")))) == "[a](<a b>)")
    }

    @Test func aLinkWhoseTextIsItsURLIsAnAutolink() {
        #expect(write(rich("https://mega.nz", (0..<15, link("https://mega.nz")))) == "<https://mega.nz>")
    }

    @Test func aLinkWithInnerStyleIsNotAnAutolink() {
        let text = rich("https://mega.nz", (0..<15, link("https://mega.nz")), (0..<5, .bold))
        #expect(!write(text).hasPrefix("<https"))
    }

    @Test func aStyleThatCrossesALinkEdgeIsCutThere() {
        #expect(write(rich("abc", (0..<2, .bold), (1..<3, link("u")))) == "**a**[**b**c](u)")
    }

    // MARK: - Breaks

    @Test func aSoftBreakIsALineFeed() {
        #expect(write(rich("a\nb")) == "a\nb")
    }

    @Test func aHardBreakIsABackslashAndALineFeed() {
        #expect(write(rich("a\u{2028}b")) == "a\\\nb")
    }

    @Test func continuationLinesGetTheContextPrefix() {
        #expect(write(rich("a\nb"), context: .listItem(continuationIndent: 2)) == "a\n  b")
        #expect(write(rich("a\nb"), context: .quote(prefix: "> ")) == "a\n> b")
    }

    @Test func aLineStartAfterABreakIsEscaped() {
        #expect(write(rich("a\n- b")) == "a\n\\- b")
    }

    @Test func codeCloseBeforeABreakAndOpensAgain() {
        #expect(write(rich("a\nb", (0..<3, .code))) == "`a`\n`b`")
    }

    @Test func aHashIsEscapedInAnATXHeadingOnly() {
        #expect(write(rich("a #"), context: .atxHeading) == "a \\#")
        #expect(write(rich("a #")) == "a #")
    }
}
