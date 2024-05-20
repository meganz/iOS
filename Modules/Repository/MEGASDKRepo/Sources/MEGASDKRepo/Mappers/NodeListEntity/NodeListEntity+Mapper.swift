import MEGADomain
import MEGASdk

extension MEGANodeList {
    public func toNodeListEntity() -> NodeListEntity {
        .init(
            nodesCount: self.size,
            nodeAt: { self.node(at: $0)?.toNodeEntity() ?? nil }
        )
    }
}

extension NodeListEntity {
    public static var emptyNodeList: Self {
        .init(nodesCount: 0, nodeAt: { _ in nil })
    }
}
