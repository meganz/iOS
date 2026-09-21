import ChatRepo
import ContentLibraries
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAFoundation
import MEGARepo
import NodeBackgroundDownloader

@objc public final class PhotoBrowserViewModel: NSObject, ViewModelType {
    public enum Action: ActionType {
        case onViewDidLoad
        case onViewWillAppear
        case onViewWillDisappear
        case nodeDownloadStarted(NodeEntity)
        case downloadFileLink(URL)
        /// The browsing position changed. Only meaningful when this browser paginates; for every
        /// other entry point the whole sequence is already loaded and this does nothing.
        case didMoveToIndex(Int)
        /// The scroll view started moving under a drag or a deceleration.
        case didBeginScrolling
        /// It came to rest.
        case didSettleScrolling
    }
    
    public enum Command: CommandType, Equatable {
        case nodesUpdate([NodeEntity])
        /// A page arrived beyond the end of the loaded range.
        case photosAppended([NodeEntity])
        /// A page arrived before the start of it. Every page already laid out moves along by this
        /// many, so the receiver has to move the content offset with them.
        case photosPrepended([NodeEntity])
        /// `i of n` changed without the loaded range changing — reaching an end can renormalise the
        /// count on its own.
        case titleNeedsRefresh
    }
    
    public var invokeCommand: ((Command) -> Void)?
    
