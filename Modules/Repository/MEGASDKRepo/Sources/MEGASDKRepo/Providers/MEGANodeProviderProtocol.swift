import MEGADomain
import MEGASdk

public protocol MEGANodeProviderProtocol: Sendable {
    /// The MEGANode for the `HandleEntity`
    ///
    /// If the node is cached it will be returned immediately.
    ///
    /// If the node is not cached it will load `publicSetElementsInPreview` then find the `MEGASetElement` with
    /// matching node id and retrieve the `MEGANode` via `previewElementNode`
    ///
    /// - Parameter handle: Handle entity of node
    /// - Returns: MEGANode or nil if not found.
    func node(for handle: HandleEntity) async -> MEGANode?
}
