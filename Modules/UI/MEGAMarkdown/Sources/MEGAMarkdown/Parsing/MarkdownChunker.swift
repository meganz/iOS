import Foundation
import MEGAFoundation

/// Cuts big Markdown into chunks that each parse to the same result as one whole parse, so no cmark tree
/// holds the whole file. `next()` learns each chunk's link definitions; `definitionPrefix(for:)` shares them
/// with the chunks after it. A reference to a definition in a later chunk stays literal text.
struct MarkdownChunker {
    struct Chunk: Equatable {
        /// Source lines, 0-based.
        var lines: Range<Int>
        /// UTF-8 offsets in the source.
        var bytes: Range<Int>
        /// No safe cut was found within `maxChunkBytes`: this rest of the file is shown as plain text.
        var isPlainText = false
    }

    static let defaultTargetBytes = 1 << 20
    static let defaultMaxChunkBytes = 8 << 20
    /// Candidate cuts tried one by one once doubling would pass `maxChunkBytes`. Each try parses the chunk again.
    static let maxStepsAfterDoubling = 8

    private let source: UnsafeBufferPointer<UInt8>
    private let targetBytes: Int
    private let maxChunkBytes: Int
    /// Offset of each line start. Line ends are `\n`, `\r\n` or `\r`, like cmark.
    private let lineStarts: [Int]
    private var nextLine = 0
    /// Labels as UTF-8 bytes. cmark compares bytes, so `é` and `e` + U+0301 are two labels. Swift `String` would merge them.
    private var seenLabels = Set<[UInt8]>()
    private var definitionTextLines = 0

    /// All definitions learned so far, as Markdown (`[label]: <url> "title"` lines), then a blank line.
    private var definitionPrefix: [UInt8] = []
    /// Lines in `definitionPrefix`.
    private var definitionLineCount = 0
    /// How many candidate cuts after the last doubling were tried one by one (see `next()`).
    private var stepsAfterDoubling = 0
    /// How often a candidate cut was not safe and the chunk had to grow. Only tests read it.
    private(set) var rejectedCuts = 0

    /// `source` must stay valid while the chunker is used.
    init(source: UnsafeBufferPointer<UInt8>, targetBytes: Int = defaultTargetBytes, maxChunkBytes: Int = defaultMaxChunkBytes) {
        self.source = source
        self.targetBytes = max(1, targetBytes)
        self.maxChunkBytes = maxChunkBytes
        lineStarts = Self.lineStarts(source)
    }

    var isFinished: Bool { nextLine >= lineStarts.count }

    /// Lines in the source, counted like cmark: `\n`, `\r\n` and `\r` end a line.
    var lineCount: Int { lineStarts.count }

    /// The text to feed before `chunk`. A chunk after the first always gets at least one empty line:
    /// cmark drops a byte order mark on its first line, and only the file start may lose one.
    func definitionPrefix(for chunk: Chunk) -> [UInt8] {
        if definitionPrefix.isEmpty { return chunk.lines.lowerBound == 0 ? [] : [10] }
        return definitionPrefix
    }

    /// Lines in `definitionPrefix(for:)`.
    func definitionLineCount(for chunk: Chunk) -> Int {
        if definitionPrefix.isEmpty { return chunk.lines.lowerBound == 0 ? 0 : 1 }
        return definitionLineCount
    }

