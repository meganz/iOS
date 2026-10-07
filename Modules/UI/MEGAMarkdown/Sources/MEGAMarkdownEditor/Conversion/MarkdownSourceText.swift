import Foundation

/// A Markdown file split into what the blocks hold and what `RichFileFormat` holds.
struct MarkdownSourceText {
    /// The text with "\n" line ends, without the byte order mark and without the last line end.
    let body: String
    let format: RichFileFormat

    init(_ markdown: String) {
        var text = markdown
        var format = RichFileFormat(lineEnding: RichLineEnding.detect(in: markdown))
        if text.unicodeScalars.first == "\u{FEFF}" {
            text.unicodeScalars.removeFirst()
            format.hasByteOrderMark = true
        }
        // Swift treats "\r\n" as one Character, so line splitting needs plain "\n" ends.
        if text.utf8.contains(13) {
            text = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        }
        format.endsWithLineEnding = text.utf8.last == 10
        if format.endsWithLineEnding {
            text.removeLast()
        }
        body = text
        self.format = format
    }

    /// The file bytes for `body`, with the line ending, the byte order mark and the last line end put back.
    static func file(body: String, format: RichFileFormat) -> String {
        var text = body
        // An empty body writes an empty file, not a lone line end.
        if format.endsWithLineEnding && !text.isEmpty {
            text += "\n"
        }
        if format.lineEnding != .lf {
            text = text.replacingOccurrences(of: "\n", with: format.lineEnding.text)
        }
        return format.hasByteOrderMark ? "\u{FEFF}" + text : text
    }
}
