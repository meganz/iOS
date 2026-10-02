import cmark_gfm
@testable import MEGAMarkdown

// MARK: - Debug tree

extension CmarkParser {
    /// The whole cmark tree as text, one string per top-level block: types, literals, URLs, titles,
    /// list type, start and tightness, heading level, fence info and block lines. For tests only.
    static func debugTree(prefix: [UInt8], body: UnsafeBufferPointer<UInt8>, lineOffset: Int) -> [String] {
        withTree(prefix: prefix, body: body) { root in
            var result: [String] = []
            var top = cmark_node_first_child(root)
            while let node = top {
                result.append(debugText(node, lineOffset: lineOffset))
                top = cmark_node_next(node)
            }
            return result
        } ?? ["PARSE FAILED"]
    }

    private static func debugText(_ top: UnsafeMutablePointer<cmark_node>, lineOffset: Int) -> String {
        guard let iterator = cmark_iter_new(top) else { return "" }
        defer { cmark_iter_free(iterator) }
        var out = ""
        while true {
            let event = cmark_iter_next(iterator)
            if event == CMARK_EVENT_DONE { break }
            guard let node = cmark_iter_get_node(iterator) else { continue }
            if event == CMARK_EVENT_EXIT {
                out += ")"
                continue
            }
            let type = cmark_node_get_type(node)
            out += "(" + string(cmark_node_get_type_string(node))
            if type.rawValue & UInt32(CMARK_NODE_TYPE_MASK) == UInt32(CMARK_NODE_TYPE_BLOCK) {
                let line = Int(cmark_node_get_start_line(node))
                out += line == 0 ? "@?" : "@\(line - 1 + lineOffset)"
            }
            switch type {
            case CMARK_NODE_TEXT, CMARK_NODE_CODE, CMARK_NODE_HTML_INLINE, CMARK_NODE_HTML_BLOCK:
                out += " " + string(cmark_node_get_literal(node)).debugDescription
            case CMARK_NODE_CODE_BLOCK:
                out += " " + string(cmark_node_get_literal(node)).debugDescription + " info=" + string(cmark_node_get_fence_info(node))
            case CMARK_NODE_LINK, CMARK_NODE_IMAGE:
                out += " url=" + string(cmark_node_get_url(node)) + " title=" + string(cmark_node_get_title(node))
            case CMARK_NODE_HEADING:
                out += " h\(cmark_node_get_heading_level(node))"
            case CMARK_NODE_LIST:
                out += " t\(cmark_node_get_list_type(node).rawValue) s\(cmark_node_get_list_start(node)) tight\(cmark_node_get_list_tight(node))"
            default:
                break
            }
            // Leaf nodes get no exit event.
            if cmark_node_first_child(node) == nil { out += ")" }
        }
        return out
    }
}
