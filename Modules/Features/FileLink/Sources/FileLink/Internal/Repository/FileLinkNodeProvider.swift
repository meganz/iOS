import MEGAAppSDKRepo
import MEGADomain
import MEGASdk
import MEGASwift

/// Holds on to the `MEGANode` a file link resolved to.
///
/// A public link node is not part of the account tree, so `MEGASdk` cannot look it up by handle: the
/// file attribute requests that load a preview have to carry the node object the link resolution
/// handed back. `ThumbnailRepository` reaches nodes through `MEGANodeProviderProtocol`, so keeping
/// that object here is what lets it load a preview for a file link.
///
/// The same instance has to be shared between `FileLinkRepository`, which stores the node, and the
/// loader built by `FileLinkPreviewLoaderFactory`, which reads it.
///
/// `@unchecked Sendable` is sound here: the only mutable state is synchronised by `@Atomic`.
package final class FileLinkNodeProvider: MEGANodeProviderProtocol, @unchecked Sendable {
    /// Written on the SDK thread that resolves the link and read from whichever thread asks for the
    /// preview, hence the synchronisation. The write happens before the link resolution returns, so
    /// the preview request that follows it always finds the node.
    @Atomic private var resolvedNode: MEGANode?

    package init() {}

    package func node(for handle: HandleEntity) async -> MEGANode? {
        guard let resolvedNode, resolvedNode.handle == handle else { return nil }
        return resolvedNode
    }

    package func store(_ node: MEGANode) {
        $resolvedNode.mutate { $0 = node }
    }
}
