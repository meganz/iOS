import MEGADomain

/// The changes found but not yet delivered to the system, in the order they were found. The working set's change
/// enumeration reads them from its sync anchor on.
public protocol FileProviderChangeQueueRepositoryProtocol: RepositoryProtocol, Sendable {
    func append(_ changes: [FileProviderChangeEntity]) async throws
    /// The position just after the last change appended.
    func currentAnchor() async throws -> FileProviderChangeAnchorEntity
    /// The changes appended after `anchor`, in order.
    /// - Parameter limit: The most changes to return.
    /// - Throws: `FileProviderChangeQueueErrorEntity.anchorExpired` when some of those changes are gone.
    func changes(since anchor: FileProviderChangeAnchorEntity, limit: Int) async throws -> FileProviderChangeBatchEntity
}

/// Tells the system the working set has changes, so that it enumerates them.
public protocol FileProviderWorkingSetSignalRepositoryProtocol: RepositoryProtocol, Sendable {
    /// The working set is the only container a replicated extension can signal.
    func signalWorkingSet() async throws
}
