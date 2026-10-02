/// One inline HTML style tag like `<strong>` or `</em>`.
/// The editor exporter writes these when `**`, `_`, `~~` or backticks cannot round-trip.
/// The tag names match `MarkdownImporter.htmlStyleTags` in MEGAMarkdownEditor.
struct StyleTag {
    enum Style {
        case bold
        case italic
        case strikethrough
        case code
        case underline
    }

    private static let names: [String: Style] = [
        "strong": .bold, "b": .bold, "em": .italic, "i": .italic,
        "del": .strikethrough, "s": .strikethrough, "strike": .strikethrough,
        "code": .code, "u": .underline
    ]

    /// Index of the run that holds the tag, inside one leaf block.
    let run: Int
    /// The run's link index, or -1. A tag inside link text pairs only with a tag in the same link.
    let link: Int
    let text: String
    let style: Style
    let isClosing: Bool
    var isMatched = false

    /// Reads a run made only of style tags, like `</em></strong>`.
    /// Returns no tags when the run holds any other HTML, so it stays literal.
    static func tags(in html: String, run: Int, link: Int = -1) -> [StyleTag] {
        var result: [StyleTag] = []
        var rest = Substring(html)
        while !rest.isEmpty {
            guard rest.hasPrefix("<"), let close = rest.firstIndex(of: ">") else { return [] }
            let text = String(rest[...close])
            var name = rest[rest.index(after: rest.startIndex)..<close].lowercased()
            rest = rest[rest.index(after: close)...]
            let isClosing = name.hasPrefix("/")
            if isClosing { name.removeFirst() }
            guard let style = names[name] else { return [] }
            result.append(StyleTag(run: run, link: link, text: text, style: style, isClosing: isClosing))
        }
        return result
    }

    /// Pairs each closing tag with the last open tag of the same style in the same link.
    /// A pair with nothing between its tags stays literal, like Foundation shows it.
    static func markMatchedPairs(_ tags: inout [StyleTag]) {
        struct Key: Hashable {
            let style: Style
            let link: Int
        }
        var open: [Key: [Int]] = [:]
        for index in tags.indices {
            let key = Key(style: tags[index].style, link: tags[index].link)
            if !tags[index].isClosing {
                open[key, default: []].append(index)
            } else if let opener = open[key]?.popLast() {
                // Each tag is its own cmark node, so adjacent runs mean no text between the tags.
                guard tags[index].run > tags[opener].run + 1 else { continue }
                tags[opener].isMatched = true
                tags[index].isMatched = true
            }
        }
    }
}
