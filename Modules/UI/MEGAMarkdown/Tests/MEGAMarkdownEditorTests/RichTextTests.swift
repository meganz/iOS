@testable import MEGAMarkdownEditor
import Testing

@Suite("Rich text")
struct RichTextTests {
    @Test func spansAreNormalizedOnInit() {
        let text = RichText("abcdef", spans: [
            RichSpan(range: 3..<5, style: .bold),
            RichSpan(range: 0..<3, style: .bold),
            RichSpan(range: 4..<9, style: .italic),
            RichSpan(range: 2..<2, style: .code)
        ])
        #expect(text.spans == [RichSpan(range: 0..<5, style: .bold), RichSpan(range: 4..<6, style: .italic)])
    }

    @Test func textComparesByBytes() {
        // "é" and "e" + U+0301 are equal Strings, but their UTF-16 lengths differ.
        #expect(RichText("\u{E9}") != RichText("e\u{301}"))
        #expect(RichText("\u{E9}").hashValue == RichText("\u{E9}").hashValue)
    }

    @Test func sliceClipsAndShiftsSpans() {
        let text = rich("hello world", (0..<5, .bold), (6..<11, .italic))
        #expect(text.slice(3..<8) == rich("lo wo", (0..<2, .bold), (3..<5, .italic)))
    }

    @Test func joinShiftsTheRightSpans() {
        #expect(rich("ab", (0..<2, .bold)) + rich("cd", (0..<1, .bold)) == rich("abcd", (0..<3, .bold)))
    }

    @Test func offsetInsideASurrogatePairMovesToItsStart() {
        let text = RichText("a😀b")
        #expect(text.slice(0..<2).text == "a")
        #expect(text.replacing(2..<2, with: "x").text == "ax😀b")
    }

    @Test func sliceKeepsACombiningMarkWithItsOffset() {
        // A String subscript would move offset 1 to the Character boundary before "e".
        let text = RichText("e\u{301}x")
        #expect(text.slice(1..<3).text == "\u{301}x")
    }

    @Test func replacingMovesSpansAfterTheEdit() {
        let text = rich("abc def", (4..<7, .bold))
        #expect(text.replacing(0..<1, with: "XYZ") == rich("XYZbc def", (6..<9, .bold)))
    }
}

@Suite("Span editing")
struct SpanEditingTests {
    @Test func insertAtSpanStartDoesNotJoinIt() {
        let text = rich("bold", (0..<4, .bold))
        #expect(text.replacing(0..<0, with: "x", typingStyles: []) == rich("xbold", (1..<5, .bold)))
    }

    @Test func insertAtSpanEndTakesTheTypingStyles() {
        let text = rich("bold", (0..<4, .bold))
        #expect(text.replacing(4..<4, with: "er", typingStyles: [.bold]) == rich("bolder", (0..<6, .bold)))
        #expect(text.replacing(4..<4, with: "er", typingStyles: []) == rich("bolder", (0..<4, .bold)))
    }

    @Test func typingStylesAreExactInsideASpan() {
        // Bold turned off at the caret inside a bold word: the new letter is plain.
        let text = rich("bold", (0..<4, .bold))
        #expect(text.replacing(2..<2, with: "x", typingStyles: []) == rich("boxld", (0..<2, .bold), (3..<5, .bold)))
    }

    @Test func withoutTypingStylesAnInsertInsideASpanJoinsIt() {
        let text = rich("bold", (0..<4, .bold))
        #expect(text.replacing(2..<2, with: "x") == rich("boxld", (0..<5, .bold)))
    }

    @Test func deleteAcrossSpanEdgesKeepsTheRest() {
        let text = rich("aaBBcc", (2..<4, .bold))
        #expect(text.replacing(1..<3, with: "") == rich("aBcc", (1..<2, .bold)))
        #expect(text.replacing(2..<4, with: "") == RichText("aacc"))
    }

    @Test func toggleAddsThenRemoves() {
        let text = RichText("hello")
        let bold = text.togglingStyle(.bold, in: 1..<4)
        #expect(bold == rich("hello", (1..<4, .bold)))
        #expect(bold.togglingStyle(.bold, in: 1..<4) == text)
        // Part of the range is not bold yet: the whole range becomes bold.
        #expect(bold.togglingStyle(.bold, in: 0..<5) == rich("hello", (0..<5, .bold)))
    }

    @Test func aLinkReplacesOtherLinksInItsRange() {
        let text = rich("abcdef", (0..<6, link("a")))
        #expect(text.addingStyle(link("b"), in: 2..<4) == rich("abcdef", (0..<2, link("a")), (2..<4, link("b")), (4..<6, link("a"))))
    }

    @Test func caretStylesComeFromTheCharacterBefore() {
        let text = rich("ab cd", (0..<2, .bold), (3..<5, link("u")))
        #expect(text.styles(in: 2..<2) == [.bold])
        #expect(text.styles(in: 0..<0) == [.bold])
        #expect(text.styles(in: 3..<3) == [])
        #expect(text.styles(in: 4..<4) == [link("u")])
        // A link does not continue past its end.
        #expect(text.styles(in: 5..<5) == [])
    }

    @Test func rangeStylesAreTheStylesOnEveryCharacter() {
        let text = rich("abcd", (0..<4, .bold), (1..<2, .italic))
        #expect(text.styles(in: 0..<4) == [.bold])
        #expect(text.styles(in: 1..<2) == [.bold, .italic])
    }
}
