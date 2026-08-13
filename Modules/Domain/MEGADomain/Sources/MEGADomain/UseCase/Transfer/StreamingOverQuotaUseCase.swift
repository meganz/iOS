import MEGASwift

// MARK: - Use case protocol

public protocol StreamingOverQuotaUseCaseProtocol: Sendable {
    /// Emits `streamingOverQuota` events raised by streaming done while the user is logged out.
    ///
    /// `AppDelegate` is registered as a global delegate on `MEGASdk.shared` only, so it already
    /// covers the logged-in case in `onEvent:event:`. Logged-out streaming runs on the folder link
    /// SDK instance instead, and its events never reach that delegate.
    var loggedOutStreamingOverQuotaUpdates: AnyAsyncSequence<EventEntity> { get }
}

// MARK: - Use case

public struct StreamingOverQuotaUseCase<T: EventRepositoryProtocol>: StreamingOverQuotaUseCaseProtocol {
    private let repo: T

    public init(repo: T) {
        self.repo = repo
    }

    public var loggedOutStreamingOverQuotaUpdates: AnyAsyncSequence<EventEntity> {
        repo
            .folderLinkEventUpdates
            .filter { $0.type == .streamingOverQuota }
            .eraseToAnyAsyncSequence()
    }
}
