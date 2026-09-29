/// Errors surfaced by the left-off use case. Raw store errors are mapped onto this at the repository
/// boundary, so callers above never see the underlying persistence errors.
public enum LeftOffItemErrorEntity: Error, Sendable, Equatable {
    /// The operation was cancelled before it finished.
    case cancelled
    /// The persistence layer failed to complete the operation.
    case persistenceFailure
}
