import MEGASwift

public protocol EventRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Listen to event updates
    /// - Returns: an AsyncSequence that emits event updates
    var eventUpdates: AnyAsyncSequence<EventEntity> { get }

    /// Listen to event updates of the folder link SDK instance.
    ///
    /// Despite the name, this instance serves *all* streaming done while the user is logged out —
    /// `StreamingInfoRepository` and `AudioStreamingRepository` both select it purely on
    /// `MEGASdk.isLoggedIn`, regardless of folder link vs file link.
    /// - Returns: an AsyncSequence that emits event updates
    var folderLinkEventUpdates: AnyAsyncSequence<EventEntity> { get }
}
