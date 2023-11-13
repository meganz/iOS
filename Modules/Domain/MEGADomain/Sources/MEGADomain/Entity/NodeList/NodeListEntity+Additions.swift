public extension NodeListEntity {
    func toNodeEntities() -> [NodeEntity] {
        guard nodesCount > 0 else { return [] }
        return (0..<nodesCount).compactMap { nodeAt($0) }
    }
}
