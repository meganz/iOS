import Foundation

/// Test documents. Same generator as `ParsingLargeInputTests.makeLargeDocument`.
enum BenchmarkDocuments {
    static func makeLargeDocument(targetBytes: Int) -> String {
        let section = """
        ## Section heading

        A paragraph with **bold**, *italic*, `code`, ~~strike~~ and a [link](https://mega.io).
        It continues on a second line so there is a soft break.

        - item one
        - item two
          - nested item
        1. first
        2. second

        > A quote with *emphasis*.

        ```swift
        let value = 42
        print(value)
        ```

        | A | B |
        |---|:-:|
        | 1 | 2 |

        ---


        """
        let count = targetBytes / section.utf8.count + 1
        return String(repeating: section, count: count)
    }

    /// Every block kind, then the big blocks, repeated until the text reaches `targetBytes`.
    /// One repeat holds about 10 MB of big blocks: a 1 MB paragraph, a 5 MB code block, a table of 100,000 rows,
    /// a list of 100,000 items, a 1 MB quote and a 1 MB line with no space. No randomness.
    static func makeAllKindsDocument(targetBytes: Int) -> String {
        let unit = allKindsSection() + bigBlocks()
        var document = ""
        document.reserveCapacity(targetBytes + unit.utf8.count)
        while document.utf8.count < targetBytes {
            document += unit
        }
        return document
    }

    /// About 100 sections with one block of each kind.
    private static func allKindsSection() -> String {
        let headings = (1...6).map { String(repeating: "#", count: $0) + " Heading level \($0)" }.joined(separator: "\n\n")
        let wideHeader = "|" + (1...70).map { " c\($0) |" }.joined()
        let wideDelimiter = "|" + String(repeating: "---|", count: 70)
        let wideRow = "|" + (1...70).map { " `v\($0)` |" }.joined()
        let section = """
        \(headings)

        A paragraph with **bold**, *italic*, ~~strike~~, `inline code`, a [link](https://mega.io) and an autolink https://mega.io/docs.
        It goes on after a soft break.\\
        And after a hard break, with an inline image ![logo](https://mega.io/logo.png) in the text.

        - bullet one
        - bullet two
          - nested two
            - nested three
              - nested four
        - bullet with code and quote

          ```
          code in an item
          ```

          > quote in an item

        7. ordered seven
        8. ordered eight

        - [ ] open task
        - [x] done task

        > A quote with *emphasis*.
        >
        > > A nested quote.
        >
        > - list in a quote
        > - second item
        >
        > | A | B |
        > |---|---|
        > | 1 | 2 |

        ```swift
        let value = 42
        let longLine = "\(String(repeating: "long code line ", count: 40))"
        ```

            indented code line one
            indented code line two

        | Left | Center | Right |
        |:-----|:------:|------:|
        | `a` | b | c |
        | 1 | `2` | 3 |

        \(wideHeader)
        \(wideDelimiter)
        \(wideRow)

        ---

        ![An image block](https://mega.io/image.png)


        """
        return String(repeating: section, count: 100)
    }

    private static func bigBlocks() -> String {
        HugeBlock.allCases.map(\.markdown).joined(separator: "\n\n") + "\n\n"
    }

    /// One block that is a whole file on its own: 1 MB to 6 MB of one kind.
    enum HugeBlock: String, CaseIterable {
        case paragraph, code, table, list, quote, line

        var markdown: String {
            switch self {
            case .paragraph: String(repeating: "Words of a very long paragraph with **bold** text. ", count: 20_000)
            case .code: "```text\n" + (0..<250_000).map { "let line\($0) = \($0)" }.joined(separator: "\n") + "\n```"
            case .table: "| Row | Value | Note |\n|---|:-:|--:|\n" + (0..<100_000).map { "| \($0) | v\($0) | `n` |" }.joined(separator: "\n")
            case .list: (0..<100_000).map { "- item \($0)" }.joined(separator: "\n")
            case .quote: (0..<20_000).map { "> Quoted paragraph \($0) with some words in it.\n>" }.joined(separator: "\n")
            case .line: String(repeating: "x", count: 1_000_000)
            }
        }
    }

    struct PathologicalInput {
        var name: String
        var markdown: String
        /// The number of top-level blocks the parse gives. `PathologicalInputTests` checks the full output.
        var blocks: Int
    }

    /// The inputs of `PathologicalInputTests.cases`, from cmark's `test/pathological_tests.py`. Keep both lists the same.
    static func pathologicalInputs() -> [PathologicalInput] {
        func repeated(_ unit: String, _ count: Int) -> String { String(repeating: unit, count: count) }
        return [
            PathologicalInput(name: "nested strong emph", markdown: repeated("*a **a ", 65_000) + "b" + repeated(" a** a*", 65_000), blocks: 1),
            PathologicalInput(name: "many emph closers with no openers", markdown: repeated("a_ ", 65_000), blocks: 1),
            PathologicalInput(name: "many emph openers with no closers", markdown: repeated("_a ", 65_000), blocks: 1),
            PathologicalInput(name: "many link closers with no openers", markdown: repeated("a]", 65_000), blocks: 1),
            PathologicalInput(name: "many link openers with no closers", markdown: repeated("[a", 65_000), blocks: 1),
            PathologicalInput(name: "mismatched openers and closers", markdown: repeated("*a_ ", 50_000), blocks: 1),
            PathologicalInput(name: "openers and closers multiple of 3", markdown: "a**b" + repeated("c* ", 50_000), blocks: 1),
            PathologicalInput(name: "link openers and emph closers", markdown: repeated("[ a_", 50_000), blocks: 1),
            PathologicalInput(name: "pattern [ (]( repeated", markdown: repeated("[ (](", 80_000), blocks: 1),
            PathologicalInput(name: "pattern ![[]() repeated", markdown: repeated("![[]()", 160_000), blocks: 1),
            PathologicalInput(name: "hard link/emph case", markdown: "**x [a*b**c*](d)", blocks: 1),
            PathologicalInput(name: "nested brackets", markdown: repeated("[", 50_000) + "a" + repeated("]", 50_000), blocks: 1),
            PathologicalInput(name: "deeply nested lists", markdown: (0..<1_000).map { repeated("  ", $0) + "* a\n" }.joined(), blocks: 1),
            PathologicalInput(name: "U+0000 in input", markdown: "abc\u{0}de\u{0}", blocks: 1),
            PathologicalInput(name: "backticks", markdown: (1..<5_000).map { "e" + repeated("`", $0) }.joined(), blocks: 1),
            PathologicalInput(name: "unclosed links A", markdown: repeated("[a](<b", 30_000), blocks: 1),
            PathologicalInput(name: "unclosed links B", markdown: repeated("[a](b", 30_000), blocks: 1),
            PathologicalInput(name: "unclosed <!--", markdown: "</" + repeated("<!--", 300_000), blocks: 1),
            PathologicalInput(name: "tables", markdown: repeated("aaa\rbbb\n-\u{0B}\n", 30_000), blocks: 2),
            PathologicalInput(name: "many image openers", markdown: repeated("![p", 100_000) + "\n", blocks: 1),
            PathologicalInput(name: "reference collisions", markdown: referenceCollisions(), blocks: 49_999)
        ]
    }

    /// 50 000 reference labels that collide in cmark's 16-bucket reference map, from `hash_collisions()`.
    private static func referenceCollisions() -> String {
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
        return keys.map { "[\($0)]: /url\n\n[\(badKey)]\n\n" }.joined()
    }
}
