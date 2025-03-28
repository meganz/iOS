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
    
    public func containsVisualMedia() -> Bool {
        guard nodesCount > 0 else { return false }
        return (0..<nodesCount).contains {
            nodeAt($0)?.name.fileExtensionGroup.isVisualMedia ?? false
        }
    }
    
    public func containsOnlyVisualMedia() -> Bool {
        guard nodesCount > 0 else { return false }
        return (0..<nodesCount).notContains {
            guard let nodeName = nodeAt($0)?.name else {
                return false
            }
            return !nodeName.fileExtensionGroup.isVisualMedia
        }
    }
}
