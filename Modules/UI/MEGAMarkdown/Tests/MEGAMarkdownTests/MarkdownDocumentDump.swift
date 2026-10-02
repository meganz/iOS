import Foundation
@testable import MEGAMarkdown

/// Plain-text form of a `MarkdownDocument` for the golden files. Every value the parser sets is in it.
enum MarkdownDocumentDump {
    static func dump(_ document: MarkdownDocument) -> String {
        var lines: [String] = []
        append(document.blocks, depth: 0, to: &lines)
        return lines.joined(separator: "\n") + "\n"
    }

    private static func append(_ blocks: [MarkdownBlock], depth: Int, to lines: inout [String]) {
        let indent = String(repeating: "  ", count: depth)
        for block in blocks {
            let head = "\(indent)#\(block.id) line=\(block.sourceLine) "
            switch block.kind {
            case .heading(let level, let text):
                lines.append(head + "heading\(level) " + runs(text))
            case .paragraph(let text):
                lines.append(head + "paragraph " + runs(text))
            case .list(let list):
                lines.append(head + "list ordered=\(list.isOrdered) start=\(list.startIndex)")
                for item in list.items {
                    lines.append("\(indent)  item checkbox=\(checkbox(item.checkbox))")
                    append(item.blocks, depth: depth + 2, to: &lines)
                }
            case .codeBlock(let language, let code):
                // One line, escaped, so CR and LF inside the code stay visible.
                lines.append(head + "code language=\(language ?? "nil") \(code.debugDescription)")
            case .blockQuote(let children):
                lines.append(head + "quote")
                append(children, depth: depth + 1, to: &lines)
            case .table(let table):
                lines.append(head + "table columns=" + table.columns.map { "\($0.alignment)" }.joined(separator: ","))
                lines.append("\(indent)  header " + table.header.map(runs).joined(separator: " | "))
                for row in table.rows {
                    lines.append("\(indent)  row " + row.map(runs).joined(separator: " | "))
                }
            case .thematicBreak:
                lines.append(head + "break")
            case .image(let url, let altText):
                lines.append(head + "image url=\(url?.absoluteString ?? "nil") alt=\(altText.debugDescription)")
            }
        }
    }

    private static func checkbox(_ checkbox: MarkdownListItem.Checkbox?) -> String {
        switch checkbox {
        case .checked: "checked"
        case .unchecked: "unchecked"
        case nil: "none"
        }
    }

    private static let intentNames: [(InlinePresentationIntent, String)] = [
        (.emphasized, "em"), (.stronglyEmphasized, "strong"), (.strikethrough, "strike"), (.code, "code"),
        (.softBreak, "soft"), (.lineBreak, "br"), (.inlineHTML, "html"), (.blockHTML, "blockhtml")
    ]

    /// Each run as `["text" flags...]`. Flags: intent names, `u`, `link=`, `img=`, `title=`.
    private static func runs(_ text: AttributedString) -> String {
        text.runs.map { run in
            var parts = [String(text[run.range].characters).debugDescription]
            let intent = run.inlinePresentationIntent ?? []
            parts += intentNames.filter { intent.contains($0.0) }.map(\.1)
            if run[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] != nil { parts.append("u") }
            if let link = run.link { parts.append("link=\(link.absoluteString)") }
            if let image = run.imageURL { parts.append("img=\(image.absoluteString)") }
            if let title = run.alternateDescription { parts.append("title=\(title.debugDescription)") }
            return "[" + parts.joined(separator: " ") + "]"
        }.joined()
    }
}