    public func dispatch(_ action: Action) {
        switch action {
        case .onViewDidLoad:
            onViewDidLoad()
        case .onViewWillAppear:
            onViewWillAppear()
        case .onViewWillDisappear:
            onViewWillDisappear()
        case let .nodeDownloadStarted(node):
            if #available(iOS 26.0, *) {
                processBackgroundDownload(for: node)
            }
        case let .downloadFileLink(url):
            if #available(iOS 26.0, *) {
                downloadFileLink(url: url)
            }
        case let .didMoveToIndex(index):
            // Hopped rather than isolated at the type: the tracking methods below are `@objc` and
            // called straight from the view controller, where annotating the class @MainActor
            // would leave that isolation to be lost at the ObjC boundary.
            Task { @MainActor [weak self] in
                self?.prefetchPages(around: index)
            }
        case .didBeginScrolling:
            Task { @MainActor [weak self] in
                self?.isScrollSettled = false
            }
        case .didSettleScrolling:
            Task { @MainActor [weak self] in
                self?.isScrollSettled = true
                self?.flushPendingPrepend()
            }
        }
    }
    
    private let photoBrowserUseCase: any PhotoBrowserUseCaseProtocol

    /// Present only for the paginated timeline; `nil` everywhere else, which leaves every other
    /// entry point on exactly the path it is on today.
    private let paginator: PhotoBrowserPaginator?

    /// Injected alongside the paginator, for the consumers that need the whole sequence rather
    /// than the loaded window. `nil` everywhere else, where the loaded array already is the whole
    /// sequence.
    private let fullListProvider: PhotoBrowserFullListProvider?

    /// The full list query in flight. Held so it can be cancelled when the browser goes away: the
    /// query is unbounded, and the progress indicator the caller put up for it would otherwise
    /// stay over whatever screen the user left for until the search finished on its own.
    @MainActor private var fullListTask: Task<[NodeEntity], any Error>?

    /// How close to an end of the loaded range the current photo has to get before the next page
    /// is requested. Provisional until measured against thumbnail prefetch on device.
    private let prefetchDistance = 10

    /// One request per direction. A page already in flight is never replaced: the request would
    /// ask the same cursor the same question, and cancelling it would only make the paginator mark
    /// the side retryable for no reason.
    @MainActor private var pageTasks: [PhotoBrowserPaginator.Direction: Task<Void, Never>] = [:]

    /// Pages fetched before the loaded range are held until the scroll view is at rest. Every page
    /// is laid out at an absolute offset, so inserting ahead of them moves them all — doing that
    /// under a deceleration lands the user on a photo they did not swipe to. Appends only extend
    /// the content size and need no such wait.
    ///
    /// Only the identities are held. The entities themselves are read back from the paginator when
    /// the wait ends, so a node deleted or updated in the meantime is not put on screen from a
    /// stale copy.
    @MainActor private var heldPrependHandles: Set<HandleEntity> = []

    /// The `i of n` anchor the view was last given. Set before the first request goes out, so the
    /// first change after that is a real one.
    @MainActor private var publishedTitlePosition: TitlePosition?

    /// Whether the browser is on screen rather than behind a video player or an action sheet.
    @MainActor private var isVisible = false

    /// The last position the view reported, so a request that has to be re-issued knows where to
    /// look from.
    @MainActor private var lastDisplayIndex: Int?
    @MainActor private var isScrollSettled = true
    
    var monitorNodeUpdatesTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    private let tracker: any AnalyticsTracking

    /// Built per node: a node reached through a folder link or a link preview is already authorized and
    /// must not be looked up again, which is what `preresolvedNodes` in the repository is for.
    private let makeDownloadUseCase: (MEGANode) -> any PhotoBrowserNodeDownloadUseCaseProtocol
    
    init(
        tracker: some AnalyticsTracking = DIContainer.tracker,
        photoBrowserUseCase: some PhotoBrowserUseCaseProtocol,
        paginator: PhotoBrowserPaginator? = nil,
        fullListProvider: PhotoBrowserFullListProvider? = nil,
        makeDownloadUseCase: @escaping (MEGANode) -> any PhotoBrowserNodeDownloadUseCaseProtocol = {
            PhotoBrowserViewModel.makeDownloadUseCase(megaNode: $0)
        }
    ) {
        self.tracker = tracker
        self.photoBrowserUseCase = photoBrowserUseCase
        self.paginator = paginator
        self.fullListProvider = fullListProvider
        self.makeDownloadUseCase = makeDownloadUseCase
    }

    /// Whether asking for a full media list costs a query. `false` means the caller already holds
    /// the whole sequence and ``fullMediaList(of:)`` has nothing to add.
    var loadsFullMediaList: Bool { fullListProvider != nil }

    /// Every node of `mediaType` in this browsing session, or `nil` when the caller should keep
    /// using the array it already has.
    ///
    /// `nil` covers three cases that mean the same thing to a caller: this browser was handed its
    /// whole sequence up front, the query failed, or it came back empty. Empty is not taken at
    /// face value — the browser is showing media of its own, so a list holding none is a result to
    /// fall back from rather than one to play.
    @MainActor
    func fullMediaList(of mediaType: MediaTimelineFilterEntity.MediaType) async -> [NodeEntity]? {
        guard let fullListProvider else { return nil }
        let task = Task { try await fullListProvider.fullList(of: mediaType) }
        fullListTask = task
        defer { if fullListTask == task { fullListTask = nil } }
        do {
            let nodes = try await task.value
            // A cancelled search answers with an empty list rather than an error, so neither
            // outcome below is a result worth reporting once the caller has gone.
            guard !task.isCancelled else { return nil }
            guard nodes.isNotEmpty else {
                MEGALogWarning("[Photo Browser] the full \(mediaType) list came back empty")
                return nil
            }
            return nodes
        } catch {
            guard !task.isCancelled else { return nil }
            MEGALogError("[Photo Browser] failed to load the full \(mediaType) list: \(error)")
            return nil
        }
    }

    /// `i of n` for the title, or `nil` when this browser does not paginate — the caller then falls
    /// back to the loaded array, which for every other entry point is the whole sequence.
    ///
    /// `i` is a position in the browsing sequence rather than a rank in the source; see
    /// `PhotoBrowserPaginator.displayPosition(forIndex:)`.
    @MainActor
    func titlePosition(forIndex index: Int) -> (index: Int, total: Int)? {
        guard let paginator else { return nil }
        return paginator.displayPosition(forIndex: paginatorIndex(forDisplayIndex: index, in: paginator))
    }

    /// Translates an index in the sequence *on screen* into one in the paginator's.
    ///
    /// While a prepend is held the two differ: the paginator has already grown at the front and the
    /// view has not, so the same photo sits `heldCount` further along in the paginator.
    @MainActor
    private func paginatorIndex(forDisplayIndex index: Int, in paginator: PhotoBrowserPaginator) -> Int {
        index + heldPrefix(in: paginator).count
    }

    /// The leading nodes the paginator holds that have not reached the view yet. Held pages always
    /// sit at the front, so this is a prefix; reading it from the paginator rather than counting
    /// what was held means nodes deleted while waiting drop out on their own.
    @MainActor
    private func heldPrefix(in paginator: PhotoBrowserPaginator) -> [NodeEntity] {
        guard !heldPrependHandles.isEmpty else { return [] }
        return Array(paginator.nodes.prefix { heldPrependHandles.contains($0.handle) })
    }

    // MARK: - Pagination

    @MainActor
    private func prefetchPages(around index: Int) {
        guard let paginator else { return }
        lastDisplayIndex = index
        if publishedTitlePosition == nil {
            publishedTitlePosition = TitlePosition(of: paginator)
        }
        for direction in PhotoBrowserPaginator.Direction.allCases
        where shouldRequest(direction, from: index, in: paginator) {
            requestPage(direction, from: paginator)
        }
    }

    @MainActor
    private func shouldRequest(
        _ direction: PhotoBrowserPaginator.Direction,
        from index: Int,
        in paginator: PhotoBrowserPaginator
    ) -> Bool {
        // `.unresolved` is deliberately not excluded: a failed page is retried the next time the
        // user moves within reach of that end, which is retry enough without a timer.
        guard paginator.availability(for: direction) != .exhausted else { return false }
        let position = paginatorIndex(forDisplayIndex: index, in: paginator)
        switch direction {
        case .forward: return position >= paginator.nodes.count - 1 - prefetchDistance
        case .backward: return position <= prefetchDistance
        }
    }

    @MainActor
    private func requestPage(
        _ direction: PhotoBrowserPaginator.Direction,
        from paginator: PhotoBrowserPaginator
    ) {
        guard pageTasks[direction] == nil else { return }
        // Not cancelled when the browser is covered by a video player or an action sheet: paging is
        // driven by scrolling, so it is idle under a cover anyway, and cancelling would leave the
        // side retryable for a reason the user never caused.
        pageTasks[direction] = Task { @MainActor [weak self] in
            let outcome = await paginator.loadMore(direction)
            self?.pageTasks[direction] = nil
            self?.commit(outcome, from: direction, in: paginator)
        }
    }

    @MainActor
    private func commit(
        _ outcome: PhotoBrowserPaginator.Outcome,
        from direction: PhotoBrowserPaginator.Direction,
        in paginator: PhotoBrowserPaginator
    ) {
        if case let .loaded(insertedCount) = outcome, insertedCount > 0 {
            insert(insertedCount, from: direction, in: paginator)
            return
        }
        // Nothing was inserted, which does not mean nothing changed: reaching both ends normalises
        // the count to what the sequence actually holds, and the user may be sitting on the last
        // photo watching a total that has just come down.
        refreshTitleIfMoved(in: paginator)
        if case .cancelled = outcome {
            resumeAfterCancellation()
        }
    }

    @MainActor
    private func resumeAfterCancellation() {
        guard isVisible, let index = lastDisplayIndex else { return }
        prefetchPages(around: index)
    }

    /// Where the title is anchored.
    private struct TitlePosition: Equatable {
        let start: Int
        let total: Int

        @MainActor
        init(of paginator: PhotoBrowserPaginator) {
            start = paginator.globalStartIndex
            total = paginator.totalCount
        }
    }

    /// Asks for a refresh when the numbers differ from the ones the view was last given.
    ///
    /// Compared against what was published rather than against a snapshot taken when the request
    /// went out: both directions are usually in flight together, and a snapshot would let the
    /// second one to return claim the first one's change and ask for a second refresh.
    @MainActor
    private func refreshTitleIfMoved(in paginator: PhotoBrowserPaginator) {
        let current = TitlePosition(of: paginator)
        guard current != publishedTitlePosition else { return }
        publishedTitlePosition = current
        invokeCommand?(.titleNeedsRefresh)
    }

    /// Publishing a page makes the view reload the title, so the position goes on record without a
    /// refresh of its own.
    @MainActor
    private func publishPosition(of paginator: PhotoBrowserPaginator) {
        publishedTitlePosition = TitlePosition(of: paginator)
    }

    @MainActor
    private func insert(
        _ insertedCount: Int,
        from direction: PhotoBrowserPaginator.Direction,
        in paginator: PhotoBrowserPaginator
    ) {
        switch direction {
        case .forward:
            publishPosition(of: paginator)
            invokeCommand?(.photosAppended(Array(paginator.nodes.suffix(insertedCount))))
        case .backward:
            let prepended = paginator.nodes.prefix(insertedCount)
            guard isScrollSettled else {
                heldPrependHandles.formUnion(prepended.map(\.handle))
                // The photo on screen has not moved — the index is translated across what is held —
                // but the count it came with is already part of the title.
                refreshTitleIfMoved(in: paginator)
                return
            }
            publishPosition(of: paginator)
            invokeCommand?(.photosPrepended(Array(prepended)))
        }
    }

    @MainActor
    private func flushPendingPrepend() {
        guard let paginator, !heldPrependHandles.isEmpty else { return }
        // Read back from the paginator rather than replaying what was held: a node deleted while
        // waiting is gone from here too, and one whose metadata changed comes back updated.
        let held = heldPrefix(in: paginator)
        heldPrependHandles = []
        guard !held.isEmpty else {
            refreshTitleIfMoved(in: paginator)
            return
        }
        publishPosition(of: paginator)
        invokeCommand?(.photosPrepended(held))
    }
    
    private func onViewWillAppear() {
        // A request cancelled on the way out is not resumed by itself: the side was left retryable,
        // and nothing else asks again until the user scrolls.
        Task { @MainActor [weak self] in
            self?.isVisible = true
            self?.retryUnresolvedPages()
        }
        monitorNodeUpdatesTask = Task { @MainActor [weak self, photoBrowserUseCase] in
            for await nodeEntities in photoBrowserUseCase.nodeUpdates {
                // The paginator is told first and in the same hop: a removal has to be on record
                // before a page already in flight comes back, or that page puts the node straight
                // back into the sequence — the entity it carries is a copy whose `isRemoved` is
                // still false, so nothing else would catch it.
                self?.applyNodeUpdatesToPaginator(nodeEntities)
                self?.invokeCommand?(.nodesUpdate(nodeEntities))
            }
        }
    }

    @MainActor
    private func applyNodeUpdatesToPaginator(_ nodes: [NodeEntity]) {
        guard let paginator else { return }
        paginator.applyRemovals(of: nodes.removedChangeTypeNodes())
        paginator.applyMetadataUpdates(of: nodes.nodes(for: [.attributes, .publicLink]))
    }
    
    private func onViewDidLoad() {
        tracker.trackAnalyticsEvent(with: DIContainer.photoPreviewScreenEvent)
    }
    
    private func onViewWillDisappear() {
        monitorNodeUpdatesTask = nil
        // Paging stops with the monitor: a page landing while node events are unwatched would have
        // no removal to be judged against. Nothing is lost — paging is scroll-driven, and the side
        // is left retryable.
        Task { @MainActor [weak self] in
            self?.isVisible = false
            self?.flushHeldPages()
            self?.cancelPageRequests()
            // Same for a full list query: it was started for a screen that is on its way out, and
            // its progress indicator has no business outliving that screen.
            self?.fullListTask?.cancel()
        }
    }

    /// Merges anything still waiting for the scroll view, so nothing is held across the stretch
    /// where node events are unwatched and would come back from a stale sequence. Dropping it is
    /// not an option: what is held also maps a view index onto a paginator one. Safe here because
    /// the scroll view has stopped.
    @MainActor
    private func flushHeldPages() {
        isScrollSettled = true
        flushPendingPrepend()
    }

    @MainActor
    private func retryUnresolvedPages() {
        guard let paginator else { return }
        for direction in PhotoBrowserPaginator.Direction.allCases
        where paginator.availability(for: direction) == .unresolved {
            requestPage(direction, from: paginator)
        }
    }

    @MainActor
    private func cancelPageRequests() {
        pageTasks.values.forEach { $0.cancel() }
        pageTasks = [:]
    }
    
    @objc func trackAnalyticsSaveToDeviceMenuToolbarEvent() {
        tracker.trackAnalyticsEvent(
            with: DIContainer.photoPreviewSaveToDeviceMenuToolbarEvent)
    }
    
    @objc func trackHideNodeMenuEvent() {
        tracker.trackAnalyticsEvent(with: ImagePreviewHideNodeMenuToolBarEvent())
    }

    @objc func trackAddToAlbumMenuItemEvent() {
        tracker.trackAnalyticsEvent(with: AddToAlbumMenuItemEvent())
    }
    
    @available(iOS 26.0, *)
    private func processBackgroundDownload(for node: NodeEntity) {
        let featureEnabled = DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosBackgroundContinuedProcessingTransfer)
        // Note: consider using MediaUseCase
        let isVideo = node.name.fileExtensionGroup.isVideo
        
        guard featureEnabled && isVideo else { return }
        
        Task {
            await BackgroundDownloadHandler.shared.handleBackgroundDownload(for: node)
        }
        tracker.trackAnalyticsEvent(with: PhotoPreviewMakeAvailableOfflineBGContinuedProcessingTaskMenuItemEvent())
    }
    
    @available(iOS 26.0, *)
    private func downloadFileLink(url: URL) {
        let fileLink = FileLinkEntity(linkURL: url)
        Task {
            do {
                let node = try await photoBrowserUseCase.nodeFor(fileLink: fileLink)
                processBackgroundDownload(for: node)
            } catch {
                MEGALogWarning("[Photo Browser] Failed to get node for file link: \(url) with error: \(error)")
            }
        }
    }

    // MARK: - Original photo download

    @objc var isBatchDownloadEnabled: Bool {
        BatchDownloadFeatureFlag.isEnabled
    }

    /// Downloads the full size image a page shows, to `destinationPath` which is a file path.
    ///
    /// Not cancelled as aligned with legacy flow. The download still runs to completion and available at the cache for next use.
    @objc func startOriginalDownload(
        for megaNode: MEGANode,
        destinationPath: String,
        onProgress: @escaping (Float) -> Void,
        onFinish: @escaping (String) -> Void
    ) {
        let events = makeDownloadUseCase(megaNode).downloadOriginalImage(
            for: megaNode.toNodeEntity(),
            to: URL(fileURLWithPath: destinationPath)
        )

        Task { @MainActor in
            do {
                for try await event in events {
                    switch event {
                    case .update(let transfer):
                        guard transfer.totalBytes > 0 else { continue }
                        onProgress(Float(transfer.transferredBytes) / Float(transfer.totalBytes))
                    case .finish(let transfer):
                        guard let path = transfer.path else { return }
                        onFinish(path)
                        return
                    default:
                        break
                    }
                }
            } catch {
                MEGALog.log(level: .error, message: "[Photo Browser] Failed to download original image: \(error)")
            }
        }
    }

    private static func makeDownloadUseCase(megaNode: MEGANode) -> any PhotoBrowserNodeDownloadUseCaseProtocol {
        let sdk = MEGASdk.shared
        return PhotoBrowserNodeDownloadUseCase(
            downloadFileRepository: DownloadFileRepository(
                sdk: sdk,
                chatNodeProvider: ChatMEGANodeProvider(chatSdk: .sharedChatSdk, sdk: sdk),
                preresolvedNodes: [megaNode.handle: megaNode]
            )
        )
    }
}
