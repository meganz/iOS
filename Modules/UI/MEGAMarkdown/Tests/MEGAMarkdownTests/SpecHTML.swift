import Foundation
@testable import MEGAMarkdown

/// Renders the walker output as HTML in cmark's format (`src/html.c`, `extensions/table.c`), so a
/// spec example's expected HTML can be compared with it. `canonical` removes the differences that
/// do not come from the walker (tag order, split runs, tight lists). Test code only.
enum SpecHTML {
    static func render(_ blocks: [ParsedBlock]) -> String {
        var writer = Writer()
        writer.blocks(blocks)
        return writer.out
    }

    // MARK: - Canonical form

    /// Inline tags in the order they are written. Flattened runs lose the nesting order, so both sides use this one.
    private static let inlineOrder = ["a", "strong", "em", "del", "u", "code"]
    /// Block tags cmark's renderer writes. Any other tag is raw HTML from the input, so it is text.
    private static let blockTags: Set<String> = [
        "p", "h1", "h2", "h3", "h4", "h5", "h6", "ul", "ol", "li", "blockquote", "pre", "table", "thead", "tbody", "tr", "th", "td", "hr"
    ]

    /// Same inline tree, different tag order or run split: same string.
    /// A tag nested in itself (`<em><em>a</em></em>`) counts once, because the model keeps styles as an `OptionSet`.
    /// `<p>` directly inside `<li>` is removed, because the model has no tight/loose flag.
    /// ` align="left"` is removed, because the walker maps "none" to left (both draw the same).
    /// An empty cell has no alignment, because cmark writes none on a cell it adds to a short row.
    static func canonical(_ html: String) -> String {
        var scanner = Canonicalizer()
        scanner.scan(html)
        let result = scanner.out
            .replacingOccurrences(of: " align=\"left\"", with: "")
            .replacingOccurrences(of: #"\n+</li>"#, with: "</li>", options: .regularExpression)
        return result.replacingOccurrences(of: #"<(t[dh]) align="\w+"></t[dh]>"#, with: "<$1></$1>", options: .regularExpression)
    }

    private struct Canonicalizer {
        var out = ""
        private var blockStack: [String] = []
        private var styles: [String] = []
        private var runs: [(styles: [String], text: String)] = []
        /// True right after `<li>`, before any other block tag. Only there does a loose `<p>` follow a newline that tight output lacks.
        private var justOpenedItem = false

        mutating func scan(_ html: String) {
            var index = html.startIndex
            while index < html.endIndex {
                if html[index] == "<", let (tag, after) = Self.tag(in: html, at: index) {
                    if inlineOrder.contains(tag.name), !tag.isClosing, !Self.hasClosingTag(tag.name, in: html, from: after) {
                        appendText(tag.raw)
                    } else {
                        consume(tag)
                    }
                    index = after
                } else {
                    appendText(String(html[index]))
                    index = html.index(after: index)
                }
            }
            flush()
        }

        /// `(name, isClosing, attributes, raw)` of the tag at `index`, or nil when it is not a tag.
        private struct Tag {
            var name: String
            var isClosing: Bool
            var attributes: String
            var raw: String
        }

        private static func tag(in html: String, at index: String.Index) -> (Tag, String.Index)? {
            guard let close = html[index...].firstIndex(of: ">") else { return nil }
            let raw = String(html[index...close])
            var body = raw.dropFirst().dropLast()
            let isClosing = body.hasPrefix("/")
            if isClosing { body = body.dropFirst() }
            let name = String(body.prefix { $0.isLetter || $0.isNumber }).lowercased()
            guard !name.isEmpty, name.first?.isLetter == true else { return nil }
            var attributes = String(body.dropFirst(name.count))
            if attributes.hasSuffix("/") { attributes.removeLast() }
            attributes = attributes.trimmingCharacters(in: .whitespaces)
            return (Tag(name: name, isClosing: isClosing, attributes: attributes, raw: raw), html.index(after: close))
        }

        /// True when `</name>` closes the tag before the next block tag.
        private static func hasClosingTag(_ name: String, in html: String, from start: String.Index) -> Bool {
            var depth = 0
            var index = start
            while let open = html[index...].firstIndex(of: "<") {
                guard let (tag, after) = Self.tag(in: html, at: open) else {
                    index = html.index(after: open)
                    continue
                }
                if blockTags.contains(tag.name) { return false }
                if tag.name == name {
                    if !tag.isClosing {
                        depth += 1
                    } else if depth == 0 {
                        return true
                    } else {
                        depth -= 1
                    }
                }
                index = after
            }
            return false
        }

        private mutating func consume(_ tag: Tag) {
            guard inlineOrder.contains(tag.name) || blockTags.contains(tag.name) else {
                // Raw HTML from the input, and `br`, `img` and `input`, which hold no text.
                appendText(tag.raw)
                return
            }
            if inlineOrder.contains(tag.name) {
                if tag.isClosing {
                    if let open = styles.lastIndex(where: { $0 == tag.name || $0.hasPrefix(tag.name + " ") }) {
                        styles.remove(at: open)
                    } else {
                        appendText(tag.raw)
                    }
                } else {
                    styles.append(tag.attributes.isEmpty ? tag.name : tag.name + " " + tag.attributes)
                }
                return
            }
            if tag.name == "p", blockStack.last == "li" {
                // Loose `<li>\n<p>a</p>\n</li>` becomes tight `<li>a</li>`.
                if !tag.isClosing, justOpenedItem, let last = runs.indices.last, runs[last].text.hasSuffix("\n") {
                    runs[last].text.removeLast()
                }
                if !tag.isClosing { justOpenedItem = false }
                return
            }
            flush()
            styles = []
            justOpenedItem = tag.name == "li" && !tag.isClosing
            if tag.isClosing {
                if blockStack.last == tag.name { blockStack.removeLast() }
            } else if !tag.raw.hasSuffix("/>") {
                blockStack.append(tag.name)
            }
            out += tag.raw
        }

        private mutating func appendText(_ text: String) {
            // Sorted, so runs with the same styles merge whatever order the tags were written in.
            var unique: [String] = []
            for style in styles.sorted(by: { rank($0) < rank($1) }) where !unique.contains(style) { unique.append(style) }
            if let last = runs.indices.last, runs[last].styles == unique {
                runs[last].text += text
            } else {
                runs.append((unique, text))
            }
        }

        private mutating func flush() {
            for run in runs where !run.text.isEmpty {
                let ordered = run.styles.sorted { rank($0) < rank($1) }
                for style in ordered { out += "<\(style)>" }
                out += run.text
                for style in ordered.reversed() { out += "</\(name(of: style))>" }
            }
            runs = []
        }

        private func name(of style: String) -> String {
            String(style.prefix { $0 != " " })
        }

        private func rank(_ style: String) -> Int {
            inlineOrder.firstIndex(of: name(of: style)) ?? inlineOrder.count
        }
    }

    // MARK: - Renderer

    private struct Writer {
        var out = ""

        /// cmark's `cmark_html_render_cr`: a newline unless the output already ends with one.
        private mutating func cr() {
            if !out.isEmpty, !out.hasSuffix("\n") { out += "\n" }
        }

        mutating func blocks(_ blocks: [ParsedBlock]) {
            for block in blocks { self.block(block) }
        }

        private mutating func block(_ block: ParsedBlock) {
            switch block.kind {
            case .heading(let level, let text):
                cr()
                out += "<h\(level)>"
                inlines(text)
                out += "</h\(level)>\n"
            case .paragraph(let text):
                if text.runs.count == 1, text.runs[0].style.contains(.blockHTML) {
                    cr()
                    out += CmarkReference.asText(text.text)
                    cr()
                } else {
                    cr()
                    out += "<p>"
                    inlines(text)
                    out += "</p>\n"
                }
            case .list(let list):
                cr()
                if !list.isOrdered {
                    out += "<ul>\n"
                } else if list.startIndex == 1 {
                    out += "<ol>\n"
                } else {
                    out += "<ol start=\"\(list.startIndex)\">\n"
                }
                for item in list.items { self.item(item) }
                out += list.isOrdered ? "</ol>\n" : "</ul>\n"
            case .codeBlock(let language, let code):
                cr()
                if let language {
                    // cmark ends the first word at an ASCII space, not at U+00A0.
                    let firstWord = language.prefix { !" \t\n\r\u{0B}\u{0C}".contains($0) }
                    out += "<pre><code class=\"language-\(SpecHTML.escape(String(firstWord)))\">"
                } else {
                    out += "<pre><code>"
                }
                // The walker strips the trailing newline; cmark keeps one.
                out += SpecHTML.escape(code + "\n")
                out += "</code></pre>\n"
            case .blockQuote(let children):
                cr()
                out += "<blockquote>\n"
                blocks(children)
                cr()
                out += "</blockquote>\n"
            case .table(let table):
                self.table(table)
            case .thematicBreak:
                cr()
                out += "<hr />\n"
            case .image(let url, let altText):
                cr()
                out += "<p><img src=\"\(SpecHTML.escapeHref(url ?? ""))\" alt=\"\(SpecHTML.escape(altText))\" /></p>\n"
            }
        }

        private mutating func item(_ item: ParsedListItem) {
            cr()
            out += "<li>"
            switch item.checkbox {
            case .checked: out += "<input type=\"checkbox\" checked=\"\" disabled=\"\" /> "
            case .unchecked: out += "<input type=\"checkbox\" disabled=\"\" /> "
            case nil: break
            }
            blocks(item.blocks)
            out += "</li>\n"
        }

        private mutating func table(_ table: ParsedTable) {
            cr()
            out += "<table>"
            cr()
            out += "<thead>"
            row(table.header, columns: table.columns, cellTag: "th")
            cr()
            out += "</thead>"
            for (index, cells) in table.rows.enumerated() {
                if index == 0 {
                    cr()
                    out += "<tbody>"
                }
                row(cells, columns: table.columns, cellTag: "td")
            }
            if !table.rows.isEmpty {
                cr()
                out += "</tbody>"
            }
            cr()
            out += "</table>"
            cr()
        }

        private mutating func row(_ cells: [InlineText], columns: [MarkdownTable.Column], cellTag: String) {
            cr()
            out += "<tr>"
            for (cell, column) in zip(cells, columns) {
                cr()
                out += "<\(cellTag)"
                switch column.alignment {
                case .left: out += " align=\"left\""
                case .center: out += " align=\"center\""
                case .right: out += " align=\"right\""
                case .none: break
                }
                out += ">"
                inlines(cell)
                out += "</\(cellTag)>"
            }
            cr()
            out += "</tr>"
        }

        private mutating func inlines(_ text: InlineText) {
            var start = text.text.utf8.startIndex
            for run in text.runs {
                let end = text.text.utf8.index(text.text.utf8.startIndex, offsetBy: run.end)
                let runText = String(text.text[start..<end])
                start = end
                let link = run.link >= 0 ? text.links[run.link] : nil
                // U+FFFC placeholders keep a block alive in the model. They are not author text.
                // An image placeholder is still an image, with empty alt text, as cmark writes it.
                let isPlaceholder = run.style.contains(.placeholder)
                if isPlaceholder, !run.style.contains(.image) { continue }
                let piece = isPlaceholder ? "" : runText
                let open = Self.openTags(run.style, link: link)
                for tag in open { out += "<\(tag)>" }
                if let link, run.style.contains(.image) {
                    out += "<img src=\"\(SpecHTML.escapeHref(link.url))\" alt=\"\(SpecHTML.escape(piece))\""
                    if !link.title.isEmpty { out += " title=\"\(SpecHTML.escape(link.title))\"" }
                    out += " />"
                } else if run.style.contains(.lineBreak) {
                    // Equal neighbour runs merge, so one run can hold several breaks.
                    out += String(repeating: "<br />\n", count: max(1, piece.filter { $0 == "\n" }.count))
                } else if run.style.contains(.softBreak) {
                    out += "\n"
                } else if run.style.contains(.inlineHTML) || run.style.contains(.blockHTML) {
                    out += CmarkReference.asText(piece)
                } else {
                    out += SpecHTML.escape(piece)
                }
                for tag in open.reversed() { out += "</\(tag.prefix { $0 != " " })>" }
            }
        }

        /// Opening tags of one run, outer to inner, in the same order `canonical` uses.
        private static func openTags(_ style: InlineStyle, link: InlineLink?) -> [String] {
            var open: [String] = []
            if let link, !style.contains(.image) {
                var tag = "a href=\"\(SpecHTML.escapeHref(link.url))\""
                if !link.title.isEmpty { tag += " title=\"\(SpecHTML.escape(link.title))\"" }
                open.append(tag)
            }
            if style.contains(.stronglyEmphasized) { open.append("strong") }
            if style.contains(.emphasized) { open.append("em") }
            if style.contains(.strikethrough) { open.append("del") }
            if style.contains(.underline) { open.append("u") }
            if style.contains(.code) { open.append("code") }
            return open
        }
    }

    // MARK: - Escaping (cmark `houdini_html_e.c`, `houdini_href_e.c`)

    static func escape(_ text: String) -> String {
        var result = ""
        for character in text {
            switch character {
            case "\"": result += "&quot;"
            case "&": result += "&amp;"
            case "<": result += "&lt;"
            case ">": result += "&gt;"
            default: result.append(character)
            }
        }
        return result
    }

    /// Bytes cmark leaves as they are in an `href`: alphanumerics and `-_.+!*'(),%#@?=;:/,+&$~`.
    private static let hrefSafe: Set<UInt8> = {
        var safe = Set("-_.+!*'(),%#@?=;:/,+&$~".utf8)
        safe.formUnion(UInt8(ascii: "0")...UInt8(ascii: "9"))
        safe.formUnion(UInt8(ascii: "a")...UInt8(ascii: "z"))
        safe.formUnion(UInt8(ascii: "A")...UInt8(ascii: "Z"))
        return safe
    }()

    static func escapeHref(_ url: String) -> String {
        var result = ""
        for byte in url.utf8 {
            if byte == UInt8(ascii: "&") {
                result += "&amp;"
            } else if byte == UInt8(ascii: "'") {
                result += "&#x27;"
            } else if hrefSafe.contains(byte) {
                result.append(Character(UnicodeScalar(byte)))
            } else {
                result += String(format: "%%%02X", byte)
            }
        }
        return result
    }
}
