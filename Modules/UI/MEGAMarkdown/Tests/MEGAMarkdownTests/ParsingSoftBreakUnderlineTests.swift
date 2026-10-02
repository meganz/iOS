import Foundation
@testable import MEGAMarkdown
import SwiftUI
import Testing

@Suite struct ParsingSoftBreakTests {
    private func firstParagraph(_ blocks: [MarkdownBlock]) -> String? {
        flatten(blocks).compactMap(\.paragraphText).first
    }

    @Test func defaultKeepsSoftBreakAsLineBreak() {
        // Quirk: Foundation emits a soft break as its own " " run with inline intent `softBreak`.
        // Android preview now shows it as a line break, so that is our default.
        #expect(firstParagraph(parse("line one\nline two")) == "line one\nline two")
    }

    @Test func spaceModeJoinsLines() {
        let blocks = MarkdownParser.parse("line one\nline two", softBreak: .space).blocks
        #expect(firstParagraph(blocks) == "line one line two")
    }

    @Test func hardWrappedParagraphKeepsEveryLineAndEverySpace() {
        let markdown = "The quick brown fox\njumps over the\nlazy dog."
        #expect(firstParagraph(parse(markdown)) == "The quick brown fox\njumps over the\nlazy dog.")
        let spaced = MarkdownParser.parse(markdown, softBreak: .space).blocks
        #expect(firstParagraph(spaced) == "The quick brown fox jumps over the lazy dog.")
    }

    @Test func softBreakInsideListItem() throws {
        let list = try #require(parse("- first line\n  second line\n- next").first?.list)
        #expect(list.items[0].blocks.first?.paragraphText == "first line\nsecond line")
        #expect(list.items[1].blocks.first?.paragraphText == "next")
    }

    @Test func softBreakInsideQuote() throws {
        let quote = try #require(parse("> quoted one\n> quoted two").first?.quote)
        #expect(quote.first?.paragraphText == "quoted one\nquoted two")
    }

    @Test func softBreakInsideStyledText() {
        // A soft break inside bold keeps the bold style on both lines.
        let blocks = parse("**bold one\nbold two**")
        guard case .paragraph(let text) = blocks.first?.kind else {
            Issue.record("not a paragraph")
            return
        }
        #expect(text.plain == "bold one\nbold two")
        #expect(text.runs.allSatisfy { $0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true })
    }

    @Test(arguments: [MarkdownSoftBreak.lineBreak, .space])
    func hardBreakIsNewlineInBothModes(mode: MarkdownSoftBreak) {
        let blocks = MarkdownParser.parse("two spaces  \nbackslash\\\nend", softBreak: mode).blocks
        #expect(firstParagraph(blocks) == "two spaces\nbackslash\nend")
    }

    @Test func codeBlockIsNotChanged() throws {
        let code = try #require(parse("```\na b\nc d\n```").first?.code)
        #expect(code.code == "a b\nc d")
    }

    // MARK: - Break markers

    private func breakRuns(_ markdown: String, _ mode: MarkdownSoftBreak) -> [(String, InlinePresentationIntent)] {
        guard case .paragraph(let text) = MarkdownParser.parse(markdown, softBreak: mode).blocks.first?.kind else { return [] }
        return text.runs.compactMap { run in
            guard let intent = run.inlinePresentationIntent,
                  intent.contains(.softBreak) || intent.contains(.lineBreak) else { return nil }
            return (String(text[run.range].characters), intent)
        }
    }

    @Test func softAndHardBreaksKeepDifferentMarkers() {
        let runs = breakRuns("soft\nhard  \nend", .lineBreak)
        #expect(runs.count == 2)
        #expect(runs[0].0 == "\n")
        #expect(runs[0].1.contains(.softBreak))
        #expect(!runs[0].1.contains(.lineBreak))
        #expect(runs[1].0 == "\n")
        #expect(runs[1].1.contains(.lineBreak))
        #expect(!runs[1].1.contains(.softBreak))
    }

