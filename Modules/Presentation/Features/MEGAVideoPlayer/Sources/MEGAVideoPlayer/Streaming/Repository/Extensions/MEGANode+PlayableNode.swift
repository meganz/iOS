import MEGASdk

extension MEGANode: PlayableNode {
    public var id: String {
        return String(handle)
    }

    public var nodeName: String {
        name ?? ""
    }
}
