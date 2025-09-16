import MEGAVideoPlayer

public struct MockPlayableNode: PlayableNode {
    public let id: String
    public let nodeName: String

    public init(id: String = "", nodeName: String) {
        self.id = id
        self.nodeName = nodeName
    }
}
