import MEGAVideoPlayer

public struct MockPlayableNode: PlayableNode {
    public let id: String
    public let nodeHandle: UInt64
    public let nodeName: String
    public let nodeParentHandle: UInt64

    public init(
        id: String = "",
        nodeHandle: UInt64 = 0,
        nodeName: String,
        nodeParentHandle: UInt64 = 0,
    ) {
        self.id = id
        self.nodeHandle = nodeHandle
        self.nodeName = nodeName
        self.nodeParentHandle = nodeParentHandle
    }
}
