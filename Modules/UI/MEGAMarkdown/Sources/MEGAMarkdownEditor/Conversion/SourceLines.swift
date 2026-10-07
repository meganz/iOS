import Foundation

/// The lines of a text with "\n" line ends. Ranges are line indexes.
struct SourceLines {
    private let lines: [Substring]

    init(_ text: String) {
        lines = text.split(separator: "\n", omittingEmptySubsequences: false)
    }

    var count: Int { lines.count }

    func join(_ range: Range<Int>) -> String {
        lines[range].joined(separator: "\n")
    }

    func isBlank(_ index: Int) -> Bool {
        lines[index].utf8.allSatisfy { $0 == 32 || $0 == 9 }
    }

    func isBlank(_ range: Range<Int>) -> Bool {
        range.allSatisfy(isBlank)
    }

    /// The range without blank lines at both ends.
    func trimmed(_ range: Range<Int>) -> Range<Int> {
        var lower = max(0, range.lowerBound)
        var upper = min(range.upperBound, lines.count)
        while lower < upper, isBlank(lower) { lower += 1 }
        while upper > lower, isBlank(upper - 1) { upper -= 1 }
        return lower..<max(lower, upper)
    }

    /// YAML front matter: `---` on the first line, a non-blank second line, up to the next `---` or `...` line.
    /// Returns the line after it, or 0. A divider at the start has a blank line after it, so it is not front matter.
    func frontMatterEnd() -> Int {
        guard let first = lines.first, first.trimmingCharacters(in: .whitespaces) == "---", lines.count > 1,
              !isBlank(1), lines[1].trimmingCharacters(in: .whitespaces) != "---" else { return 0 }
        for index in 1..<lines.count {
            let line = lines[index].trimmingCharacters(in: .whitespaces)
            if line == "---" || line == "..." { return index + 1 }
        }
        return 0
    }

    /// `[label]: destination` at the line start, after quote markers, list markers and spaces.
    /// It may also be text that only looks like one. The caller then keeps the block raw, which is safe.
    func looksLikeDefinition(_ index: Int) -> Bool {
        var line = lines[index].drop { $0 == " " || $0 == "\t" || $0 == ">" }
        while let marker = Self.listMarkerEnd(line) {
            line = line[marker...].drop { $0 == " " || $0 == "\t" || $0 == ">" }
        }
        guard line.hasPrefix("["), let close = line.firstIndex(of: "]") else { return false }
        return line[line.index(after: close)...].hasPrefix(":")
    }

    /// End of a list marker (`-`, `+`, `*`, `1.`, `1)`) followed by a space, a tab or the line end.
    private static func listMarkerEnd(_ text: Substring) -> Substring.Index? {
        guard let first = text.first else { return nil }
        var index = text.startIndex
        if first == "-" || first == "+" || first == "*" {
            index = text.index(after: index)
        } else if first.isASCII && first.isNumber {
            let digits = text.prefix { $0.isASCII && $0.isNumber }
            guard digits.count <= 9 else { return nil }
            index = digits.endIndex
            guard index < text.endIndex, text[index] == "." || text[index] == ")" else { return nil }
            index = text.index(after: index)
        } else {
            return nil
        }
        if index == text.endIndex { return index }
        return text[index] == " " || text[index] == "\t" ? index : nil
    }
}
