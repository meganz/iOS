import MEGASdk

extension MEGANode: PlayableNode {
    public var nodeName: String {
        name ?? ""
    }
}
