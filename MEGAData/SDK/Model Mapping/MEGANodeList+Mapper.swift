

extension MEGANodeList {
    func toNodeArray() -> [MEGANode] {
        guard (size?.intValue ?? 0) > 0 else { return [] }
        return (0..<size.intValue).compactMap { node(at: $0) }
    }
    
    func toNodeEntities() -> [NodeEntity] {
        guard (size?.intValue ?? 0) > 0 else { return [] }
        return (0..<size.intValue).compactMap { node(at: $0).toNodeEntity() }
    }
}
