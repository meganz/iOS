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
            nodeAt($0)?.isVisualMediaFile ?? false
        }
    }
    
    public func containsOnlyVisualMedia() -> Bool {
        guard nodesCount > 0 else { return false }
        return (0..<nodesCount).notContains {
            guard let node = nodeAt($0) else {
                return false
            }
            return !node.isVisualMediaFile
        }
    }
}

private extension NodeEntity {
    /// A folder can carry an image or video extension in its name, so the name alone doesn't make it media
    var isVisualMediaFile: Bool {
        isFile && name.fileExtensionGroup.isVisualMedia
    }
}
