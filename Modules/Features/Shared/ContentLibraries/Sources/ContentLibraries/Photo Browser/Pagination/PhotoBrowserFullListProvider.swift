import MEGADomain

/// The whole media sequence a paginated photo browser was opened on, for the two consumers that
/// cannot work from the loaded window: the slideshow and the video queue.
///
/// Both take their list once, when the user asks for them, and keep it for the rest of that
/// session — so a list assembled from the window would quietly leave out everything the browser
/// had not paged to, with no later chance to put it back.
public struct PhotoBrowserFullListProvider: Sendable {
    private let useCase: any MediaTimelineUseCaseProtocol
    private let filter: MediaTimelineFilterEntity
    private let sortOrder: MediaTimelineSortOrderEntity

    public init(context: PhotoBrowserPaginationContext, useCase: some MediaTimelineUseCaseProtocol) {
        self.useCase = useCase
        self.filter = context.filter
        self.sortOrder = context.sortOrder
    }

    /// Every node of `mediaType` the browser's query reaches, in the browser's own order. The rest
    /// of the query — location, sensitivity, sort — is the one the browser was opened on, so the
    /// list is the same sequence the user is paging through, narrowed to one kind of media.
    ///
    /// The limit is `0`, which the SDK reads as no limit. The loaded count is not an upper bound
    /// to guess with: an upload landing after the browser opened pushes the oldest items out of a
    /// bounded descending query, and the photo being viewed may be among them.
    public func fullList(of mediaType: MediaTimelineFilterEntity.MediaType) async throws -> [NodeEntity] {
        try await useCase.mediaPage(
            filter: MediaTimelineFilterEntity(mediaType: mediaType, location: filter.location),
            sortOrder: sortOrder,
            after: nil,
            limit: 0)
    }
}
