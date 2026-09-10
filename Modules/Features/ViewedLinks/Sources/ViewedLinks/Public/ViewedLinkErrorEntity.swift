/// Errors surfaced by the viewed-links use case.
public enum ViewedLinkErrorEntity: Error, Sendable, Equatable {
    /// The requested link could not be found.
    case notFound
    /// The persistence layer failed to complete the operation.
    case persistenceFailed
}
