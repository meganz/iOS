import Foundation
@testable import MEGAMarkdown
import Testing

/// A chunked parse must give the same cmark tree as one parse of the whole text.
/// Compares the full tree: block types and lines, list type, start and tightness, literals, URLs and titles.
@Suite struct ChunkedParseTests {
    struct Chunked {
        var trees: [String]
        var chunks: [MarkdownChunker.Chunk]
        var rejected: Int
    }

    static func chunked(_ text: String, target: Int, maxChunkBytes: Int = MarkdownChunker.defaultMaxChunkBytes) -> Chunked {
        var source = text
        return source.withUTF8 { buffer in
            var chunker = MarkdownChunker(source: buffer, targetBytes: target, maxChunkBytes: maxChunkBytes)
            var chunks: [MarkdownChunker.Chunk] = []
            while let chunk = chunker.next() { chunks.append(chunk) }
            let trees = chunks.flatMap { chunk in
                CmarkParser.debugTree(
                    prefix: chunker.definitionPrefix(for: chunk),
                    body: UnsafeBufferPointer(rebasing: buffer[chunk.bytes]),
                    lineOffset: chunk.lines.lowerBound - chunker.definitionLineCount(for: chunk)
                )
            }
            return Chunked(trees: trees, chunks: chunks, rejected: chunker.rejectedCuts)
        }
    }

    static func whole(_ text: String) -> [String] {
        var source = text
        return source.withUTF8 { CmarkParser.debugTree(prefix: [], body: $0, lineOffset: 0) }
    }

    static func firstDifference(_ whole: [String], _ chunked: [String]) -> String? {
        for index in 0..<max(whole.count, chunked.count) {
            let left = index < whole.count ? whole[index] : "<none>"
            let right = index < chunked.count ? chunked[index] : "<none>"
            if left != right { return "block \(index)\n whole:   \(left.prefix(300))\n chunked: \(right.prefix(300))" }
        }
        return nil
    }

    // MARK: - Inputs that broke the chunk rule

    static let minimalInputs: [String] = {
        guard let url = Bundle.module.url(forResource: "chunk-minimal-inputs", withExtension: "json", subdirectory: "Fixtures"),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }()

    @Test func minimalInputsExist() {
        #expect(Self.minimalInputs.count == 208)
    }

    /// Every input that broke an earlier version of the chunk rule.
    @Test(arguments: [1, 2, 5, 13, 50])
    func minimalInputsMatch(target: Int) {
        for input in Self.minimalInputs {
            let difference = Self.firstDifference(Self.whole(input), Self.chunked(input, target: target).trees)
            #expect(difference == nil, "\(input.debugDescription): \(difference ?? "")")
        }
    }

    // MARK: - Seeded fuzz