    mutating func next() -> Chunk? {
        guard !isFinished else { return nil }
        let start = nextLine
        var minimumBytes = targetBytes
        while true {
            let cut = candidate(after: start, minimumBytes: minimumBytes)
            let chunkBytes = lineStart(start)..<lineStart(cut)
            let isLast = cut >= lineStarts.count
            if chunkBytes.count > maxChunkBytes {
                // No safe cut close enough. The rest is shown as plain text, so memory stays bounded.
                MEGALog.log(
                    level: .warning,
                    message: "[MarkdownChunker] No safe cut within \(maxChunkBytes) bytes, rest shown as plain text. "
                        + "line=\(start) restBytes=\(source.count - lineStart(start))"
                )
                nextLine = lineStarts.count
                return Chunk(lines: start..<lineStarts.count, bytes: lineStart(start)..<source.count, isPlainText: true)
            }
            // The whole text in one chunk: nothing to learn or check.
            if start == 0 && isLast {
                nextLine = cut
                return Chunk(lines: start..<cut, bytes: chunkBytes)
            }
            let body = UnsafeBufferPointer(rebasing: source[chunkBytes])
            let labels = Self.labels(in: body)
            // A blank line after each label: an inline construct cannot join two labels' lines.
            let probe = Array(labels.map { "[\($0)]\n\n" }.joined().utf8)
            let probeLines = labels.count * 2
            let lastChunkLine = isLast ? nil : probeLines + (cut - start)
            // After a blank line only an open fence or an HTML block (type 1-5) goes on at column 0.
            // The probe checks that the last leaf block does not reach the chunk's last line.
            let result = CmarkParser.probe(prefix: probe, body: body, labelCount: labels.count, lastChunkLine: lastChunkLine)
            if result == nil && isLast {
                // cmark could not parse (no memory for a parser). The last chunk cannot grow: show it as text.
                MEGALog.log(
                    level: .warning,
                    message: "[MarkdownChunker] cmark could not parse the last chunk, shown as plain text. "
                        + "line=\(start) bytes=\(chunkBytes.count)"
                )
                nextLine = lineStarts.count
                return Chunk(lines: start..<lineStarts.count, bytes: lineStart(start)..<source.count, isPlainText: true)
            }
            guard let result, result.isSafeSplit else {
                rejectedCuts += 1
                // Grow fast, so a file with many unsafe cuts is still parsed only a few times. Near the cap, doubling
                // would skip every safe cut under it, so the next few candidates are tried one by one instead.
                let doubled = max(chunkBytes.count * 2, minimumBytes)
                if doubled <= maxChunkBytes {
                    minimumBytes = doubled
                } else if stepsAfterDoubling < Self.maxStepsAfterDoubling {
                    stepsAfterDoubling += 1
                    minimumBytes = chunkBytes.count + 1
                } else {
                    minimumBytes = doubled
                }
                continue
            }
            stepsAfterDoubling = 0
            for (label, definition) in zip(labels, result.definitions) {
                guard let definition, seenLabels.insert(Array(label.utf8)).inserted else { continue }
                addDefinition(label: label, link: definition)
            }
            nextLine = cut
            return Chunk(lines: start..<cut, bytes: chunkBytes)
        }
    }

    // MARK: - Cuts

    private func lineStart(_ line: Int) -> Int {
        line < lineStarts.count ? lineStarts[line] : source.count
    }

    /// First line after `start`, at least `minimumBytes` later, that follows a blank line and starts a new block
    /// at column 0. `lineStarts.count` when there is none.
    private func candidate(after start: Int, minimumBytes: Int) -> Int {
        var line = start + 1
        let first = lineStart(start)
        while line < lineStarts.count, lineStarts[line] - first < minimumBytes { line += 1 }
        while line < lineStarts.count {
            if isBlank(line - 1) && startsBlockAtColumnZero(line) { return line }
            line += 1
        }
        return lineStarts.count
    }

    private func isBlank(_ line: Int) -> Bool {
        var index = lineStart(line)
        let end = lineStart(line + 1)
        while index < end {
            switch source[index] {
            case 32, 9, 10, 13: index += 1
            default: return false
            }
        }
        return true
    }

    /// Not a space, not blank, not a list marker (`-`, `+`, `*` or `1.` / `1)` then a space).
    private func startsBlockAtColumnZero(_ line: Int) -> Bool {
        let start = lineStart(line)
        let end = lineStart(line + 1)
        guard start < end else { return false }
        let isSpace = { (byte: UInt8) in byte == 32 || byte == 9 || byte == 10 || byte == 13 }
        let first = source[start]
        if isSpace(first) { return false }
        let second: UInt8 = start + 1 < end ? source[start + 1] : 10
        if (first == UInt8(ascii: "-") || first == UInt8(ascii: "+") || first == UInt8(ascii: "*")) && isSpace(second) { return false }
        if first >= 48 && first <= 57 {
            var index = start
            while index < end, index - start < 9, source[index] >= 48, source[index] <= 57 { index += 1 }
            if index < end, source[index] == UInt8(ascii: ".") || source[index] == UInt8(ascii: ")") { return false }
        }
        return true
    }

