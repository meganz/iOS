/// How a soft break (a single newline inside a paragraph) is shown.
///
/// Both kinds of break keep a marker in the inline text, so a consumer (for example an editor
/// that writes Markdown back) can tell them apart:
/// - a soft break run has `inlinePresentationIntent` containing `.softBreak` ("\n" or " ").
/// - a hard break run ("\n") has `inlinePresentationIntent` containing `.lineBreak`.
public enum MarkdownSoftBreak: Sendable {
    /// Keep the line break from the source. Android preview does this (like Obsidian).
    case lineBreak
    /// Join the lines with a space. This is the CommonMark default.
    case space
}
