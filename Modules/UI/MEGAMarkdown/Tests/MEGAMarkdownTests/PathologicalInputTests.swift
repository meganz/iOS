import Foundation
@testable import MEGAMarkdown
import Testing

/// The inputs from cmark's `test/pathological_tests.py`, through the whole parser and the chunker.
/// Each case must finish fast and give the output cmark gives. Deep quotes and lists are in `ParserDifferenceTests`.
@Suite struct PathologicalInputTests {
    struct Case: CustomTestStringConvertible {
        var name: String
        var markdown: String
        var check: @Sendable ([MarkdownBlock]) -> Bool
        var testDescription: String { name }
    }

    static func repeated(_ unit: String, _ count: Int) -> String { String(repeating: unit, count: count) }

    /// One paragraph whose text is the input without its trailing spaces: nothing matched, nothing was lost.
    static func literalParagraph(_ name: String, _ markdown: String) -> Case {
        let text = String(markdown.reversed().drop { $0 == " " || $0 == "\n" }.reversed())
        return Case(name: name, markdown: markdown) { $0.count == 1 && $0.first?.paragraphText == text }
    }

    /// 50 000 reference labels that collide in cmark's 16-bucket reference map, from `hash_collisions()`.
    static func referenceCollisions() -> Case {
        func collides(_ key: String) -> Bool {
            var hash: UInt32 = 0
            for byte in key.utf8 { hash = UInt32(byte) &+ (hash << 6) &+ (hash << 16) &- hash }
            return hash % 16 == 0
        }
        var keys: [String] = []
        var index = 0
        while keys.count < 50_000 {
            if collides("x\(index)") { keys.append("x\(index)") }
            index += 1
        }
        let badKey = keys.removeFirst()
        let markdown = keys.map { "[\($0)]: /url\n\n[\(badKey)]\n\n" }.joined()
        return Case(name: "reference collisions", markdown: markdown) { blocks in
            blocks.count == 49_999 && blocks.allSatisfy { $0.paragraphText == "[\(badKey)]" }
        }
    }

    static let cases: [Case] = [
        Case(name: "nested strong emph", markdown: repeated("*a **a ", 65_000) + "b" + repeated(" a** a*", 65_000)) {
            $0.count == 1 && $0.first?.paragraphText == repeated("a a ", 65_000) + "b" + repeated(" a a", 65_000)
        },
        literalParagraph("many emph closers with no openers", repeated("a_ ", 65_000)),
        literalParagraph("many emph openers with no closers", repeated("_a ", 65_000)),
        literalParagraph("many link closers with no openers", repeated("a]", 65_000)),
        literalParagraph("many link openers with no closers", repeated("[a", 65_000)),
        literalParagraph("mismatched openers and closers", repeated("*a_ ", 50_000)),
        literalParagraph("openers and closers multiple of 3", "a**b" + repeated("c* ", 50_000)),
        literalParagraph("link openers and emph closers", repeated("[ a_", 50_000)),
        literalParagraph("pattern [ (]( repeated", repeated("[ (](", 80_000)),
        // Each `[]()` is a link with empty text, so it keeps a placeholder (same rule as `[](url)`).
        Case(name: "pattern ![[]() repeated", markdown: repeated("![[]()", 160_000)) {
            $0.count == 1 && $0.first?.paragraphText == repeated("![\u{FFFC}", 160_000)
        },
        Case(name: "hard link/emph case", markdown: "**x [a*b**c*](d)") {
            $0.count == 1 && $0.first?.paragraphText == "**x ab**c"
        },
        literalParagraph("nested brackets", repeated("[", 50_000) + "a" + repeated("]", 50_000)),
        Case(name: "deeply nested lists", markdown: (0..<1_000).map { repeated("  ", $0) + "* a\n" }.joined()) {
            $0.count == 1 && $0.first?.list != nil
        },
        Case(name: "U+0000 in input", markdown: "abc\u{0}de\u{0}") {
            $0.count == 1 && $0.first?.paragraphText == "abc\u{FFFD}de\u{FFFD}"
        },
        literalParagraph("backticks", (1..<5_000).map { "e" + repeated("`", $0) }.joined()),
        literalParagraph("unclosed links A", repeated("[a](<b", 30_000)),
        literalParagraph("unclosed links B", repeated("[a](b", 30_000)),
        literalParagraph("unclosed <!--", "</" + repeated("<!--", 300_000)),
        Case(name: "tables", markdown: repeated("aaa\rbbb\n-\u{0B}\n", 30_000)) {
            $0.count == 2 && $0.first?.paragraphText == "aaa" && $0.last?.table?.rows.count == 29_999 * 3
        },
        Case(name: "many image openers", markdown: repeated("![p", 100_000) + "\n") {
            $0.count == 1 && $0.first?.paragraphText == repeated("![p", 100_000)
        },
        referenceCollisions()
    ]

    /// cmark's `pathological_tests.py` allows 5 s per case for the C parser alone. Same limit here for parser + walker.
    @Test(arguments: cases)
    func parsesFastWithTheExpectedOutput(testCase: Case) {
        let clock = ContinuousClock()
        var blocks: [MarkdownBlock] = []
        let elapsed = clock.measure { blocks = parse(testCase.markdown) }
        print("pathological: \(testCase.name) bytes=\(testCase.markdown.utf8.count) blocks=\(blocks.count) time=\(elapsed)")
        #expect(elapsed < .seconds(5), "\(testCase.name) took \(elapsed)")
        #expect(testCase.check(blocks), "\(testCase.name): unexpected output, \(blocks.count) blocks")
    }

    @Test(arguments: cases)
    func chunkedParseMatchesWholeParse(testCase: Case) {
        let whole = ChunkedParseTests.whole(testCase.markdown)
        let chunked = ChunkedParseTests.chunked(testCase.markdown, target: 4_096).trees
        #expect(ChunkedParseTests.firstDifference(whole, chunked) == nil, "\(testCase.name)")
    }
}
