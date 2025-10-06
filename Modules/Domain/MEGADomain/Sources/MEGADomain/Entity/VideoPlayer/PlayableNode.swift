public protocol PlayableNode: Sendable {
    var handle: UInt64 { get }
    var id: String { get }
    var name: String? { get }
    var parentHandle: UInt64 { get }
}
