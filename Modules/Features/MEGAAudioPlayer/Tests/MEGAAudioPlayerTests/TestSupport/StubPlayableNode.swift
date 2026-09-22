import MEGADomain

/// A node the player carries as an object rather than a handle — what a file link hands
/// over, and what a folder link hands over once the node is authorized.
struct StubPlayableNode: PlayableNode {
    let handle: UInt64
    var name: String? = "track.mp3"
    var parentHandle: UInt64 = 0
    var fingerprint: String?
}
