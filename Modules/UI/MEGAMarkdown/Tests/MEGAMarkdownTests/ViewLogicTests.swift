@testable import MEGAMarkdown
import SwiftUI
import Testing

@Suite struct ViewLogicTests {
    // MARK: - splitForMeasuring

    @Test func shortTextStaysOnePiece() {
        let pieces = splitForMeasuring(AttributedString("hello"), maxLength: 10)
        #expect(pieces.map { String($0.characters) } == ["hello"])
    }

    @Test func emptyTextGivesOneEmptyPiece() throws {
        let pieces = splitForMeasuring(AttributedString(""), maxLength: 10)
        try #require(pieces.count == 1)
        #expect(pieces[0].characters.isEmpty)
    }

    @Test func textOfExactMaxLengthStaysOnePiece() {
        let source = String(repeating: "a", count: 10)
        let pieces = splitForMeasuring(AttributedString(source), maxLength: 10)
        #expect(pieces.map { String($0.characters) } == [source])
        // One character more must split, so the limit is not off by one.
        let longer = splitForMeasuring(AttributedString(source + "b"), maxLength: 10)
        #expect(longer.map { String($0.characters) } == [source, "b"])
    }

    @Test func longTextSplitsAndKeepsAllCharacters() {
        let source = String(repeating: "abcdefghij", count: 12_345)
        let pieces = splitForMeasuring(AttributedString(source))
        #expect(pieces.count == 3)
        #expect(pieces.dropLast().allSatisfy { $0.characters.count == maxTextMeasureCharacters })
        #expect(pieces.map { String($0.characters) }.joined() == source)
    }

    @Test func splitKeepsInlineStyles() throws {
        let text = try AttributedString(markdown: "aaaa**bbbb**")
        let pieces = splitForMeasuring(text, maxLength: 6)
        try #require(pieces.map { String($0.characters) } == ["aaaabb", "bb"])
        // The first piece keeps its plain part plain and its bold part bold.
        let firstRuns = pieces[0].runs.map { (String(pieces[0][$0.range].characters), $0.inlinePresentationIntent) }
        #expect(firstRuns.map(\.0) == ["aaaa", "bb"])
        #expect(firstRuns.map(\.1) == [nil, .stronglyEmphasized])
        #expect(pieces[1].runs.count == 1)
        #expect(pieces[1].runs.first?.inlinePresentationIntent == .stronglyEmphasized)
    }

    @Test func splitDoesNotBreakEmoji() {
        let source = String(repeating: "👨‍👩‍👧", count: 5)
        let pieces = splitForMeasuring(AttributedString(source), maxLength: 2)
        #expect(pieces.map { $0.characters.count } == [2, 2, 1])
        #expect(pieces.map { String($0.characters) }.joined() == source)
    }

    // MARK: - Inline styling

    @Test func linkRunGetsThemeColorAndUnderline() throws {
        var theme = MarkdownTheme.default
        theme.linkColor = .purple
        let styled = theme.styledInline(try AttributedString(markdown: "go [here](https://mega.io) now"), codeFont: theme.inlineCodeFont(scale: 1), codeBaselineOffset: 0)
        let linkRun = try #require(styled.runs.first { $0.link != nil })
        #expect(linkRun.foregroundColor == .purple)
        #expect(linkRun.underlineStyle == .single)
        #expect(String(styled[linkRun.range].characters) == "here")
        // Text around the link keeps the view colour and gets no underline.
        let plainRuns = styled.runs.filter { $0.link == nil }
        try #require(!plainRuns.isEmpty)
        #expect(plainRuns.allSatisfy { $0.foregroundColor == nil && $0.underlineStyle == nil })
    }

    @Test func inlineCodeRunGetsCodeFontAndBackground() throws {
        let theme = MarkdownTheme.default
        let styled = theme.styledInline(try AttributedString(markdown: "run `swift test` please"), codeFont: theme.inlineCodeFont(scale: 1), codeBaselineOffset: 0)
        let codeRun = try #require(styled.runs.first { $0.inlinePresentationIntent?.contains(.code) == true })
        #expect(String(styled[codeRun.range].characters) == "swift test")
        #expect(codeRun.font == .system(size: 14, design: .monospaced))
        #expect(codeRun.backgroundColor == theme.inlineCodeBackground)
        #expect(codeRun.foregroundColor == theme.inlineCodeColor)
        let plainRuns = styled.runs.filter { $0.inlinePresentationIntent?.contains(.code) != true }
        try #require(!plainRuns.isEmpty)
        #expect(plainRuns.allSatisfy { $0.font == nil && $0.backgroundColor == nil })
    }

    /// Long table cell text is cut and ends with "…". Text at the limit is kept as it is.
    @MainActor
    @Test func tableCellTextIsCutOnlyOverTheCap() {
        let limit = TableLimits.maxCellCharacters
        let atLimit = AttributedString(String(repeating: "a", count: limit))
        #expect(TableBlockView.capped(atLimit) == atLimit)
        let over = TableBlockView.capped(AttributedString(String(repeating: "a", count: limit) + "bcd"))
        #expect(String(over.characters) == String(repeating: "a", count: limit) + "…")
        #expect(TableBlockView.capped(AttributedString("")) == AttributedString(""))
    }

