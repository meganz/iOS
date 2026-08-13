import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import MEGASwift

/// Holds on to what a file link resolved to: the `MEGANode`, and the link that produced it.
///
/// A public link node is not part of the account tree, so `MEGASdk` cannot look it up by handle: the
/// file attribute requests that load a preview have to carry the node object the link resolution
/// handed back. `ThumbnailRepository` reaches nodes through `MEGANodeProviderProtocol`, so keeping
/// that object here is what lets it load a preview for a file link.
///
/// The link is kept with it because it is not always the link the screen was opened with: one shared
/// without its key is rebuilt around the key the user types in, and only that rebuilt link can be
/// downloaded from or handed on to someone else.
/// `@unchecked Sendable` is sound here: the only mutable state is synchronised by `@Atomic`.
public final class FileLinkNodeProvider: MEGANodeProviderProtocol, @unchecked Sendable {
    /// Kept as one value so that a caller holding the node can count on having its link too.
    private struct Resolved {
        let node: MEGANode
        let link: String
    }

    /// Written on the SDK thread that resolves the link and read from whichever thread asks for the
    /// preview, hence the synchronisation. The write happens before the link resolution returns, so
    /// the preview request that follows it always finds the node.
    @Atomic private var resolved: Resolved?

    public init() {}

    public func node(for handle: HandleEntity) async -> MEGANode? {
        guard let resolved, resolved.node.handle == handle else { return nil }
        return resolved.node
    }

    public var resolvedLink: String? {
        resolved?.link
    }

    package func store(_ node: MEGANode, resolvedFrom link: String) {
        $resolved.mutate { $0 = Resolved(node: node, link: link) }
    }
}