    /// A UTF-8 byte order mark is skipped: cmark drops it only at the very start, and a chunk may get definitions before it.
    private static func lineStarts(_ bytes: UnsafeBufferPointer<UInt8>) -> [Int] {
        let hasBOM = bytes.count >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF
        var starts = [hasBOM ? 3 : 0]
        var index = starts[0]
        while index < bytes.count {
            if bytes[index] == 10 {
                starts.append(index + 1)
            } else if bytes[index] == 13 {
                if index + 1 < bytes.count, bytes[index + 1] == 10 { index += 1 }
                starts.append(index + 1)
            }
            index += 1
        }
        if starts.count > 1, starts.last == bytes.count { starts.removeLast() }
        return starts
    }

    // MARK: - Definitions

    /// Every `[...]:` in the chunk, the label on one line. A loose scan: cmark decides which ones are real.
    private static func labels(in bytes: UnsafeBufferPointer<UInt8>) -> [String] {
        var labels: [String] = []
        var seen = Set<[UInt8]>()
        var index = 1
        while index + 1 < bytes.count {
            defer { index += 1 }
            guard bytes[index] == UInt8(ascii: "]"), bytes[index + 1] == UInt8(ascii: ":") else { continue }
            // Back to the unescaped `[` (labels are at most 999 characters).
            var open = index - 1
            while open >= 0, index - open <= 1_000 {
                if bytes[open] == UInt8(ascii: "[") || bytes[open] == UInt8(ascii: "]") {
                    var slashes = 0
                    var before = open - 1
                    while before >= 0, bytes[before] == UInt8(ascii: "\\") {
                        slashes += 1
                        before -= 1
                    }
                    if slashes.isMultiple(of: 2) { break }
                }
                open -= 1
            }
            guard open >= 0, bytes[open] == UInt8(ascii: "["), open + 1 < index else { continue }
            var label = String(decoding: UnsafeBufferPointer(rebasing: bytes[(open + 1)..<index]), as: UTF8.self)
            label = label.replacingOccurrences(of: "\r\n", with: " ")
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
            // cmark trims only ASCII whitespace from a label. A label of other spaces (U+00A0, U+3000) is real.
            guard !label.unicodeScalars.allSatisfy(Self.isASCIIWhitespace), seen.insert(Array(label.utf8)).inserted else { continue }
            labels.append(label)
        }
        return labels
    }

    private mutating func addDefinition(label: String, link: InlineLink) {
        if !definitionPrefix.isEmpty { definitionPrefix.removeLast() }
        var line = "[\(label)]: <\(Self.escaped(link.url, special: "\\<>&"))>"
        if !link.title.isEmpty { line += " \"\(Self.escaped(link.title, special: Self.asciiPunctuation))\"" }
        line += "\n"
        let bytes = Array(line.utf8)
        definitionPrefix += bytes
        // A blank line ends the definitions, so the chunk starts a new block.
        definitionPrefix.append(10)
        // Line breaks in the URL or title are encoded, so each definition is one line. The +1 is the blank line.
        definitionTextLines += 1
        definitionLineCount = definitionTextLines + 1
    }

    /// A title can span lines. Escaping all of these keeps a line like `# x` or `- x` inside the title.
    private static let asciiPunctuation = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"

    private static func isASCIIWhitespace(_ scalar: Unicode.Scalar) -> Bool {
        scalar == " " || (scalar.value >= 0x09 && scalar.value <= 0x0D)
    }

    /// Backslash-escapes the characters that would change meaning. Works on scalars: a combining mark after `<`
    /// must not hide it. `&` becomes `&amp;`, because cmark decodes entities before backslashes, so `\&amp;`
    /// would still turn a literal `&amp;` into `&`. A decoded `&#10;` or `&#13;` goes back to its entity:
    /// a raw line break would end the definition line.
    private static func escaped(_ text: String, special: String) -> String {
        let specials = Set(special.unicodeScalars)
        var result = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if scalar == "&" {
                result.append(contentsOf: "&amp;".unicodeScalars)
            } else if scalar == "\n" {
                result.append(contentsOf: "&#10;".unicodeScalars)
            } else if scalar == "\r" {
                result.append(contentsOf: "&#13;".unicodeScalars)
            } else {
                if specials.contains(scalar) { result.append("\\") }
                result.append(scalar)
            }
        }
        return String(result)
    }
}
