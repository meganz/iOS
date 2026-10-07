import MEGAMarkdown

/// Writes `RichText` as inline Markdown: escapes plain text and nests style markers.
///
/// CommonMark emphasis has "flanking" rules, so some style mixes cannot be written with `*` or `~~`
/// (for example bold around code in the middle of a word). So the writer parses its output again.
/// When the styles differ, it writes HTML tags (`<strong>`, `<em>`, `<del>`, `<code>`), which have no flanking rules.
enum InlineWriter {
    /// Where the text goes. It sets the prefix of continuation lines and what must be escaped.
    enum Context: Hashable, Sendable {
        case paragraph
        /// Continuation lines start with this many spaces.
        case listItem(continuationIndent: Int)
        /// Continuation lines start with `prefix`, for example "> > ".
        case quote(prefix: String)
        /// One line: breaks become spaces, and `#` is escaped.
        case atxHeading
        /// Keeps its breaks. The exporter writes the `===` or `---` line.
        case setextHeading

        var continuationPrefix: String {
            switch self {
            case .listItem(let indent): String(repeating: " ", count: indent)
            case .quote(let prefix): prefix
            case .paragraph, .atxHeading, .setextHeading: ""
            }
        }
    }

    /// True when the text writes nothing. A space inside a link or code span is written, so that text is not blank.
    static func isBlank(_ text: RichText) -> Bool {
        let isWhitespace = text.text.unicodeScalars.allSatisfy { $0 == " " || $0 == "\t" || $0 == "\n" || $0 == "\u{2028}" }
        return isWhitespace && InlineTextCleaner.cleaned(text, joinsLines: false).isEmpty
    }

    /// `roundTrips` is false when no writing parses back to the same styles. The text is then written with markers anyway.
    static func write(_ text: RichText, context: Context) -> (markdown: String, roundTrips: Bool) {
        let expected = InlineTextCleaner.cleaned(text, joinsLines: context == .atxHeading)
        // Plain text has no markers, so there is nothing to check. This keeps saving fast.
        if expected.spans.isEmpty {
            return (InlineMarkupWriter(text: expected, context: context, usesHTML: false).write(), true)
        }
        for usesHTML in [false, true] {
            let check = InlineMarkupWriter(text: expected, context: .paragraph, usesHTML: usesHTML).write()
            if parsesBack(check, to: expected) {
                return (InlineMarkupWriter(text: expected, context: context, usesHTML: usesHTML).write(), true)
            }
        }
        return (InlineMarkupWriter(text: expected, context: context, usesHTML: false).write(), false)
    }

    private static func parsesBack(_ markdown: String, to expected: RichText) -> Bool {
        guard let blocks = CmarkParser.editorBlocks(markdown)?.blocks else { return false }
        guard let first = blocks.first else { return expected.isEmpty }
        guard blocks.count == 1, case .paragraph(let inline) = first.kind,
              let parsed = RichBlockConversion.richText(from: inline) else { return false }
        return parsed == expected
    }
}
