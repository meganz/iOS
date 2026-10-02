import Foundation
@testable import MEGAMarkdown
import SwiftUI
import Testing

/// Every cmark spec example through Foundation's `AttributedString(markdown:)` and through `MarkdownParser`.
/// Foundation is not a source of truth (see DECISIONS.md, "Source of truth"), and its output changes with the OS.
/// This suite only shows where the parser differs from the old viewer. It runs with `MARKDOWN_FOUNDATION_PARITY=1`.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["MARKDOWN_FOUNDATION_PARITY"] == "1"))
struct SpecCorpusParityTests {
    /// "file number" of each example where the two parsers differ on purpose, with the reason.
    static let knownDifferences: [String: String] = [
        // Foundation closes nested emphasis too early. cmark gives the spec's HTML.
        "spec 378": "nested emphasis", "spec 382": "nested emphasis", "spec 398": "nested emphasis",
        "spec 416": "nested emphasis", "spec 417": "nested emphasis", "spec 427": "nested emphasis",
        "spec 434": "nested emphasis", "spec 435": "nested emphasis", "spec 441": "nested emphasis",
        "spec 442": "nested emphasis", "regression 5": "nested emphasis",
        // Foundation drops emphasis and code inside link text. cmark keeps them, like the spec's HTML.
        "spec 524": "styles inside link text", "spec 538": "styles inside link text",
        "spec 562": "styles inside link text", "spec 566": "styles inside link text", "spec 567": "styles inside link text",
        // Foundation gives an image with no alt text U+FFFC as alt text. Tested in ParserDifferenceTests.
        "spec 589": "empty alt text",
        // Foundation gives no source line (-1 or 0) to some paragraphs. cmark gives the real line.
        "spec 631": "source line of an autolink paragraph",
        "extensions 16": "source line of a paragraph cut by a table",
        "extensions 19": "source line of an autolink paragraph",
        // Foundation drops a URL `URL(string:)` rejects and double-encodes `%20` next to `ä`. The parser encodes once, like the spec's HTML.
        "spec 508": "link URL encoded once", "spec 511": "link URL encoded once",
        // Footnotes are off, so cmark parses the label as inlines and marks `<script>` as inline HTML.
        "extensions 25": "inline HTML inside a footnote label"
    ]

    static func key(_ example: SpecCorpus.Example) -> String { "\(example.file) \(example.number)" }

    /// Both soft break modes and a base URL, like the old fixture parity test.
    static func firstDifference(_ markdown: String) -> String? {
        for softBreak in [MarkdownSoftBreak.lineBreak, .space] {
            for baseURL in [nil, URL(string: "https://mega.io/docs/")] {
                let expected = FoundationReferenceParser.parse(markdown, baseURL: baseURL, softBreak: softBreak)
                let actual = MarkdownParser.parse(markdown, baseURL: baseURL, softBreak: softBreak)
                if let difference = firstBlockDifference(expected.blocks, actual.blocks) {
                    return "softBreak=\(softBreak) base=\(baseURL?.absoluteString ?? "nil") \(difference)"
                }
            }
        }
        return nil
    }

    @Test func knownDifferencesNameRealExamples() {
        let keys = Set(SpecCorpus.examples.map(Self.key))
        #expect(Set(Self.knownDifferences.keys).isSubset(of: keys))
    }

    @Test func sameAsFoundation() {
        var differences: [String] = []
        for example in SpecCorpus.examples where Self.knownDifferences[Self.key(example)] == nil {
            if let difference = Self.firstDifference(example.markdown) {
                differences.append("\(Self.key(example)) (\(example.section)) \(example.markdown.debugDescription)\n  \(difference)")
            }
        }
        if let path = ProcessInfo.processInfo.environment["MARKDOWN_PARITY_REPORT"] {
            try? differences.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
        }
        #expect(differences.isEmpty, "\(differences.count) examples differ\n\(differences.prefix(5).joined(separator: "\n"))")
    }

    /// Each known difference must still be a difference, so the list cannot hide a fixed case.
    @Test(arguments: knownDifferences.keys.sorted())
    func knownDifferenceStillDiffers(key: String) throws {
        let example = try #require(SpecCorpus.examples.first { Self.key($0) == key })
        #expect(Self.firstDifference(example.markdown) != nil, "\(key) no longer differs: remove it from the list")
    }