    // MARK: - Line mapping

    private func rows(lines: [Int]) -> [PreviewRow] {
        lines.map { PreviewRow(sourceLine: $0, content: .block(ParsedBlock(sourceLine: $0, kind: .thematicBreak))) }
    }

    @Test func rowIndexIsNilForEmptyDocument() {
        #expect(rowIndex(containing: 5, in: []) == nil)
    }

    @Test(arguments: [(0, 0), (3, 0), (4, 1), (9, 1), (10, 2), (500, 2)])
    func rowIndexPicksLastRowStartingAtOrBeforeLine(line: Int, expected: Int) {
        #expect(rowIndex(containing: line, in: rows(lines: [0, 4, 10])) == expected)
    }

    @Test func rowIndexBeforeFirstRowGoesToFirstRow() {
        #expect(rowIndex(containing: 1, in: rows(lines: [3, 8])) == 0)
    }

    @Test func rowIndexWithEqualLinesPicksTheLastOne() {
        #expect(rowIndex(containing: 4, in: rows(lines: [0, 4, 4, 9])) == 2)
    }
}

@MainActor
@Suite struct ParseCacheTests {
    @Test func sameRequestParsesOnce() {
        var parseCount = 0
        let cache = MarkdownParseCache { request in
            parseCount += 1
            return request.parse()
        }
        let first = cache.document(for: MarkdownParseRequest(markdown: "# Title"))
        let second = cache.document(for: MarkdownParseRequest(markdown: "# Title"))
        #expect(first == second)
        #expect(parseCount == 1)
    }

    /// "é" and "e" + U+0301 are equal Strings but different bytes. cmark matches the reference label by bytes,
    /// so only the first text has a link. The cache must parse the second text again.
    @Test func canonicallyEqualTextWithOtherBytesParsesAgain() {
        var parseCount = 0
        let cache = MarkdownParseCache { request in
            parseCount += 1
            return request.parse()
        }
        let composed = "[x][\u{E9}]\n\n[\u{E9}]: /destination"
        let decomposed = "[x][\u{E9}]\n\n[e\u{301}]: /destination"
        let hasLink = { (document: MarkdownDocument) in
            document.blocks.first?.paragraph?.runs.contains { $0.link != nil } ?? false
        }
        #expect(hasLink(cache.document(for: MarkdownParseRequest(markdown: composed))))
        #expect(!hasLink(cache.document(for: MarkdownParseRequest(markdown: decomposed))))
        #expect(parseCount == 2)
        #expect(MarkdownParseRequest(markdown: composed) != MarkdownParseRequest(markdown: decomposed))
    }

    @Test func changedTextParsesAgain() throws {
        var parseCount = 0
        let cache = MarkdownParseCache { request in
            parseCount += 1
            return request.parse()
        }
        _ = cache.document(for: MarkdownParseRequest(markdown: "# One"))
        let second = cache.document(for: MarkdownParseRequest(markdown: "# Two"))
        #expect(parseCount == 2)
        try #require(second.blocks.count == 1)
        guard case .heading(1, let text) = second.blocks[0].kind else {
            Issue.record("expected a level 1 heading")
            return
        }
        #expect(String(text.characters) == "Two")
    }

    /// Every field of the request counts. Same text with another base URL or soft break is a new parse.
    @Test func changedBaseURLOrSoftBreakParsesAgain() {
        var parseCount = 0
        let cache = MarkdownParseCache { request in
            parseCount += 1
            return request.parse()
        }
        let base = MarkdownParseRequest(markdown: "a\nb")
        _ = cache.document(for: base)
        var withURL = base
        withURL.baseURL = URL(string: "https://mega.io/docs/")
        _ = cache.document(for: withURL)
        #expect(parseCount == 2)
        var withSpace = withURL
        withSpace.softBreak = .space
        _ = cache.document(for: withSpace)
        #expect(parseCount == 3)
        _ = cache.document(for: withSpace)
        #expect(parseCount == 3)
    }

    @Test func softBreakOptionReachesTheParser() {
        let cache = MarkdownParseCache()
        let document = cache.document(for: MarkdownParseRequest(markdown: "a\nb", softBreak: .space))
        guard case .paragraph(let text) = document.blocks.first?.kind else {
            Issue.record("expected a paragraph")
            return
        }
        #expect(String(text.characters) == "a b")
        // Negative case: the default keeps the break, so the option is really used.
        let lineBreak = cache.document(for: MarkdownParseRequest(markdown: "a\nb"))
        guard case .paragraph(let kept) = lineBreak.blocks.first?.kind else {
            Issue.record("expected a paragraph")
            return
        }
        #expect(String(kept.characters) != "a b")
    }
}

@Suite struct TaskLabelTests {
    @Test func labelIsTheFirstParagraphText() {
        let text = AttributedString("Ship it")
        let item = MarkdownListItem(checkbox: .unchecked, blocks: [MarkdownBlock(id: 1, sourceLine: 0, kind: .paragraph(text))])
        #expect(item.taskLabel == "Ship it")
    }

    @Test func emptyItemHasEmptyLabel() {
        #expect(MarkdownListItem(checkbox: .checked, blocks: []).taskLabel.isEmpty)
    }
}