    @Test func spaceModeSoftBreakKeepsMarker() {
        let runs = breakRuns("soft\nhard\\\nend", .space)
        #expect(runs.map(\.0) == [" ", "\n"])
        #expect(runs[0].1.contains(.softBreak))
        #expect(runs[1].1.contains(.lineBreak))
    }

    @Test func softBreakInsideBoldKeepsBothIntents() {
        let runs = breakRuns("**a\nb**", .lineBreak)
        #expect(runs.count == 1)
        #expect(runs[0].1.contains(.softBreak))
        #expect(runs[0].1.contains(.stronglyEmphasized))
    }
}

@Suite struct ParsingUnderlineTests {
    private func paragraph(_ markdown: String) throws -> AttributedString {
        guard case .paragraph(let text) = try #require(parse(markdown).first).kind else {
            Issue.record("not a paragraph")
            return AttributedString()
        }
        return text
    }

    private func isUnderlined(_ word: String, in text: AttributedString) -> Bool {
        guard let range = text.range(of: word) else { return false }
        return text[range].runs.allSatisfy {
            $0[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] == .single
        }
    }

    @Test func balancedTagsBecomeUnderline() throws {
        let text = try paragraph("before <u>under</u> after")
        #expect(text.plain == "before under after")
        #expect(isUnderlined("under", in: text))
        #expect(!isUnderlined("before", in: text))
        #expect(!isUnderlined("after", in: text))
    }

    @Test func underlineKeepsOtherStyles() throws {
        let text = try paragraph("<u>**bold** plain</u>")
        #expect(text.plain == "bold plain")
        #expect(isUnderlined("bold", in: text))
        #expect(isUnderlined("plain", in: text))
        let bold = try #require(text.range(of: "bold"))
        #expect(text[bold].runs.first?.inlinePresentationIntent == .stronglyEmphasized)
    }

    @Test func upperCaseTagsWork() throws {
        let text = try paragraph("<U>x</U>")
        #expect(text.plain == "x")
        #expect(isUnderlined("x", in: text))
    }

    @Test func nestedTagsAllRemoved() throws {
        let text = try paragraph("<u>a <u>b</u> c</u>")
        #expect(text.plain == "a b c")
        #expect(isUnderlined("a b c", in: text))
    }

    @Test(arguments: ["only <u>open", "only close</u>", "</u>wrong order<u>"])
    func unbalancedTagsStayLiteral(markdown: String) throws {
        let text = try paragraph(markdown)
        #expect(text.plain == markdown)
        #expect(text.runs.allSatisfy { $0[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] == nil })
    }

    @Test func extraOpenTagStaysLiteral() throws {
        let text = try paragraph("<u>a <u>b</u>")
        #expect(text.plain == "<u>a b")
        #expect(isUnderlined("b", in: text))
        #expect(!isUnderlined("a", in: text))
    }

    @Test func otherInlineHTMLStaysLiteral() throws {
        #expect(try paragraph("a <span>x</span>").plain == "a <span>x</span>")
    }

    @Test func underlineInListItemAndTableCell() throws {
        let list = try #require(parse("- <u>item</u>").first?.list)
        #expect(list.items[0].blocks.first?.paragraphText == "item")
        let table = try #require(parse("| <u>h</u> |\n|---|\n| c |").first?.table)
        #expect(table.header[0].plain == "h")
        #expect(table.header[0].runs.first?[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] == .single)
    }

    @Test func htmlBlockStaysRawParagraph() {
        // Coordinator decision: HTML blocks are kept as raw text, not dropped, and not rewritten.
        // A tag alone on its line starts an HTML block (CommonMark type 7). Inline `<u>` with text
        // on the same line is a paragraph instead, and becomes underline.
        let blocks = parse("<u>\nraw block\n</u>\n\ntext")
        #expect(blocks.first?.paragraphText == "<u>\nraw block\n</u>\n")
        #expect(blocks.last?.paragraphText == "text")
    }
}
