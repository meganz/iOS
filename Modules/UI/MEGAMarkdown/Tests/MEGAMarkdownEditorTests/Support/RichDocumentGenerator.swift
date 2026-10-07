import Foundation
@testable import MEGAMarkdownEditor

/// Random documents inside what Markdown can hold exactly, so export then import must give them back.
///
/// Left out on purpose, because the exporter drops them by design: empty paragraphs and quote rows,
/// spaces at line edges, empty lines inside a text, breaks in level 3-6 headings, emphasis that starts
/// or ends on whitespace, and a start number of 1.
struct RichDocumentGenerator {
    var random: SeededGenerator

    init(seed: UInt64) {
        random = SeededGenerator(seed: seed)
    }

    /// Words with the characters Markdown syntax uses, plus non-ASCII text.
    private static let words = [
        "plain", "a", "word", "x*y", "_under_", "**", "`tick`", "``", "[box]", "[x]", "<tag>", "</u>", "#", "##", "1.", "2)",
        "-", "+", "*", ">", "=", "===", "---", "***", "~~", "~", "|", "a|b", "!", "![", "&amp;", "&copy;", "&#35;", "\\", "\\*",
        "https://mega.nz", "www.mega.nz", "é", "e\u{301}", "😀", "👍🏽", "中文", "\u{00A0}nbsp", "tab\tin", "(", ")", "\"q\"",
        "':'", "50%", "9.", "10)", "<https://x>", "[a](b)", "<!-- c -->", ":::", "$math$", "@user", "end.",
        // A syntax character with a combining mark is one Character, but cmark still reads the syntax byte.
        ">\u{301}", "*\u{301}x*", "`\u{301}", "#\u{301}", "-\u{301}", "[\u{301}]"
    ]

    private static let destinations = [
        "https://mega.nz", "https://mega.nz/a?b=1&c=2", "/relative/path", "with space", "paren(x)", "a\\b", "&amp;",
        "mailto:a@b.co", "üñí", "", "<angle>", "#anchor", "x)", "x(", "a\"b"
    ]

    private static let titles = ["", "", "", "title", "with \"quotes\"", "&copy;", "a\\b", "(paren)"]

    private static let languages: [String?] = [nil, nil, "swift", "a b", "c`d", "~~~", "x\\y"]

    private mutating func pick<T>(_ values: [T]) -> T {
        values[Int.random(in: 0..<values.count, using: &random)]
    }

    private mutating func chance(_ percent: Int) -> Bool {
        Int.random(in: 0..<100, using: &random) < percent
    }

    mutating func document(blockCount: Int) -> [RichBlock] {
        var blocks: [RichBlock] = []
        for _ in 0..<blockCount {
            blocks.append(block(after: blocks.last))
        }
        return blocks
    }

    private mutating func block(after previous: RichBlock?) -> RichBlock {
        switch Int.random(in: 0..<100, using: &random) {
        case 0..<25:
            return .paragraph(text(allowsBreaks: true, allowsEmpty: false))
        case 25..<35:
            let level = Int.random(in: 1...6, using: &random)
            return .heading(level: level, text: text(allowsBreaks: level <= 2 && chance(30), allowsEmpty: true))
        case 35..<65:
            let maxIndent = previous?.listItem.map { $0.indent + 1 } ?? 0
            let indent = Int.random(in: 0...min(maxIndent, 3), using: &random)
            let isOrdered = chance(40)
            let start: Int? = isOrdered && chance(20) ? pick([0, 2, 7, 42, 999]) : nil
            let checked: Bool? = chance(25) ? chance(50) : nil
            let item = RichListItem(isOrdered: isOrdered, indent: indent, isChecked: checked, startNumber: start)
            return .listItem(item, text: text(allowsBreaks: true, allowsEmpty: true))
        case 65..<77:
            var depth = Int.random(in: 1...3, using: &random)
            if case .quote(let previousDepth, _)? = previous { depth = min(depth, previousDepth + 1) }
            return .quote(depth: depth, text: text(allowsBreaks: true, allowsEmpty: false))
        case 77..<87:
            return .codeBlock(language: pick(Self.languages), code: code())
        case 87..<92:
            return .thematicBreak
        default:
            // An empty paragraph: between two lists it starts a new list.
            return .paragraph(RichText())
        }
    }

    private mutating func code() -> String {
        let lineCount = Int.random(in: 0...4, using: &random)
        let lines = (0..<lineCount).map { _ in
            chance(20) ? "" : (0..<Int.random(in: 1...4, using: &random)).map { _ in pick(Self.words + ["```", "~~~~", "    indented"]) }.joined(separator: " ")
        }
        return lines.joined(separator: "\n")
    }

    /// Lines of words joined by single spaces. A line break is a soft break or a hard break (U+2028).
    private mutating func text(allowsBreaks: Bool, allowsEmpty: Bool) -> RichText {
        if allowsEmpty && chance(10) { return RichText() }
        let lineCount = allowsBreaks && chance(30) ? Int.random(in: 2...3, using: &random) : 1
        var string = ""
        for line in 0..<lineCount {
            if line > 0 { string += chance(50) ? "\n" : "\u{2028}" }
            string += (0..<Int.random(in: 1...5, using: &random)).map { _ in pick(Self.words) }.joined(separator: " ")
        }
        // Words with a tab or NBSP at a line edge would lose it: trim each line.
        string = string.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.split(separator: "\u{2028}", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \t")) }.joined(separator: "\u{2028}") }
            .joined(separator: "\n")
        var text = RichText(string)
        for _ in 0..<Int.random(in: 0...3, using: &random) {
            guard let span = span(in: text) else { continue }
            text = text.addingStyle(span.style, in: span.range)
        }
        return text
    }

    private mutating func span(in text: RichText) -> RichSpan? {
        let units = Array(text.text.utf16)
        guard units.count > 1 else { return nil }
        // Ranges on Character boundaries: the editor never cuts a Character.
        let boundaries = characterBoundaries(text.text)
        guard boundaries.count > 1 else { return nil }
        let lowerIndex = Int.random(in: 0..<(boundaries.count - 1), using: &random)
        let upperIndex = Int.random(in: (lowerIndex + 1)..<boundaries.count, using: &random)
        let range = boundaries[lowerIndex]..<boundaries[upperIndex]
        let style: RichSpanStyle = switch Int.random(in: 0..<6, using: &random) {
        case 0: .bold
        case 1: .italic
        case 2: .strikethrough
        case 3: .underline
        case 4: .code
        default: .link(RichLink(destination: pick(Self.destinations), title: pick(Self.titles)))
        }
        let piece = units[range]
        let isBreak: (UInt16) -> Bool = { $0 == 10 || $0 == 0x2028 }
        let isSpace: (UInt16) -> Bool = { $0 == 32 || $0 == 9 || $0 == 0xA0 || isBreak($0) }
        switch style {
        case .bold, .italic, .strikethrough:
            guard let first = piece.first, let last = piece.last, !isSpace(first), !isSpace(last) else { return nil }
        case .code:
            // A code span cannot hold a line end.
            guard !piece.contains(where: isBreak) else { return nil }
        default:
            break
        }
        return RichSpan(range: range, style: style)
    }

    private func characterBoundaries(_ string: String) -> [Int] {
        var result = [0]
        var offset = 0
        for character in string {
            offset += character.utf16.count
            result.append(offset)
        }
        return result
    }
}
