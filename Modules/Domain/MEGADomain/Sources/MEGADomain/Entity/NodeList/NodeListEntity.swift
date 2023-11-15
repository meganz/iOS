public struct NodeListEntity: @unchecked Sendable {
    public let nodesCount: Int
    public let nodeAt: ((Int) -> NodeEntity?)

    public init(nodesCount: Int, nodeAt: @escaping ((Int) -> NodeEntity?)) {
        self.nodeAt = nodeAt
        self.nodesCount = nodesCount
    }
}
