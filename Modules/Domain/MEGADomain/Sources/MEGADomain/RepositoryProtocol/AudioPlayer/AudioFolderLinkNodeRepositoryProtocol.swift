import Foundation

public protocol AudioFolderLinkNodeRepositoryProtocol: RepositoryProtocol, Sendable {
    /// The folder-link node with this handle as it is now, authorized against the
    /// folder-link tree so it can be streamed and acted on. `nil` once it has gone.
    func authorizedNode(forHandle handle: HandleEntity) -> (any PlayableNode)?
}
