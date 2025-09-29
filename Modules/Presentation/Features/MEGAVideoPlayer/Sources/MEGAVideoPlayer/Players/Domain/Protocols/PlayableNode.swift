public protocol PlayableNode: Sendable {
    var nodeHandle: UInt64 { get }
    var id: String { get }
    var nodeName: String { get }
    var nodeParentHandle: UInt64 { get }
}
