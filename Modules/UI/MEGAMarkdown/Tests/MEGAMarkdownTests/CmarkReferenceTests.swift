import Foundation
@testable import MEGAMarkdown
import Testing

/// The walker against cmark's own HTML (`CmarkReference`). Every difference must come from a rule.
/// `MARKDOWN_REFERENCE_REPORT` writes every difference to a file.
@Suite struct CmarkReferenceTests {
    // MARK: - Inputs

    /// All cmark spec files, also `smart_punct.txt`: smart punctuation is off on both sides.
    static let specInputs: [(name: String, markdown: String)] = SpecCorpus.examples.map { ("\($0.file) \($0.number)", $0.markdown) }

    /// The Markdown fixtures of the golden tests and `all-blocks.md`.
    static let fixtureInputs: [(name: String, markdown: String)] = {
        var urls = Bundle.module.urls(forResourcesWithExtension: "md", subdirectory: "Fixtures/parity") ?? []
        if let allBlocks = Bundle.module.url(forResource: "all-blocks", withExtension: "md", subdirectory: "Fixtures") {
            urls.append(allBlocks)
        }
        return urls.sorted { $0.lastPathComponent < $1.lastPathComponent }.compactMap { url in
            (try? String(contentsOf: url, encoding: .utf8)).map { (url.lastPathComponent, $0) }
        }
    }()

    /// Spec examples changed at random: inserted Markdown syntax, deleted ranges, container prefixes and joins.
    /// Seeded, so a failure repeats. `MARKDOWN_REFERENCE_ITERATIONS` sets the count, `MARKDOWN_REFERENCE_SEED` the seed.
    static func mutatedInputs() -> [(name: String, markdown: String)] {
        let environment = ProcessInfo.processInfo.environment
        let iterations = environment["MARKDOWN_REFERENCE_ITERATIONS"].flatMap(Int.init) ?? 3000
        var generator = ChunkedParseTests.Seeded(state: environment["MARKDOWN_REFERENCE_SEED"].flatMap(UInt64.init) ?? 11)
        let pool = SpecCorpus.examples.map(\.markdown)
        return (0..<iterations).map { index in
            var text = pool.randomElement(using: &generator) ?? ""
            for _ in 0..<Int.random(in: 1...4, using: &generator) {
                text = mutate(text, pool: pool, using: &generator)
            }
            return ("mutation \(index)", text)
        }
    }

    private static let tokens = [
        "*", "**", "_", "`", "[", "]", "(", ")", "!", "<", ">", "\\", "&amp;", "&#91;", "#", "-", "+", "1.", " ", "\t",
        "\n", "\n\n", "> ", "- ", "|", "~~", "[x] ", "[ ] ", "http://a.b", "<u>", "</u>", "<b>", "</b>", "\u{E4}", "%20",
        "    ", "```", "---", "[a]: /u\n", "![i](p.png)", "[l](/u \"t\")"
    ]

    private static func mutate(_ text: String, pool: [String], using generator: inout ChunkedParseTests.Seeded) -> String {
        var characters = Array(text)
        switch Int.random(in: 0..<5, using: &generator) {
        case 0, 1:
            let index = Int.random(in: 0...characters.count, using: &generator)
            characters.insert(contentsOf: tokens.randomElement(using: &generator) ?? "", at: index)
        case 2:
            guard !characters.isEmpty else { break }
            let start = Int.random(in: 0..<characters.count, using: &generator)
            let end = min(characters.count, start + Int.random(in: 1...6, using: &generator))
            characters.removeSubrange(start..<end)
        case 3:
            let prefix = ["> ", "- ", "1. ", "  ", "> - "].randomElement(using: &generator) ?? "> "
            return text.split(separator: "\n", omittingEmptySubsequences: false).map { prefix + $0 }.joined(separator: "\n")
        default:
            return text + ["", "\n", "\n\n"].randomElement(using: &generator)! + (pool.randomElement(using: &generator) ?? "")
        }
        return String(characters)
    }

    // MARK: - Comparison

