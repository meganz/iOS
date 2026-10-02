import cmark_gfm
import Foundation
@testable import MEGAMarkdown

/// The source of truth for syntax: cmark's own HTML for the same input and setup. Each wanted difference is a `Rule`
/// with its DECISIONS.md ID. Raw HTML is compared as text, with `⟨` and `⟩`, so a raw `<td>` is no table cell.
enum CmarkReference {
    struct Rule: Sendable {
        /// The ID in DECISIONS.md, like `R1`.
        let id: String
        /// An input where cmark and the walker differ only because of this rule.
        let example: String
        /// Changes cmark's HTML. R5 changes cmark's tree instead, so its `apply` does nothing.
        let apply: @Sendable (String) -> String
    }

    /// cmark's HTML for `markdown`. `CMARK_OPT_UNSAFE` keeps every URL, like the walker does.
    static func html(_ markdown: String, styleTags: Bool = true) -> String {
        var source = markdown
        let html: String? = source.withUTF8 { body in
            CmarkParser.withTree(prefix: [], body: body) { root in
                prepareRawHTML(root, styleTags: styleTags)
                guard let pointer = cmark_render_html(root, CMARK_OPT_UNSAFE, nil) else { return "" }
                defer { free(pointer) }
                return String(cString: pointer)
            }
        }
        return html ?? "PARSE FAILED"
    }

    /// The walker output for `markdown`, as HTML in cmark's format.
    static func walkerHTML(_ markdown: String) -> String {
        SpecHTML.render(CmarkParser.blocks(markdown, softBreak: .lineBreak) ?? [])
    }

    /// Nil when the walker gives the same HTML as cmark after `rules`. Otherwise both sides, in canonical form.
    static func difference(_ markdown: String, rules: [Rule] = rules) -> String? {
        var expected = withoutTaskMarkers(html(markdown, styleTags: rules.contains { $0.id == styleTagRuleID }))
        for rule in rules { expected = rule.apply(expected) }
        let expectedCanonical = SpecHTML.canonical(expected.replacingOccurrences(of: taskMark, with: ""))
        let actual = withoutTaskMarkers(walkerHTML(markdown)).replacingOccurrences(of: taskMark, with: "")
        let actualCanonical = SpecHTML.canonical(actual)
        guard expectedCanonical != actualCanonical else { return nil }
        return "expected \(expectedCanonical.debugDescription)\n  actual   \(actualCanonical.debugDescription)"
    }

    /// Stands for a task marker while the rules run, so an empty task item is not an empty item (R1).
    static let taskMark = "\u{E000}task\u{E000}"

