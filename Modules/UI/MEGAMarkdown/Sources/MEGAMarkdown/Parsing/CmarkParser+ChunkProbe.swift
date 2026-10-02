import cmark_gfm

// MARK: - Chunk probe

extension CmarkParser {
    /// Result of parsing one chunk with probe paragraphs `[label 1]`, blank line, `[label 2]`... in front.
    struct ProbeResult {
        /// False when the last leaf block reaches the chunk's last line (an open fence or HTML block, for example).
        var isSafeSplit: Bool
        /// One entry per probe label: the chunk's own definition for it, or nil.
        var definitions: [InlineLink?]
    }

    /// `lastChunkLine` is the 1-based line of the chunk's last (blank) line in the parsed text, or nil for the last chunk.
    static func probe(prefix: [UInt8], body: UnsafeBufferPointer<UInt8>, labelCount: Int, lastChunkLine: Int?) -> ProbeResult? {
        withTree(prefix: prefix, body: body) { root in
            if let lastChunkLine, let leaf = lastLeaf(root), Int(cmark_node_get_end_line(leaf)) >= lastChunkLine {
                return ProbeResult(isSafeSplit: false, definitions: [])
            }
            // One probe paragraph per label, in order. A label's paragraph that is exactly one link is a definition.
            var definitions: [InlineLink?] = []
            var node = cmark_node_first_child(root)
            while definitions.count < labelCount, let paragraph = node {
                definitions.append(probeLink(paragraph))
                node = cmark_node_next(paragraph)
            }
            while definitions.count < labelCount { definitions.append(nil) }
            return ProbeResult(isSafeSplit: true, definitions: definitions)
        }
    }

    /// The last leaf block: goes down through lists, items and quotes.
    /// A list's own end line can cover blank lines after it, so the list itself is not checked.
    private static func lastLeaf(_ root: UnsafeMutablePointer<cmark_node>) -> UnsafeMutablePointer<cmark_node>? {
        guard var node = cmark_node_last_child(root) else { return nil }
        while [CMARK_NODE_LIST, CMARK_NODE_ITEM, CMARK_NODE_BLOCK_QUOTE].contains(cmark_node_get_type(node)),
              let child = cmark_node_last_child(node) {
            node = child
        }
        return node
    }

    private static func probeLink(_ paragraph: UnsafeMutablePointer<cmark_node>) -> InlineLink? {
        guard cmark_node_get_type(paragraph) == CMARK_NODE_PARAGRAPH,
              let link = cmark_node_first_child(paragraph),
              cmark_node_next(link) == nil,
              cmark_node_get_type(link) == CMARK_NODE_LINK else { return nil }
        return InlineLink(url: string(cmark_node_get_url(link)), title: string(cmark_node_get_title(link)))
    }
}
