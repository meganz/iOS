public struct NodeListEntity: Sendable {
    public let nodesCount: Int
    public let nodeAt: (@Sendable (Int) -> NodeEntity?)

    public init(nodesCount: Int, nodeAt: @escaping (@Sendable (Int) -> NodeEntity?)) {
        self.nodeAt = nodeAt
        self.nodesCount = nodesCount
    }
}