    /// Task items have their own source of truth, and cmark's `tasklist` misses some markers. So both sides turn
    /// the checkbox, or else a leading marker and its spaces, into `taskMark`. Task tests pin the state.
    static func withoutTaskMarkers(_ html: String) -> String {
        // After a checkbox the marker is gone already, so a second marker in the text stays.
        var result = replace(#"<input type="checkbox"( checked="")? disabled="" /> ?"#, in: html, with: taskMark)
        // A marker at the line end goes with the line end, and one alone in the item stays as the mark:
        // cmark drops the spaces after it, so `[x] ` and `[x]` look the same.
        result = replace(#"<li>(\n<p>)?\[[ xX]\]([ \t]+|\n|(?=</))"#, in: result, with: "<li>$1" + taskMark)
        // Whether a marker and one image make an image block (R4) depends on the task state, so the title goes.
        let image = #"<img src="([^"]*)" alt="([^"]*)" title="[^"]*" />"#
        let template = "<li>$1" + taskMark + #"<img src="$2" alt="$3" />"#
        return replace("<li>(\n<p>)?" + taskMark + image + #"(?=</li>|</p>|\n<)"#, in: result, with: template)
    }

    // MARK: - Raw HTML and style tags

    /// The rule that works on cmark's tree.
    static let styleTagRuleID = "R5"

    /// Writes raw HTML as text (see the type comment). With `styleTags`, the tags the walker pairs become standard
    /// tags first (R5). The pairing is the walker's own `StyleTag` rule, so this checks everything around it.
    private static func prepareRawHTML(_ root: UnsafeMutablePointer<cmark_node>, styleTags: Bool) {
        guard let iterator = cmark_iter_new(root) else { return }
        defer { cmark_iter_free(iterator) }
        // Counts the walker's pieces in the current leaf block. A link or image with no pieces adds a placeholder.
        var runs = 0
        var htmlNodes: [HTMLNode] = []
        var links: [Int] = []
        var nextLink = 0
        var inlines: [(isImage: Bool, isInImage: Bool, runsAtEnter: Int)] = []
        var imageDepth = 0
        while true {
            let event = cmark_iter_next(iterator)
            if event == CMARK_EVENT_DONE { break }
            guard let node = cmark_iter_get_node(iterator) else { continue }
            let type = cmark_node_get_type(node)
            let typeName = cmark_node_get_type_string(node).map { String(cString: $0) } ?? ""
            if type == CMARK_NODE_PARAGRAPH || type == CMARK_NODE_HEADING || typeName == "table_cell" {
                if event == CMARK_EVENT_EXIT {
                    rewrite(htmlNodes, styleTags: styleTags)
                }
                runs = 0
                htmlNodes = []
                continue
            }
            switch type {
            case CMARK_NODE_TEXT, CMARK_NODE_CODE, CMARK_NODE_SOFTBREAK, CMARK_NODE_LINEBREAK:
                runs += 1
            case CMARK_NODE_HTML_INLINE:
                // Inside alt text, raw HTML is plain text on both sides.
                if imageDepth == 0 { htmlNodes.append(HTMLNode(node: node, run: runs, link: links.last ?? -1)) }
                runs += 1
            case CMARK_NODE_HTML_BLOCK:
                cmark_node_set_literal(node, asText(literal(node)))
            case CMARK_NODE_LINK, CMARK_NODE_IMAGE:
                let isImage = type == CMARK_NODE_IMAGE
                if event == CMARK_EVENT_ENTER {
                    inlines.append((isImage, imageDepth > 0, runs))
                    if !isImage, imageDepth == 0 {
                        nextLink += 1
                        links.append(nextLink)
                    }
                    if isImage { imageDepth += 1 }
                } else if let open = inlines.popLast() {
                    if !open.isInImage, runs == open.runsAtEnter { runs += 1 }
                    if isImage { imageDepth -= 1 }
                    if !isImage, !open.isInImage { links.removeLast() }
                }
            default:
                break
            }
        }
    }

    /// One raw inline HTML node, with the walker's piece index and link for it.
    private struct HTMLNode {
        let node: UnsafeMutablePointer<cmark_node>
        let run: Int
        let link: Int
    }

    /// The raw HTML of one leaf block: matched style tags become standard tags, the rest becomes text.
    private static func rewrite(_ nodes: [HTMLNode], styleTags: Bool) {
        var tags: [StyleTag] = []
        var ranges: [Range<Int>] = []
        for entry in nodes {
            let found = styleTags ? StyleTag.tags(in: literal(entry.node), run: entry.run, link: entry.link) : []
            ranges.append(tags.count..<(tags.count + found.count))
            tags += found
        }
        StyleTag.markMatchedPairs(&tags)
        for (entry, range) in zip(nodes, ranges) {
            guard !range.isEmpty else {
                cmark_node_set_literal(entry.node, asText(literal(entry.node)))
                continue
            }
            let text = tags[range].map { tag in
                tag.isMatched ? "<\(tag.isClosing ? "/" : "")\(standardName(tag.style))>" : asText(tag.text)
            }.joined()
            cmark_node_set_literal(entry.node, text)
        }
    }

    private static func standardName(_ style: StyleTag.Style) -> String {
        switch style {
        case .bold: "strong"
        case .italic: "em"
        case .strikethrough: "del"
        case .code: "code"
        case .underline: "u"
        }
    }

    /// Raw HTML as text, the same on both sides.
    static func asText(_ html: String) -> String {
        html.replacingOccurrences(of: "<", with: "\u{27E8}").replacingOccurrences(of: ">", with: "\u{27E9}")
    }

    private static func literal(_ node: UnsafeMutablePointer<cmark_node>) -> String {
        cmark_node_get_literal(node).map { String(cString: $0) } ?? ""
    }

    // MARK: - Rules

    static let rules: [Rule] = [
        Rule(id: "R1", example: "#\n\n```\n```\n\n- \n- a\n\n>\n\n1. -\n1.\n1. b\n", apply: dropEmptyBlocks),
        Rule(id: "R2", example: "```\na\n\n\n```\n", apply: { replace(#"\n\n+</code></pre>"#, in: $0, with: "\n</code></pre>") }),
        Rule(id: "R3", example: "[![alt](j.png)](k)\n", apply: altTextForImagesInLinks),
        Rule(id: "R4", example: "![a](u.png \"t\")\n\n- ![b](v.png \"t\")\n", apply: imageBlocksWithoutTitle),
        Rule(id: "R5", example: "<b>x</b> <i>y</i> <s>z</s>\n", apply: { $0 }),
        Rule(id: "R6", example: "[a <http://b.c> d](u)\n", apply: innerLinkWins)
    ]

    /// R1: a block with no content is dropped, and an ordered list starts at its first kept item.
    /// Items are marked first, because an item can become empty only after its children go.
    private static func dropEmptyBlocks(_ html: String) -> String {
        let emptyItem = "<li data-empty></li>\n"
        let removed = "\u{E000}removed\u{E000}"
        var result = html
        while true {
            var next = result
            next = replace(#"<h[1-6]></h[1-6]>\n"#, in: next, with: removed)
            next = replace(#"<pre><code( class="[^"]*")?></code></pre>\n"#, in: next, with: removed)
            next = replace("<blockquote>\n(?:\(removed))*</blockquote>\n", in: next, with: removed)
            next = replace("<li>\n?(?:\(removed))*</li>\n", in: next, with: emptyItem)
            next = replace(#"<(ul|ol)( start="\d+")?>\n(<li data-empty></li>\n)+</(ul|ol)>\n"#, in: next, with: removed)
            next = replace(#"<tr>\n(<td( align="\w+")?></td>\n)+</tr>\n"#, in: next, with: "")
            next = replace(#"<tbody>\n</tbody>\n"#, in: next, with: "")
            if next == result { break }
            result = next
        }
        result = renumberOrderedLists(result)
        result = result.replacingOccurrences(of: emptyItem, with: "")
        // `removed` marks a dropped block. The walker's item starts with its text, without cmark's newline before it.
        result = replace("<li>\n(?:\(removed))+" + #"(?=[^<\n\u27E8 \t\uE000])"#, in: result, with: "<li>")
        return result.replacingOccurrences(of: removed, with: "")
    }

    /// `<ol start="3">` with two empty items first becomes `<ol start="5">`.
    private static func renumberOrderedLists(_ html: String) -> String {
        let pattern = try! NSRegularExpression(pattern: #"<ol( start="(\d+)")?>\n((?:<li data-empty></li>\n)+)"#)
        var result = html
        while let match = pattern.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)),
              let whole = Range(match.range, in: result), let items = Range(match.range(at: 3), in: result) {
            let start = Range(match.range(at: 2), in: result).flatMap { Int(result[$0]) } ?? 1
            let newStart = start + result[items].components(separatedBy: "</li>").count - 1
            result.replaceSubrange(whole, with: newStart == 1 ? "<ol>\n" : "<ol start=\"\(newStart)\">\n")
        }
        return result
    }

    /// R3: an image inside a link keeps only its alt text.
    private static func altTextForImagesInLinks(_ html: String) -> String {
        let link = try! NSRegularExpression(pattern: #"<a [^>]*>.*?</a>"#, options: [.dotMatchesLineSeparators])
        var result = ""
        var last = html.startIndex
        for match in link.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
            guard let range = Range(match.range, in: html) else { continue }
            result += html[last..<range.lowerBound]
            result += replace(#"<img src="[^"]*" alt="([^"]*)"( title="[^"]*")? />"#, in: String(html[range]), with: "$1")
            last = range.upperBound
        }
        return result + html[last...]
    }

    /// R4: a paragraph of one image is an image block, and it has no title. In a tight list item there is
    /// no `<p>`, so the image fills the item up to `</li>` or a child block.
    private static func imageBlocksWithoutTitle(_ html: String) -> String {
        let image = #"<img src="([^"]*)" alt="([^"]*)" title="[^"]*" />"#
        let inParagraph = replace("<p>" + image + "</p>", in: html, with: #"<p><img src="$1" alt="$2" /></p>"#)
        let childBlock = #"(?=</li>|\n<(ul|ol|blockquote|pre|table|h[1-6]|hr|p)\b)"#
        return replace("<li>" + image + childBlock, in: inParagraph, with: #"<li><img src="$1" alt="$2" />"#)
    }

    /// R6: a link inside a link keeps only the inner link. cmark nests an autolink inside link text.
    private static func innerLinkWins(_ html: String) -> String {
        let token = try! NSRegularExpression(pattern: #"<a [^>]*>|</a>"#)
        var result = ""
        var open: [String] = []
        var last = html.startIndex
        for match in token.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
            guard let range = Range(match.range, in: html) else { continue }
            result += html[last..<range.lowerBound]
            let tag = String(html[range])
            if tag == "</a>" {
                if !open.isEmpty { open.removeLast() }
                result += "</a>" + (open.last ?? "")
            } else {
                if !open.isEmpty { result += "</a>" }
                open.append(tag)
                result += tag
            }
            last = range.upperBound
        }
        return result + html[last...]
    }

    static func replace(_ pattern: String, in text: String, with template: String) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        return regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
    }
}
