import MEGADomain

/// An enum which represents current editing state where
enum FolderLinkEditingState<C> where C: Collection {
    /// Edit mode is not active
    case inactive
    /// Edit mode is active and comes with a collection of selected nodes.
    /// - Parameter C: collection of selected nodes. `Set<HandleEntity>` from Search module and `[NodeEntity]` from Media Discovery
    ///
    /// Using generic here because the collection comes from different forms.
    ///
    /// Advantages when working with a collection of `NodeEntity`:
    /// - Access `NodeEntity` properties directly, without converting from `HandleEntity`.
    /// - Avoid repeatedly requesting `NodeEntity` from the SDK for each `HandleEntity`, reducing contention on the SDK mutex.
    case active(C)
}
