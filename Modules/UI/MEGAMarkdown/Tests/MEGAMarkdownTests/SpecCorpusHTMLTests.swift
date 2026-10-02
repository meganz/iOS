import Foundation
@testable import MEGAMarkdown
import Testing

/// Every cmark spec example: the walker output, rendered as HTML, against the spec's expected HTML.
/// This makes the spec the oracle for the walker. `SpecCorpusParityTests` uses Foundation as the oracle.
/// Wanted differences are listed with a reason. `smart_punct.txt` is skipped: that extension is off.
@Suite struct SpecCorpusHTMLTests {
    /// "file number" of each example that differs on purpose, with the reason.
    static let knownDifferences: [String: String] = [
        // The walker drops blocks with no content (empty heading, code block, quote, list item), like Foundation.
        "spec 49": "empty block dropped", "spec 96": "empty block dropped", "spec 100": "empty block dropped",
        "spec 114": "empty block dropped", "spec 187": "empty block dropped", "spec 215": "empty block dropped",
        "spec 217": "empty block dropped", "spec 218": "empty block dropped", "spec 258": "empty block dropped",
        "spec 259": "empty block dropped", "spec 260": "empty block dropped", "spec 261": "empty block dropped",
        "spec 262": "empty block dropped", "spec 295": "empty block dropped",
        // The walker strips all trailing newlines of a code block. cmark keeps the blank lines before the closing fence.
        "spec 298": "code block trailing newlines",
        // An image inside a link keeps only its alt text, like Foundation.
        "spec 525": "image inside a link", "spec 539": "image inside a link",
        // `ParsedBlock.Kind.image` has no title. Inline images keep theirs.
        "spec 580": "image block title", "spec 581": "image block title", "spec 584": "image block title",
        "spec 585": "image block title", "spec 592": "image block title", "spec 593": "image block title",
        "spec 594": "image block title", "spec 596": "image block title", "spec 597": "image block title",
        "spec 599": "image block title",
        // The GFM autolink extension is on. The CommonMark spec examples expect it off.
        "spec 610": "autolink extension on", "spec 614": "autolink extension on", "spec 616": "autolink extension on",
        "spec 619": "autolink extension on", "spec 620": "autolink extension on",
        // The tagfilter extension is off, so `<title>` and friends stay raw.
        "spec 652": "tagfilter extension off", "extensions 22": "tagfilter extension off",
        // The footnotes extension is off, so `[^x]` is text, a link or a link definition.
        "extensions 23": "footnotes extension off", "extensions 24": "footnotes extension off",
        "extensions 25": "footnotes extension off", "regression 13": "footnotes extension off",
        "regression 20": "footnotes extension off", "regression 21": "footnotes extension off",
        "regression 22": "footnotes extension off", "regression 23": "footnotes extension off",
        "regression 24": "footnotes extension off"
    ]

    /// `<IGNORE>` marks a crash test with no expected output, like in cmark's `spec_tests.py`.
    static let examples = SpecCorpus.examples.filter { $0.file != "smart_punct" && $0.html != "<IGNORE>\n" }

    static func key(_ example: SpecCorpus.Example) -> String { "\(example.file) \(example.number)" }

    /// Nil when the rendered walker output matches the spec HTML in canonical form.
    static func difference(_ example: SpecCorpus.Example) -> String? {
        let blocks = CmarkParser.blocks(example.markdown, softBreak: .lineBreak) ?? []
        let actual = SpecHTML.canonical(SpecHTML.render(blocks))
        let expected = SpecHTML.canonical(example.html)
        guard actual != expected else { return nil }
        return "expected \(expected.debugDescription)\n  actual   \(actual.debugDescription)"
    }

    @Test func examplesExist() {
        // 670 + 30 + 26 examples, minus the one `<IGNORE>` crash test. 43 are known differences.
        #expect(Self.examples.count == 725)
        #expect(Self.knownDifferences.count == 43)
    }

    @Test func knownDifferencesNameRealExamples() {
        let keys = Set(Self.examples.map(Self.key))
        #expect(Set(Self.knownDifferences.keys).isSubset(of: keys))
    }

    @Test func sameAsSpec() {
        var differences: [String] = []
        for example in Self.examples where Self.knownDifferences[Self.key(example)] == nil {
            if let difference = Self.difference(example) {
                differences.append("\(Self.key(example)) (\(example.section)) \(example.markdown.debugDescription)\n  \(difference)")
            }
        }
        if let path = ProcessInfo.processInfo.environment["MARKDOWN_HTML_REPORT"] {
            try? differences.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
        }
        #expect(differences.isEmpty, "\(differences.count) examples differ\n\(differences.prefix(5).joined(separator: "\n"))")
    }

    /// Each known difference must still be a difference, so the list cannot hide a fixed case.
    @Test(arguments: knownDifferences.keys.sorted())
    func knownDifferenceStillDiffers(key: String) throws {
        let example = try #require(Self.examples.first { Self.key($0) == key })
        #expect(Self.difference(example) != nil, "\(key) no longer differs: remove it from the list")
    }

    // MARK: - Canonical form

    @Test func canonicalFlattensNestedInlineTags() {
        #expect(SpecHTML.canonical("<p><strong>foo <em>bar</em></strong></p>\n")
            == SpecHTML.canonical("<p><strong>foo </strong><em><strong>bar</strong></em></p>\n"))
    }

    @Test func canonicalDropsParagraphsInListItems() {
        let loose = "<ul>\n<li>\n<p>a</p>\n<ul>\n<li>\n<p>b</p>\n</li>\n</ul>\n</li>\n</ul>\n"
        let tight = "<ul>\n<li>a\n<ul>\n<li>b</li>\n</ul>\n</li>\n</ul>\n"
        #expect(SpecHTML.canonical(loose) == SpecHTML.canonical(tight))
        #expect(SpecHTML.canonical(tight) == "<ul>\n<li>a\n<ul>\n<li>b</li>\n</ul></li>\n</ul>\n")
    }

    @Test func canonicalCountsATagNestedInItselfOnce() {
        #expect(SpecHTML.canonical("<p><em><em>foo</em></em></p>\n") == "<p><em>foo</em></p>\n")
    }

    @Test func canonicalKeepsNewlineBeforeParagraphAfterBlockInItem() {
        let loose = "<ul>\n<li>\n<h2>Bar</h2>\n<p>baz</p>\n</li>\n</ul>\n"
        #expect(SpecHTML.canonical(loose) == "<ul>\n<li>\n<h2>Bar</h2>\nbaz</li>\n</ul>\n")
    }

    @Test func canonicalKeepsParagraphBoundaries() {
        #expect(SpecHTML.canonical("<p>a</p>\n<p>b</p>\n") != SpecHTML.canonical("<p>a\nb</p>\n"))
    }

    @Test func hrefEscapingMatchesCmark() {
        #expect(SpecHTML.escapeHref("http://a.b/c d?x=1&y='z'") == "http://a.b/c%20d?x=1&amp;y=&#x27;z&#x27;")
        #expect(SpecHTML.escapeHref("/ü") == "/%C3%BC")
    }
}