    struct Seeded: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
            value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
            return value ^ (value >> 31)
        }
    }

    /// Pieces that stress the chunk rule: fences, HTML blocks, definitions in every place, lists, tables, CR/CRLF.
    static let snippets: [String] = [
        "```\ncode\n\nX\n```", "~~~~\na\n\nY\n~~~", "```", "````\n```\n\nZ\n````",
        "<div>\n```\n</div>", "<custom>\n~~~\n</custom>", "``` a`b", "```code```",
        "<pre>\na\n\nB\n</pre>", "<!--\nx\n\nY\n-->", "<script>\n\nQ\n</script>", "<?\n\nP\n?>", "<![CDATA[\n\nC\n]]>",
        "<div>\n[r1]: /bad-div\n</div>", "para\n[r2]: /bad-para", "> [r3]: /q", "- [r4]: /l", "> - [r5]: /ql",
        "[a\\]b]: /esc", "[multi\nline]: /ml", "[r6]:\n/next-line", "[r7]: /t\n'title'", "[r8]: /t 'multi\nline'",
        "- a\n  - b\n\n    [r9]: /deep", "| h |\n|---|\n[r10]: /tbl", "> ```\n\n[r11]: /afterq", "    [r12]: /code",
        "para\nlazy", "> quote\nlazy", "Title\n===", "===", "---", "- a\n\n- b\n\n  cont", "1. x\n\n2. y",
        "    indented\n\n    more", "| a | b |\n|---|---|\n| 1 | 2 |",
        "Use [x][r1] [y][r2] [z][r3] [w][r4] [v][r5] [u][a\\]b] [t][multi line] [s][r6] [q][r7] [p][r8] [o][r9] [n][r10] "
            + "[m][r11] [k][r12] [j][R1] [ss][STRASSE] [dz][ǅ]",
        "[straße]: /sz", "[ǆ]: /dz", "[r1]: /good1", "[R1]: /good1b", "[r2]: /good2", "Text *em\n\nnot*", "<u>x\n\ny</u>",
        "[^1]: foot", "\tX", "www.example.com and a@b.com", "- item\n\n  [r4]: /inner-item", ">> [r3]: /qq",
        "<table>\n\n[r1]: /after-table-open\n\n</table>", "- a\n\n  ```\n  x\n\n  y\n  ```", "<custom-tag>\n\nX", "</div>",
        "> a\n>\n> b", "1) x\n\n   para",
        "- [ ] task\n\n  more", "Line  \nhard", "```js", "~~~", "<!-- open", "<?php", "  ```\n  ind fence\n\nX\n  ```",
        "> - a\n>\n>   b", "  - deep\n\n    - deeper\n\n      text", "<div>\n\n*md*\n\n</div>", "Para\n    not code", "#hashtag",
        "# H\n", "~~~\n[r12]: /in-tilde\n~~~", "* * *", "2024. year", "[t1]: <with space> \"a \\\"quoted\\\" & title\"",
        "[t1] and [T1]", "![](empty-alt.png)", "x\n| t |\n|---|\n| 1 |"
    ]

    /// Iterations from `MARKDOWN_FUZZ_ITERATIONS` (3 chunk sizes each). The default keeps a normal test run fast.
    @Test(.timeLimit(.minutes(10)))
    func seededFuzzMatchesWholeParse() {
        let iterations = ProcessInfo.processInfo.environment["MARKDOWN_FUZZ_ITERATIONS"].flatMap(Int.init) ?? 400
        var generator = Seeded(state: 42)
        var cases = 0
        var mismatches: [String] = []
        for _ in 0..<iterations {
            let count = Int.random(in: 2...12, using: &generator)
            var parts = (0..<count).map { _ in Self.snippets.randomElement(using: &generator) ?? "" }
            let separator = ["\n\n", "\n", "\n\n\n"].randomElement(using: &generator) ?? "\n\n"
            let lineEnd = Int.random(in: 0..<10, using: &generator)
            if lineEnd == 0 { parts = parts.map { $0.replacingOccurrences(of: "\n", with: "\r\n") } }
            if lineEnd == 1 { parts = parts.map { $0.replacingOccurrences(of: "\n", with: "\r") } }
            let text = parts.joined(separator: separator == "\n" && lineEnd == 0 ? "\r\n" : separator) + "\n"
            let whole = Self.whole(text)
            let targets = [1, Int.random(in: 2...40, using: &generator), Int.random(in: 40...400, using: &generator)]
            for target in targets {
                cases += 1
                if let difference = Self.firstDifference(whole, Self.chunked(text, target: target).trees) {
                    mismatches.append("target \(target) \(text.debugDescription)\n\(difference)")
                }
            }
        }
        print("chunk fuzz: iterations=\(iterations) cases=\(cases) mismatches=\(mismatches.count)")
        #expect(mismatches.isEmpty, "\(mismatches.prefix(3).joined(separator: "\n"))")
    }

    // MARK: - Shapes

    /// Many small list blocks, each after a blank line. A list's own end line covers the blank line after it,
    /// so a rule that checked the list (not its last leaf) rejected almost every cut.
    @Test func notesShapeCutsWithoutRejections() {
        let notes = (1...3_000).map { "**Topic \($0)** with a short intro line.\n\n- point one of \($0)\n- point two of \($0)\n" }
            .joined(separator: "\n")
        let result = Self.chunked(notes, target: 16_384)
        #expect(result.chunks.count >= 10)
        #expect(result.rejected == 0)
        #expect(Self.firstDifference(Self.whole(notes), result.trees) == nil)
    }

    /// Files in `MARKDOWN_CHUNK_FILES` (paths split by ":"). Skipped (not passed) when it is not set.
    @Test(.enabled(if: ProcessInfo.processInfo.environment["MARKDOWN_CHUNK_FILES"] != nil))
    func filesMatchWholeParse() throws {
        let paths = (ProcessInfo.processInfo.environment["MARKDOWN_CHUNK_FILES"] ?? "").split(separator: ":")
        for path in paths {
            let text = try String(contentsOf: URL(fileURLWithPath: String(path)), encoding: .utf8)
            let result = Self.chunked(text, target: MarkdownChunker.defaultTargetBytes)
            let difference = Self.firstDifference(Self.whole(text), result.trees)
            print("chunk file: \(path.split(separator: "/").last ?? "") chunks=\(result.chunks.count) rejected=\(result.rejected) "
                + "plain=\(result.chunks.contains(where: \.isPlainText)) same=\(difference == nil)")
            #expect(difference == nil, "\(path): \(difference ?? "")")
        }
    }

    @Test func corpusLikeFixtureMatches() throws {
        let markdown = try ParserGoldenTests.fixture("c-mixed-100k.md")
        for target in [512, 4_096, 32_768] {
            let result = Self.chunked(markdown, target: target)
            #expect(result.chunks.count > 1)
            #expect(result.rejected <= result.chunks.count)
            #expect(Self.firstDifference(Self.whole(markdown), result.trees) == nil, "target \(target)")
        }
    }

    @Test func unsafeCutGrowsTheChunkFast() {
        // One fence open for the whole text: every cut is unsafe. The chunk doubles, so rejections stay few.
        let text = "```\n" + (0..<20_000).map { "line \($0)\n\nX \($0)" }.joined(separator: "\n") + "\n```\n"
        let result = Self.chunked(text, target: 1_000)
        #expect(result.chunks.count == 1)
        #expect(result.rejected <= 12)
        #expect(Self.firstDifference(Self.whole(text), result.trees) == nil)
    }

    @Test func blockOverTheCapIsPlainText() {
        let text = "# Title\n\n```\n" + String(repeating: "code line\n", count: 5_000) + "```\n"
        let result = Self.chunked(text, target: 1, maxChunkBytes: 10_000)
        #expect(result.chunks.first?.isPlainText == false)
        #expect(result.chunks.last?.isPlainText == true)
        #expect(result.chunks.last?.bytes.upperBound == text.utf8.count)
    }

    @Test func singleChunkIsNotProbed() {
        let result = Self.chunked("para\n\n[a]: /x\n", target: 1_000_000)
        #expect(result.chunks == [MarkdownChunker.Chunk(lines: 0..<3, bytes: 0..<14)])
    }
}