    private static func differences(_ inputs: [(name: String, markdown: String)]) -> [String] {
        let differences = inputs.compactMap { input in
            CmarkReference.difference(input.markdown).map { "\(input.name) \(input.markdown.debugDescription)\n  \($0)" }
        }
        if let path = ProcessInfo.processInfo.environment["MARKDOWN_REFERENCE_REPORT"] {
            let old = (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
            try? (old + differences.joined(separator: "\n") + "\n").write(toFile: path, atomically: true, encoding: .utf8)
        }
        return differences
    }

    @Test func specExamplesMatchCmark() {
        let differences = Self.differences(Self.specInputs)
        #expect(differences.isEmpty, "\(differences.count) differ\n\(differences.prefix(5).joined(separator: "\n"))")
    }

    @Test func fixtureFilesMatchCmark() {
        #expect(Self.fixtureInputs.count > 60)
        let differences = Self.differences(Self.fixtureInputs)
        #expect(differences.isEmpty, "\(differences.count) differ\n\(differences.prefix(5).joined(separator: "\n"))")
    }

    @Test(.timeLimit(.minutes(5)))
    func mutatedInputsMatchCmark() {
        let differences = Self.differences(Self.mutatedInputs())
        #expect(differences.isEmpty, "\(differences.count) differ\n\(differences.prefix(5).joined(separator: "\n"))")
    }

    /// Files in `MARKDOWN_REFERENCE_FILES` (paths split by ":"), for example real documents or other parsers' fixtures.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MARKDOWN_REFERENCE_FILES"] != nil))
    func filesMatchCmark() throws {
        let paths = (ProcessInfo.processInfo.environment["MARKDOWN_REFERENCE_FILES"] ?? "").split(separator: ":")
        let inputs = try paths.map { path in
            (String(path), try String(contentsOf: URL(fileURLWithPath: String(path)), encoding: .utf8))
        }
        let differences = Self.differences(inputs)
        #expect(differences.isEmpty, "\(differences.count) differ\n\(differences.prefix(5).joined(separator: "\n"))")
    }

    // MARK: - Rules

    /// Each rule is still needed: without it, its example differs. With all rules, it does not.
    @Test(arguments: CmarkReference.rules.map(\.id))
    func ruleIsNeeded(id: String) throws {
        let rule = try #require(CmarkReference.rules.first { $0.id == id })
        #expect(CmarkReference.difference(rule.example) == nil)
        #expect(CmarkReference.difference(rule.example, rules: CmarkReference.rules.filter { $0.id != id }) != nil)
    }

    @Test func ruleIDsAreUnique() {
        #expect(Set(CmarkReference.rules.map(\.id)).count == CmarkReference.rules.count)
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

    @Test func canonicalKeepsTheBreakBetweenTwoParagraphsInAnItem() {
        #expect(SpecHTML.canonical("<ul>\n<li>\n<p>a</p>\n<p>c</p>\n</li>\n</ul>\n") == SpecHTML.canonical("<ul>\n<li>a\nc</li>\n</ul>\n"))
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

    @Test func canonicalMergesRunsWhateverTheTagOrder() {
        let html = "<p><del><strong>a</strong></del><strong><del>b</del></strong></p>\n"
        #expect(SpecHTML.canonical(html) == "<p><strong><del>ab</del></strong></p>\n")
    }

    @Test func canonicalTreatsAStyleTagWithNoClosingTagAsText() {
        #expect(SpecHTML.canonical("<ul>\n<li>a<u>b</li>\n</ul>\n") == "<ul>\n<li>a<u>b</li>\n</ul>\n")
    }

    @Test func rawHTMLIsComparedAsText() {
        #expect(CmarkReference.html("<td>x</td>\n") == "\u{27E8}td\u{27E9}x\u{27E8}/td\u{27E9}\n")
        #expect(CmarkReference.walkerHTML("<td>x</td>\n") == "\u{27E8}td\u{27E9}x\u{27E8}/td\u{27E9}\n")
    }

    @Test func hrefEscapingMatchesCmark() {
        #expect(SpecHTML.escapeHref("http://a.b/c d?x=1&y='z'") == "http://a.b/c%20d?x=1&amp;y=&#x27;z&#x27;")
        #expect(SpecHTML.escapeHref("/\u{FC}") == "/%C3%BC")
    }
}
