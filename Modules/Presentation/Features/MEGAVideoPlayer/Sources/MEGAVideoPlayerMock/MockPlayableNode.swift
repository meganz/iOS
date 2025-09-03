import MEGAVideoPlayer

public struct MockPlayableNode: PlayableNode {
    public let nodeName: String

    public init(nodeName: String) {
        self.nodeName = nodeName
    }
}