    /// Files in `MARKDOWN_PARITY_FILES` (paths split by ":"). Skipped (not passed) when it is not set.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MARKDOWN_PARITY_FILES"] != nil))
    func filesSameAsFoundation() throws {
        let paths = (ProcessInfo.processInfo.environment["MARKDOWN_PARITY_FILES"] ?? "").split(separator: ":")
        for path in paths {
            let markdown = try String(contentsOf: URL(fileURLWithPath: String(path)), encoding: .utf8)
            let differences = allBlockDifferences(FoundationReferenceParser.parse(markdown).blocks, MarkdownParser.parse(markdown).blocks)
            print("parity file: \(path.split(separator: "/").last ?? "") differences=\(differences.count)\n\(differences.joined(separator: "\n"))")
            #expect(differences.isEmpty, "\(path): \(differences.joined(separator: "\n"))")
        }
    }
}

/// Describes the first block that differs, or nil when both trees are equal.
private func firstBlockDifference(_ expected: [MarkdownBlock], _ actual: [MarkdownBlock]) -> String? {
    let left = flatten(expected)
    let right = flatten(actual)
    for (index, pair) in zip(left, right).enumerated() where !sameBlockShallow(pair.0, pair.1) {
        return "block #\(index): expected \(describe(pair.0))\n  actual   \(describe(pair.1))"
    }
    if left.count != right.count {
        return "block count: expected \(left.count), actual \(right.count)"
    }
    return expected == actual ? nil : "trees differ (same flat blocks)"
}

/// Every block that differs, for a report on a whole file.
private func allBlockDifferences(_ expected: [MarkdownBlock], _ actual: [MarkdownBlock]) -> [String] {
    let left = flatten(expected)
    let right = flatten(actual)
    var result = zip(left, right).enumerated()
        .filter { !sameBlockShallow($0.element.0, $0.element.1) }
        .map { "block #\($0.offset): expected \(describe($0.element.0))\n  actual   \(describe($0.element.1))" }
    if left.count != right.count { result.append("block count: expected \(left.count), actual \(right.count)") }
    return result
}

/// Compares one block without its children (children are compared on their own).
private func sameBlockShallow(_ left: MarkdownBlock, _ right: MarkdownBlock) -> Bool {
    guard left.id == right.id, left.sourceLine == right.sourceLine else { return false }
    switch (left.kind, right.kind) {
    case (.blockQuote(let a), .blockQuote(let b)): return a.count == b.count
    case (.list(let a), .list(let b)):
        return a.isOrdered == b.isOrdered && a.startIndex == b.startIndex && a.items.map(\.checkbox) == b.items.map(\.checkbox)
            && a.items.map(\.blocks.count) == b.items.map(\.blocks.count)
    default: return left.kind == right.kind
    }
}

private func describe(_ block: MarkdownBlock) -> String {
    let kind: String
    switch block.kind {
    case .paragraph(let text): kind = "paragraph \(runs(text))"
    case .heading(let level, let text): kind = "heading\(level) \(runs(text))"
    case .codeBlock(let language, let code): kind = "code(\(language ?? "-")) \(code.prefix(60).debugDescription)"
    case .table(let table): kind = "table cols=\(table.columns.count) rows=\(table.rows.count) header=\(table.header.map(runs))"
    case .list(let list): kind = "list ordered=\(list.isOrdered) start=\(list.startIndex) items=\(list.items.count)"
    case .blockQuote(let children): kind = "quote children=\(children.count)"
    case .thematicBreak: kind = "hr"
    case .image(let url, let alt): kind = "image \(url?.absoluteString ?? "nil") \(alt.debugDescription)"
    }
    return "id=\(block.id) line=\(block.sourceLine) \(kind)"
}

private func runs(_ text: AttributedString) -> String {
    text.runs.prefix(12).map { run in
        var parts = [String(text[run.range].characters).debugDescription]
        if let intent = run.inlinePresentationIntent { parts.append("i\(intent.rawValue)") }
        if let link = run.link { parts.append("link=\(link.absoluteString)") }
        if let image = run.imageURL { parts.append("img=\(image.absoluteString)") }
        if run[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] != nil { parts.append("u") }
        return "[" + parts.joined(separator: " ") + "]"
    }.joined()
}
