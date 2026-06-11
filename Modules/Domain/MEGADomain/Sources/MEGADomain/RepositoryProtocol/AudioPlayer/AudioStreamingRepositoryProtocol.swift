import Foundation

/// A node to stream, tagged with the context that decides how it is resolved
/// and authorized before the local HTTP server serves it.
public enum StreamingNode: Sendable {
    /// Cloud / chat / search node — owned by the account, streamed without authorization.
    case account(any PlayableNode)
    /// Folder-link node — authorized against the folder-link SDK before streaming.
    case folderLink(any PlayableNode)
    /// File-link node — a standalone public node already resolved upstream, streamed directly.
    case fileLink(any PlayableNode)
}

public protocol AudioStreamingRepositoryProtocol: RepositoryProtocol, Sendable {
    var isServerRunning: Bool { get }
    func startServer()
    func stopServer()
    func streamingURL(for node: StreamingNode) -> URL?
}
