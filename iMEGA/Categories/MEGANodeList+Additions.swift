

extension MEGANodeList {
    var nodes: [MEGANode] {
        guard (size?.intValue ?? 0) > 0 else { return [] }
        return (0..<size.intValue).compactMap({ node(at: $0) })
    }
}
