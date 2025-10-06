import MEGADomain

public struct MockPlayableNode: PlayableNode {
    public let id: String
    public let handle: UInt64
    public let name: String?
    public let parentHandle: UInt64

    public init(
        id: String = "",
        handle: UInt64 = 0,
        name: String,
        parentHandle: UInt64 = 0,
    ) {
        self.id = id
        self.handle = handle
        self.name = name
        self.parentHandle = parentHandle
    }
}
