import MEGADomain

public struct MockPlayableNode: PlayableNode {
    public let handle: UInt64
    public let name: String?
    public let parentHandle: UInt64
    public let fingerprint: String?

    public init(
        handle: UInt64 = 0,
        name: String,
        parentHandle: UInt64 = 0,
        fingerprint: String? = nil
    ) {
        self.handle = handle
        self.name = name
        self.parentHandle = parentHandle
        self.fingerprint = fingerprint
    }
}
