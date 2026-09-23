import AsyncAlgorithms
import Combine
import ContentLibraries
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAPreference
import SwiftUI

@MainActor
final class NewTimelineViewModel: ObservableObject {
    @Published private(set) var loadPhotosTaskId = UUID()
    /// Identifies the *query* (filter + sort) the reactive section monitor is subscribed to, as
    /// opposed to ``loadPhotosTaskId`` which drives a reload.
    @Published private(set) var timelineQueryId = UUID()
    @Published private(set) var showEmptyStateView = false
    
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private(set) var isCameraUploadsEnabled: Bool
    
    let photoLibraryContentViewModel: PhotoLibraryContentViewModel
    let photoLibraryContentViewRouter: PhotoLibraryContentViewRouter
    
    private let cameraUploadsSettingsViewRouter: any Routing
    private let photoLibraryUseCase: any PhotoLibraryUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let contentConsumptionUserAttributeUseCase: any ContentConsumptionUserAttributeUseCaseProtocol
    private let tracker: any AnalyticsTracking

    private let mediaTimelineUseCase: (any MediaTimelineUseCaseProtocol)?
    /// Whether the timeline may offer — and query by — the media capture time at all.
    private let isDateTakenSortEnabled: Bool

    /// Both axes of the timeline's order live in its own preferences: the timeline is the only
    /// screen that can express them (the app-wide "same for all" sort has no capture-time order),
    /// so writing them to the shared sort preference would re-sort Cloud Drive and every other
    /// screen with an order the user only chose for the timeline.
    @PreferenceWrapper(key: PreferenceKeyEntity.mediaTimelineSortedByDateTaken, defaultValue: false)
    private var sortsByDateTaken: Bool

    /// `nil` until the timeline has an order of its own — see the migration in `init`.
    @PreferenceWrapper(key: PreferenceKeyEntity.mediaTimelineSortedOldestFirst, defaultValue: nil)
    private var sortsOldestFirst: Bool?
    
    private var isInitialLoadComplete = false
    private var pendingNodeUpdates: [NodeEntity] = []

    /// The count-based sections backing the current skeleton, kept so a visible flat-index
    /// window can be mapped to a `section + local offset` fetch. Only populated on the
    /// skeleton path.
    private var dateSections: [MediaDateSectionEntity] = []

    private var skeletonFilterOptions: PhotosFilterOptionsEntity?
    private var skeletonSortOrder: MediaTimelineSortOrderEntity?

    private let initialHydrationWindowSize = 60

    /// Where every fetched node sits, keyed by handle — carried from commit to commit rather than
    /// rebuilt, which would mean walking every slot on the main actor once per settled scroll.
    /// Bucket coordinates survive a reshape where flat indices don't, so a rebuild drops only the
    /// buckets it disturbed. Moves with the library and the sections in `commitProjection`: one
    /// without the others would resolve the new library in the old layout's coordinates.
    private var hydratedCoordinates: [HandleEntity: TimelineProjection.BucketCoordinate] = [:]

    private var cachedProjection: (revision: Int, value: TimelineProjection)?
    /// Bumped after anything that changes either half of the projection. A cache entry carries the
    /// revision it was built at, so a projection built by a `@Published` observer *during* the
    /// publish — `willSet` runs before the library actually changes — is invalidated rather than
    /// left behind as a stale snapshot.
    private var projectionRevision = 0

    /// How long the visible range must stay put before its window is fetched.
    private let visibleWindowSettleInterval: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(100)

    /// Bumped only when the query changes (filter/sort) and the skeleton is rebuilt from scratch.
    /// Every in-flight hydration captures it and is discarded if it changed — a different query
    /// invalidates even a handle-anchored page. (The design doc calls this `timelineGeneration`.)
    private var timelineGeneration = 0

    /// Version per day bucket (`groupId`), bumped when that bucket's count changes in a reactive
    /// pass. A hydration captures the versions of the buckets its visible range spans and is
    /// discarded if any changed (or vanished) before it returns — so a reshape invalidates only
    /// fetches targeting the reshaped bucket, never hydration for the bucket the user is viewing.
    private var sectionVersions: [String: UInt] = [:]

    /// Bumped on every library commit made through ``commitLibrary(_:)``. The reactive section pass
    /// captures it before its `await`s and re-checks it before committing: if it changed, a metadata
    /// patch (or other commit) landed while the pass was suspended, so the pass — built from a now
    /// stale snapshot — merges the current library's fresher per-node metadata in before publishing,
    /// instead of reverting it.
    private var libraryRevision = 0

    /// Re-keys ``timelineQueryId`` on every real change, so the section monitor can never keep
    /// counting a photo set the rest of the screen no longer queries.
    private(set) var photoFilterOptions: PhotosFilterOptionsEntity = [.allMedia, .allLocations] {
        didSet {
            guard oldValue != photoFilterOptions else { return }
            timelineQueryId = UUID()
        }
    }

    private(set) var sortOrder: SortOrderEntity = .modificationDesc {
        didSet {
            guard oldValue != sortOrder else { return }
            timelineQueryId = UUID()
        }
    }
    
    /// Order the paginated queries run in: direction from ``sortOrder``, timestamp from
    /// ``timestampBasis``.
    private var mediaTimelineSortOrder: MediaTimelineSortOrderEntity {
        sortOrder.toMediaTimelineSortOrderEntity(basis: timestampBasis)
    }

    private var timestampBasis: MediaTimelineSortOrderEntity.TimestampBasis {
        isDateTakenSortEnabled && sortsByDateTaken ? .mediaCaptureTime : .modificationTime
    }

    var mediaTimelineSortType: MediaTimelineSortOrderEntity? {
        guard isDateTakenSortEnabled else { return nil }
        return mediaTimelineSortOrder
    }

    private(set) var currentNodeUpdateTask: Task<Void, any Error>? {
        didSet { oldValue?.cancel() }
    }
    private(set) var sortPhotoLibraryTask: Task<Void, any Error>? {
        didSet { oldValue?.cancel() }
    }
    private(set) var saveFiltersTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }
    /// The in-flight window hydration. Latest-only: a newer visible range cancels the previous
    /// fetch (via the SDK cancel token) so a slow request for an area the user scrolled past
    /// doesn't hold up — or waste work on — the region now on screen.
    private(set) var hydrationTask: Task<Void, Never>? {
        didSet { oldValue?.cancel() }
    }

    /// Selection for cells whose photo has not loaded, on the paginated path only.
    private let pendingSelection: TimelinePendingSelection?

    /// What the user marked: committed nodes plus positions still waiting for one.
    var markedItemCount: Int {
        pendingSelection?.markedCount ?? photoLibraryContentViewModel.selection.photos.count
    }

    var markedItemCountPublisher: AnyPublisher<Int, Never> {
        guard let pendingSelection else {
            return photoLibraryContentViewModel.selection.$photos
                .map(\.count)
                .removeDuplicates()
                .eraseToAnyPublisher()
        }
        return pendingSelection.markedCountPublisher.removeDuplicates().eraseToAnyPublisher()
    }

    var pendingSelectionCount: Int { pendingSelection?.unresolvedCount ?? 0 }
    
    init(
        photoLibraryContentViewModel: PhotoLibraryContentViewModel,
        photoLibraryContentViewRouter: PhotoLibraryContentViewRouter,
        cameraUploadsSettingsViewRouter: some Routing,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
        mediaTimelineUseCase: (any MediaTimelineUseCaseProtocol)? = nil,
        isDateTakenSortEnabled: Bool = false,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.photoLibraryContentViewModel = photoLibraryContentViewModel
        self.photoLibraryContentViewRouter = photoLibraryContentViewRouter
        self.cameraUploadsSettingsViewRouter = cameraUploadsSettingsViewRouter
        self.photoLibraryUseCase = photoLibraryUseCase
        self.nodeUseCase = nodeUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.mediaTimelineUseCase = mediaTimelineUseCase
        self.isDateTakenSortEnabled = isDateTakenSortEnabled
        self.tracker = tracker
        // Only the paginated path has cells with no node behind them.
        pendingSelection = mediaTimelineUseCase == nil
            ? nil
            : TimelinePendingSelection(selection: photoLibraryContentViewModel.selection)
        $isCameraUploadsEnabled.useCase = preferenceUseCase
        $sortsByDateTaken.useCase = preferenceUseCase
        $sortsOldestFirst.useCase = preferenceUseCase
        // Read synchronously so the very first load already queries in the stored order,
        // instead of loading in the default order and reloading. On the first launch after the
        // split the timeline has no order of its own yet, so it inherits — once — the direction it
        // used to keep in the app-wide sort preference, and never reads that preference again.
        let oldestFirst = sortsOldestFirst
            ?? (sortOrderPreferenceUseCase.sortOrder(for: .cameraUploadExplorerFeed) == .modificationAsc)
        sortsOldestFirst = oldestFirst
        sortOrder = oldestFirst ? .modificationAsc : .modificationDesc
        pendingSelection?.resolver = self
        photoLibraryContentViewModel.positionalSelectionHandler = pendingSelection
    }
    
    func onViewDisappear() {
        currentNodeUpdateTask = nil
        sortPhotoLibraryTask = nil
        saveFiltersTask = nil
        hydrationTask = nil
        pendingSelection?.teardown()
    }
    
    func loadPhotos() async {
        defer { isInitialLoadComplete = true }
        do {
            if !isInitialLoadComplete {
                try await loadSavedFilters()
            }
            // The skeleton path publishes from ``monitorTimelineSections()``, whose stream prepends
            // a first full load of the very same query. Running a second one here does not race it:
            // the SDK serialises the two, so the duplicate waits out the first and then repeats it.
            guard mediaTimelineUseCase == nil else { return }
            let taskId = loadPhotosTaskId
            let library = try await timelinePhotoLibrary()
            // A filter or sort change replaces this task. A pass already past the fetch would
            // otherwise put the outgoing query's content back.
            guard !Task.isCancelled, loadPhotosTaskId == taskId else { return }
            commitProjection(library, sections: nil)
        } catch is CancellationError {
            MEGALogError("[\(type(of: self))] loadPhotos cancelled")
        } catch {
            MEGALogError("[\(type(of: self))] - error loading photos \(error)")
        }
    }

    /// Single funnel for publishing a new library. Bumps ``libraryRevision`` so a concurrent
    /// reactive pass can detect that the library moved under it (see ``libraryRevision``).
    private func commitLibrary(_ library: PhotoLibrary) {
        commitProjection(library, sections: nil)
    }

    /// Publish a new projection: the library the grid renders and, when the shape moved, the
    /// sections that describe it. **Runs to completion with no suspension point**, which is what
    /// switches its four pieces atomically: `sectionVersions`, `dateSections`,
    /// `hydratedCoordinates` and the library.
    ///
    /// Moving any of them ahead of the publish opens a window where a selection cycle plans against
    /// the projection still on screen but captures the new version, so its result passes
    /// ``versionsStillValid(_:against:)`` having been planned in stale coordinates.
    ///
    /// - Parameter sections: the new layout, or `nil` for a commit that cannot change the shape
    ///   (metadata patch, sort application, first load).
    /// - Parameter coordinates: how this commit moves the index, or `nil` when it cannot — a
    ///   metadata patch leaves every handle in the slot it was in.
    /// - Parameter query: the query the committed content was fetched under; `nil` leaves the
    ///   published one alone.
    private func commitProjection(
        _ library: PhotoLibrary,
        sections: [MediaDateSectionEntity]?,
        coordinates: CoordinateUpdate? = nil,
        query: MediaTimelineQuery? = nil
    ) {
        if let sections {
            let deltas = countDeltas(from: dateSections, to: sections)
            bumpVersions(for: deltas)
            dateSections = sections
            // The shape moved, so a position means something else now: a new layout version, and
            // the marks in a bucket that resized move to where that bucket put them. The sort
            // order is read here rather than stored on the slot, it cannot change without
            // changing the query, and a query change drops every slot before this runs.
            pendingSelection?.layoutDidReshape(
                to: sections, countDeltas: deltas, newestFirst: mediaTimelineSortOrder.isNewestFirst)
        }
        switch coordinates {
        case .adding(let added):
            // Dropping the cache first leaves this the index's only holder, so the merge runs in
            // place rather than copying everything fetched so far.
            cachedProjection = nil
            hydratedCoordinates.merge(added) { current, _ in current }
        case .replacing(let replacement):
            hydratedCoordinates = replacement
        case nil:
            break
        }
        libraryRevision &+= 1
        // Only the commits that fetched the content carry one. A metadata patch comes through
        // `commitLibrary` with none: stamping it with a query the user has since chosen — whose
        // sections have not arrived — would claim content was fetched under a query it never was.
        if let query { photoLibraryContentViewModel.mediaTimelineQuery = query }
        photoLibraryContentViewModel.library = library.withLayoutVersion(
            pendingSelection?.layoutVersion ?? PhotoLibrary.initialLayoutVersion)
        projectionRevision &+= 1
        // Last, on a projection whose halves now agree: a mark whose photo arrived in this commit
        // is pinned to that node before the user can see a thumbnail under it.
        pendingSelection?.promoteResolvedSlots()
    }

    /// The query as it stands now, to be snapshotted by whoever is about to fetch content under
    /// it. `nil` when the timeline is not paginated — a browser opened from it then stays on the
    /// whole-sequence path it is on today.
    private var paginationQuery: MediaTimelineQuery? {
        guard mediaTimelineUseCase != nil else { return nil }
        return MediaTimelineQuery(
            filter: photoFilterOptions.toMediaTimelineFilterEntity(),
            sortOrder: mediaTimelineSortOrder)
    }

    /// The projection the user is currently looking at. Cached because building one indexes the
    /// buckets and selection asks a position question per cell during a drag; invalidated by every
    /// change to any part of it.
    private var publishedProjection: TimelineProjection {
        if let cachedProjection, cachedProjection.revision == projectionRevision {
            return cachedProjection.value
        }
        let projection = TimelineProjection(
            library: photoLibraryContentViewModel.library,
            sections: dateSections,
            hydratedCoordinates: hydratedCoordinates)
        cachedProjection = (projectionRevision, projection)
        return projection
    }
    
    func monitorUpdates() async {
        guard mediaTimelineUseCase == nil else { return }
        for await nodes in nodeUseCase.nodeUpdates where isInitialLoadComplete {
            handleNodeUpdates(with: nodes)
        }
    }

    /// Reactively keep the skeleton in step with the photo set while it is on screen. The date
    /// sections re-derive in the data layer on media-node and folder-sensitivity changes; here we
    /// coalesce bursts and fold each settled result in — carrying hydrated thumbnails across a
    /// reshape by identity rather than flashing back to placeholders. The View owns this task, so
    /// it is cancelled on disappear and re-subscribed (with fresh filter/sort) on `loadPhotosTaskId`
    /// change. No-op unless the skeleton path is active.
    func monitorTimelineSections() async {
        guard let mediaTimelineUseCase else { return }
        // Snapshot once: every section this subscription yields was counted under it, however long
        // the loop runs and whatever the screen's filter has moved on to. A change re-keys
        // `timelineQueryId`, which replaces this task and with it the snapshot.
        let queryId = timelineQueryId
        let query = paginationQuery
        let sectionUpdates = await mediaTimelineUseCase.monitorDateSections(
            filter: photoFilterOptions.toMediaTimelineFilterEntity(),
            granularity: .day,
            sortOrder: mediaTimelineSortOrder)
            .compactMap { result -> [MediaDateSectionEntity]? in
                switch result {
                case .success(let sections):
                    return sections
                case .failure(let error):
                    MEGALogError("[NewTimelineViewModel] timeline sections monitor failed: \(error)")
                    return nil
                }
            }
            .eraseToAnyAsyncSequence()
            .debounce(for: .milliseconds(100))

        for await sections in sectionUpdates {
            showEmptyStateView = sections.isEmpty

            let revisionBefore = libraryRevision

            guard let rebuilt = await resolveSkeletonLibrary(for: sections) else { continue }
            
            // Two-phase commit: rebuild the skeleton (dirty buckets → placeholders), hydrate the
            // current visible window against it in memory, then publish once — so a re-projected
            // bucket that is on screen shows real content directly instead of flashing to
            // placeholders. The old library stays visible until this new snapshot is ready.
            //
            // This hydration plans against the *prospective* projection — the rebuilt library and
            // the sections that describe it — because `dateSections` still describes what is on
            // screen and does not move until `commitProjection`.
            // The window is the grid's last reported range, which survives a reshape: the reload
            // keeps the content offset, so the user is still near the same flat index. Fall back to
            // the top when it no longer reaches — a much shorter query, or nothing displayed yet.
            let total = sections.reduce(0) { $0 + $1.count }
            let topWindow = total > 0 ? 0..<min(initialHydrationWindowSize, total) : nil
            let reported = photoLibraryContentViewModel.visiblePhotoIndexRange.value
            let range = reported.flatMap { visible -> Range<Int>? in
                // An empty range is an answer ("nothing on screen"); past the end is a stale query.
                guard visible.isEmpty || visible.lowerBound < total else { return nil }
                return visible.clamped(to: 0..<total)
            } ?? topWindow
            let prospective = TimelineProjection(
                library: rebuilt.library, sections: sections, hydratedCoordinates: rebuilt.coordinates)
            var assembled = rebuilt
            if let range, let hydrated = await hydratedVisibleWindow(in: prospective, range: range) {
                // This pass publishes the whole index, so fold in the window's new addresses.
                assembled = IndexedLibrary(
                    library: hydrated.library,
                    coordinates: rebuilt.coordinates.merging(hydrated.addedCoordinates) { current, _ in
                        current
                    })
            }
            // A commit during the `await`s above — a metadata patch, or a scroll hydration that
            // settled on its own window — is absent from `assembled`; publishing as-is would undo it.
            if libraryRevision != revisionBefore {
                let showsHiddenNodes = await !mediaTimelineUseCase.excludeSensitives()
                // Adopting a node only the other side holds claims it belongs to the set this
                // pass publishes — true only if both sides asked for the same query.
                assembled = reconciling(
                    assembled, describedBy: sections, with: publishedProjection,
                    carryingUnseenNodes: photoLibraryContentViewModel.mediaTimelineQuery == query,
                    showsHiddenNodes: showsHiddenNodes)
            }
            // The awaits above outlast a query change: replacing the task cancels it, but a pass
            // already past them would still publish sections counted under the query the user has
            // left — and now stamp them with it.
            guard !Task.isCancelled, timelineQueryId == queryId else { return }
            commitProjection(
                assembled.library, sections: sections,
                coordinates: .replacing(assembled.coordinates), query: query)
        }
    }
    
    func monitorNodeMetadataUpdates() async {
        guard mediaTimelineUseCase != nil else { return }
        // Coalesce update bursts into ~150ms windows and patch once per window, instead of once per SDK batch.
        let windows = nodeUseCase.nodeUpdates
            .chunked(by: .repeating(every: .milliseconds(150)))
        for await batches in windows {
            await patchVisibleMetadata(with: batches.flatMap { $0 })
        }
    }

    /// Replace already-hydrated nodes (matched by handle) whose display-affecting metadata changed
    /// with the updated entity, keeping their flat position (`replacingPhotos(at:)` swaps leaves in
    /// place). Placeholders never match — their handles are synthetic. A no-op unless something
    /// actually changed, so an unchanged burst doesn't churn the tree.
    ///
    /// Driven off the index, so a burst costs a lookup per updated node rather than a walk of the
    /// library. The rebuild that follows runs off the main actor.
    private func patchVisibleMetadata(with updatedNodes: [NodeEntity]) async {
        guard let mediaTimelineUseCase, updatedNodes.isNotEmpty else { return }
        // A node's own sensitivity flip only re-renders in place when hidden items are shown
        // (the node stays, just blurs); when they're excluded, hiding is a membership change
        // the `dateSections` monitor removes — so we must not patch it visible-but-blurred here.
        let showsHiddenNodes = await !mediaTimelineUseCase.excludeSensitives()
        let updatesByHandle = Dictionary(
            updatedNodes.map { ($0.handle, $0) }, uniquingKeysWith: { _, latest in latest })

        let maxOffActorAttempts = 3
        for _ in 0..<maxOffActorAttempts {
            let snapshot = publishedProjection
            let revisionBefore = libraryRevision
            let patched = await patchingMetadataOffActor(
                snapshot, with: updatesByHandle, showsHiddenNodes: showsHiddenNodes)
            // Re-check the revision before acting on the result. If the library moved under us,
            // re-snapshot and retry regardless of whether we found a match: a slot that was a
            // placeholder in the stale snapshot (no match) may have hydrated into a real node our
            // update matches, and a non-nil rebuild would revert the commit that landed. This
            // check-and-commit is synchronous (no `await` between), so nothing can slip in here.
            if libraryRevision != revisionBefore { continue }
            // Stable: nil ⇒ nothing in the current library matches our updates, so there's nothing
            // to do; otherwise commit the rebuilt tree.
            guard let patched else { return }
            commitLibrary(patched)
            return
        }
        // Lost the race on every off-actor attempt (needs repeated concurrent commits — extremely
        // rare); apply on the actor so it can't be raced again.
        if let rebased = applyingMetadata(
            to: publishedProjection, with: updatesByHandle, showsHiddenNodes: showsHiddenNodes) {
            commitLibrary(rebased)
        }
    }

    /// Off-actor wrapper so the metadata rebuild runs on the cooperative pool, not the main actor.
    private nonisolated func patchingMetadataOffActor(
        _ projection: TimelineProjection,
        with updatesByHandle: [HandleEntity: NodeEntity],
        showsHiddenNodes: Bool
    ) async -> PhotoLibrary? {
        applyingMetadata(to: projection, with: updatesByHandle, showsHiddenNodes: showsHiddenNodes)
    }

    /// Pure metadata patch: swap in each updated node the projection already places whose
    /// render-only metadata changed, keeping its flat position; `nil` when nothing changed. Walks
    /// the updates, not the library, and moves nothing, so the index still describes the result.
    private nonisolated func applyingMetadata(
        to projection: TimelineProjection,
        with updatesByHandle: [HandleEntity: NodeEntity],
        showsHiddenNodes: Bool
    ) -> PhotoLibrary? {
        var replacements: [Int: NodeEntity] = [:]
        for (handle, updated) in updatesByHandle {
            // A removal is a count change — leave it to the reproject path; patching it in place
            // would briefly leave a removed node on screen at a stale position.
            guard !updated.isRemoved,
                  let index = projection.flatIndex(ofHandle: handle),
                  let node = projection.hydratedNode(at: index), node.handle == handle,
                  metadataDiffers(node, updated, showsHiddenNodes: showsHiddenNodes) else { continue }
            replacements[index] = updated
        }
        guard replacements.isNotEmpty else { return nil }
        return projection.library.replacingPhotos(at: replacements)
    }

    /// Whether two same-handle nodes differ in a field this in-place patch is allowed to refresh:
    /// render-only fields that don't change a node's **position**. `isMarkedSensitive` counts only
    /// when `showsHiddenNodes` is true
    private nonisolated func metadataDiffers(
        _ lhs: NodeEntity, _ rhs: NodeEntity, showsHiddenNodes: Bool
    ) -> Bool {
        lhs.hasThumbnail != rhs.hasThumbnail
            || lhs.hasPreview != rhs.hasPreview
            || lhs.isFavourite != rhs.isFavourite
            || (showsHiddenNodes && lhs.isMarkedSensitive != rhs.isMarkedSensitive)
    }

    func emptyScreenTypeToShow() -> PhotosEmptyScreenViewType {
        guard !isCameraUploadsEnabled else {
            return .noMediaFound
        }
        return switch photoFilterOptions {
        case [.images, .cloudDrive]:
                .noImagesFound
        case [.videos, .cloudDrive]:
                .noVideosFound
        case [.allMedia, .allLocations], [.allMedia, .cameraUploads],
            [.images, .allLocations], [.images, .cameraUploads],
            [.videos, .allLocations], [.videos, .cameraUploads]:
                .enableCameraUploads
        default: .noMediaFound
        }
    }
    
    func enableCameraUploadsBannerAction(filterLocation: PhotosFilterOptions) -> (() -> Void)? {
        guard shouldShowEnableCameraUploadsBanner(filterLocation: filterLocation) else {
            return nil
        }
        return navigateToCameraUploadSettings
    }
    
    func navigateToCameraUploadSettings() {
        cameraUploadsSettingsViewRouter.start()
    }
    
    /// The menu offers only the two modification-time directions, so anything else normalises to
    /// newest first — matching what the sort menu displays.
    func updateSortOrder(_ newSortOrder: SortOrderEntity) {
        let direction: SortOrderEntity = newSortOrder == .modificationAsc ? .modificationAsc : .modificationDesc
        guard sortOrder != direction else { return }
        sortsOldestFirst = direction == .modificationAsc
        applySortOrder(direction)
    }

    func updateMediaTimelineSortOrder(_ newSortOrder: MediaTimelineSortOrderEntity) {
        guard newSortOrder != mediaTimelineSortOrder else { return }
        let basisChanged = newSortOrder.timestampBasis != timestampBasis
        sortsByDateTaken = newSortOrder.timestampBasis == .mediaCaptureTime

        let newDirection: SortOrderEntity = newSortOrder.isNewestFirst ? .modificationDesc : .modificationAsc
        if newDirection != sortOrder {
            updateSortOrder(newDirection)
        } else if basisChanged {
            applyTimestampBasis()
        }
    }
    
    private func applyTimestampBasis() {
        timelineQueryId = UUID()

        guard mediaTimelineUseCase == nil else {
            loadPhotosTaskId = UUID()
            return
        }

        let photos = photoLibraryContentViewModel.library.allPhotos
        sortPhotoLibraryTask = Task { @MainActor in
            let updatedPhotoLibrary = await buildPhotoLibrary(nodes: photos, sortOrder: sortOrder)

            try Task.checkCancellation()

            commitLibrary(updatedPhotoLibrary)
        }
    }
    
    /// Applies `newSortOrder` to the grid.
    private func applySortOrder(_ newSortOrder: SortOrderEntity) {
        sortOrder = newSortOrder

        // The skeleton is built from date sections fetched in the requested order;
        // locally re-sorting synthetic placeholder nodes would scramble the grid, so
        // trigger a reload instead (the eager path can re-sort its real nodes in place).
        guard mediaTimelineUseCase == nil else {
            loadPhotosTaskId = UUID()
            return
        }

        let photos = photoLibraryContentViewModel.library.allPhotos
        
        sortPhotoLibraryTask = Task { @MainActor in
            let updatedPhotoLibrary = await buildPhotoLibrary(
                nodes: photos, sortOrder: newSortOrder)
            
            try Task.checkCancellation()

            commitLibrary(updatedPhotoLibrary)
        }
    }
    
    func updatePhotoFilter(option: PhotosFilterOptionsEntity) async {
        let newFilterOptions = if PhotosFilterOptionsEntity.mediaOptions.contains(option) {
            option.union(photoFilterOptions.locationSelection)
        } else if PhotosFilterOptionsEntity.locationOptions.contains(option) {
            option.union(photoFilterOptions.mediaSelection)
        } else {
            option
        }
        
        guard photoFilterOptions != newFilterOptions else { return }
        tracker.trackFilterChange(new: option)
        photoFilterOptions = newFilterOptions
        loadPhotosTaskId = UUID()
        
        let filterOptionsToSave = newFilterOptions
        saveFiltersTask = Task { [weak self] in
            guard let self else { return }
            await saveFilters(filterOptions: filterOptionsToSave)
        }
    }
    
    func updateEditMode(_ mode: EditMode) {
        photoLibraryContentViewModel.selection.editMode = mode
    }
    
    private func saveFilters(filterOptions: PhotosFilterOptionsEntity) async {
        guard let mediaType = filterOptions.mediaSelection.toTimelineUserAttributeMediaTypeEntity(),
              let location = filterOptions.locationSelection.toTimelineUserAttributeMediaLocationEntity() else { return }
        
        do {
            let timeline = TimelineUserAttributeEntity(
                mediaType: mediaType,
                location: location,
                usePreference: true)
            
            try await contentConsumptionUserAttributeUseCase.save(timeline: timeline)
            
        } catch let error as JSONCodingErrorEntity {
            MEGALogError("[\(type(of: self))] Unable to save timeline filter. \(error.localizedDescription)")
        } catch {
            MEGALogError(error.localizedDescription)
        }
    }
    
    private func shouldShowEnableCameraUploadsBanner(filterLocation: PhotosFilterOptions) -> Bool {
        guard !isCameraUploadsEnabled else {
            return false
            
        }
        return filterLocation == .cloudDrive
    }
    
    /// Fold freshly-fetched date sections into a rebuilt library, or return `nil` when nothing needs
    /// rebuilding. The reactive section monitor is the only caller: its stream prepends the first
    /// full load, so the initial skeleton and every later reshape come through the same place.
    ///
    /// - Same filter/sort AND structurally-identical shape → every position still maps to the same
    ///   bucket, so there is nothing to rebuild; returns `nil`. The current (possibly hydrated)
    ///   library is kept as-is — a node update that didn't change the timeline shape must not wipe
    ///   hydrated cells back to placeholders, and any metadata change is handled by
    ///   ``monitorNodeMetadataUpdates()``.
    /// - Same filter/sort but the shape moved → rebuild, carrying count-unchanged buckets across to
    ///   the slot their identity maps to in the new layout (so the grid keeps its thumbnails), and
    ///   bump the version of every reshaped bucket to drop in-flight hydration targeting it.
    /// - Filter/sort changed → the old positions are meaningless: fresh placeholder skeleton, bump
    ///   `timelineGeneration` to drop every in-flight hydration, and reset the per-bucket versions.
    ///
    /// The heavy tree work (skeleton build, re-projection) runs off the main actor.
    private func resolveSkeletonLibrary(for sections: [MediaDateSectionEntity]) async -> IndexedLibrary? {
        let filterUnchanged = skeletonFilterOptions == photoFilterOptions
            && skeletonSortOrder == mediaTimelineSortOrder
        if filterUnchanged, sameShape(dateSections, sections) {
            // Identical buckets and counts: nothing maps anywhere new, so this is not a projection
            // change and must not bump `libraryRevision` — assign the refreshed entities directly.
            dateSections = sections
            projectionRevision &+= 1
            return nil
        }

        if filterUnchanged {
            return await reprojecting(publishedProjection, to: sections)
        }

        // A different query makes every old position meaningless, so the invalidation is raised
        // here rather than at the publish: `timelineGeneration` has to rise *before* the skeleton
        // build suspends, or an in-flight fetch from the outgoing query lands in the new one.
        //
        // `dateSections` is deliberately not among them. It is half of the pair `publishedProjection`
        // reads, and moving it before the library would leave every reader during the build holding
        // the old photos against the new bases. It moves with the library, in `commitProjection`.
        skeletonFilterOptions = photoFilterOptions
        skeletonSortOrder = mediaTimelineSortOrder
        timelineGeneration &+= 1
        sectionVersions = [:]
        // Every position was counted under the outgoing query, so nothing positional survives it.
        pendingSelection?.queryDidChange()
        // Nothing carries over, so nothing is addressed yet either.
        return IndexedLibrary(library: await makeSkeleton(from: sections), coordinates: [:])
    }

    /// A library and the index addressing its fetched nodes, so neither travels without the other.
    struct IndexedLibrary {
        let library: PhotoLibrary
        let coordinates: [HandleEntity: TimelineProjection.BucketCoordinate]
    }

    /// A library and the addresses hydration just added. A splice only fills empty slots, so
    /// reporting the delta alone keeps the cost the size of the window, not of the index.
    private struct HydratedWindow {
        let library: PhotoLibrary
        let addedCoordinates: [HandleEntity: TimelineProjection.BucketCoordinate]
    }

    /// How a commit moves the index. Hydration only adds; a rebuilt layout replaces, being the one
    /// that decides what survived the reshape.
    private enum CoordinateUpdate {
        case adding([HandleEntity: TimelineProjection.BucketCoordinate])
        case replacing([HandleEntity: TimelineProjection.BucketCoordinate])
    }

    /// Per-bucket count change between two layouts, for every bucket the new layout still has.
    /// A bucket that vanished needs no entry — its `groupId` is simply gone from the current
    /// sections, which both the apply-time presence check and slot resolution treat as a mismatch.
    private func countDeltas(
        from oldSections: [MediaDateSectionEntity],
        to newSections: [MediaDateSectionEntity]
    ) -> [String: Int] {
        let oldCount = Dictionary(uniqueKeysWithValues: oldSections.map { ($0.groupId, $0.count) })
        var deltas: [String: Int] = [:]
        for section in newSections {
            let old = oldCount[section.groupId] ?? 0
            guard old != section.count else { continue }
            deltas[section.groupId] = section.count - old
        }
        return deltas
    }

    /// Bump the version of every bucket whose count changed (or that appeared under an existing
    /// `groupId`), so an in-flight hydration that captured the old version is discarded before it
    /// writes back.
    private func bumpVersions(for deltas: [String: Int]) {
        for groupId in deltas.keys {
            sectionVersions[groupId, default: 0] += 1
        }
    }

    private nonisolated func makeSkeleton(from sections: [MediaDateSectionEntity]) async -> PhotoLibrary {
        PhotoLibrary.skeleton(from: sections)
    }

    /// Rebuild the skeleton for `newSections`, carrying already-fetched nodes across so the grid
    /// keeps its thumbnails instead of flashing to placeholders. A carried node keeps its offset
    /// within its day bucket and is re-placed at that bucket's new base. Reading the index rather
    /// than the tree keeps the work proportional to the nodes fetched so far.
    ///
    /// Only buckets whose **count is unchanged** are carried. Counts don't say *where* a change
    /// landed (a Camera-Upload insert goes to the FRONT of the newest bucket, shifting every offset
    /// by one), so carrying a changed bucket would misplace nodes — and leave a placeholder whose
    /// true occupant is still elsewhere, which hydration would re-fetch into a second slot. Such a
    /// bucket is re-hydrated from the SDK-ordered result instead.
    ///
    /// Library and index come out of one loop, so neither exists without the other. Off-actor.
    private nonisolated func reprojecting(
        _ projection: TimelineProjection,
        to newSections: [MediaDateSectionEntity]
    ) async -> IndexedLibrary {
        var newBucketBase: [String: Int] = [:]
        var newBucketCount: [String: Int] = [:]
        var cumulative = 0
        for section in newSections {
            newBucketBase[section.groupId] = cumulative
            newBucketCount[section.groupId] = section.count
            cumulative += section.count
        }
        let oldBucketCount = Dictionary(
            projection.sections.map { ($0.groupId, $0.count) }, uniquingKeysWith: { first, _ in first })

        var replacements: [Int: NodeEntity] = [:]
        var carried: [HandleEntity: TimelineProjection.BucketCoordinate] = [:]
        for (handle, coordinate) in projection.hydratedCoordinates {
            guard let count = newBucketCount[coordinate.groupId],
                  oldBucketCount[coordinate.groupId] == count,
                  let base = newBucketBase[coordinate.groupId],
                  let index = projection.flatIndex(ofHandle: handle),
                  let node = projection.hydratedNode(at: index) else { continue }
            replacements[base + coordinate.localOffset] = node
            carried[handle] = coordinate
        }

        return IndexedLibrary(
            library: PhotoLibrary.skeleton(from: newSections).replacingPhotos(at: replacements),
            coordinates: carried)
    }

    /// Fold `published` — a library committed while the pass was suspended — into the snapshot the
    /// pass assembled, so publishing it doesn't undo the commit. Two things can have landed:
    ///
    /// - metadata on a node both sides hold, overlaid in place;
    /// - a node this pass never saw, carried in under the rule ``reprojecting(_:to:)`` uses (its
    ///   bucket must still hold the same number of slots), and only when `carryingUnseenNodes` says
    ///   both sides ran the same query. Shared-handle metadata moves either way, being the node's
    ///   and not the query's.
    ///
    /// Walks the committed side's index, not either library: only a fetched node can be in play.
    nonisolated func reconciling(
        _ assembled: IndexedLibrary,
        describedBy sections: [MediaDateSectionEntity],
        with published: TimelineProjection,
        carryingUnseenNodes: Bool,
        showsHiddenNodes: Bool
    ) -> IndexedLibrary {
        let mine = TimelineProjection(
            library: assembled.library, sections: sections,
            hydratedCoordinates: assembled.coordinates)
        let newCounts = Dictionary(
            sections.map { ($0.groupId, $0.count) }, uniquingKeysWith: { first, _ in first })
        let oldCounts = Dictionary(
            published.sections.map { ($0.groupId, $0.count) }, uniquingKeysWith: { first, _ in first })

        var replacements: [Int: NodeEntity] = [:]
        var coordinates = assembled.coordinates
        for (handle, coordinate) in published.hydratedCoordinates {
            guard let theirIndex = published.flatIndex(ofHandle: handle),
                  let theirs = published.hydratedNode(at: theirIndex) else { continue }

            guard let myIndex = mine.flatIndex(ofHandle: handle) else {
                guard carryingUnseenNodes,
                      let count = newCounts[coordinate.groupId], oldCounts[coordinate.groupId] == count,
                      let target = mine.flatIndex(of: coordinate),
                      mine.isPlaceholder(at: target) else { continue }
                replacements[target] = theirs
                coordinates[handle] = coordinate
                continue
            }

            guard let node = mine.hydratedNode(at: myIndex),
                  metadataDiffers(node, theirs, showsHiddenNodes: showsHiddenNodes) else { continue }
            // Never trade readiness already in hand for a staler node that lacks it.
            if node.hasThumbnail && !theirs.hasThumbnail { continue }
            if node.hasPreview && !theirs.hasPreview { continue }
            replacements[myIndex] = theirs
        }

        return IndexedLibrary(
            library: assembled.library.replacingPhotos(at: replacements), coordinates: coordinates)
    }

    /// Two section lists describe the same skeleton shape when their buckets and per-bucket
    /// counts line up — i.e. every flat position maps to the same bucket, so hydrated nodes
    /// stay valid in place.
    private func sameShape(_ lhs: [MediaDateSectionEntity], _ rhs: [MediaDateSectionEntity]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy { $0.groupId == $1.groupId && $0.count == $1.count }
    }

    /// Drives lazy hydration: as the grid scrolls, the collection-view coordinator publishes the
    /// visible flat-index range; each settled range is fetched and spliced into the skeleton. The
    /// View owns this task, so it is cancelled on disappear. No-op unless the skeleton path is active.
    func monitorVisibleWindowHydration() async {
        guard mediaTimelineUseCase != nil else { return }
        let visibleRanges = photoLibraryContentViewModel.visiblePhotoIndexRange
            .compactMap { $0 }
            .debounce(for: visibleWindowSettleInterval, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .values

        for await range in visibleRanges {
            // Latest-only: assigning a new task cancels the previous in-flight hydration.
            hydrationTask = Task { [weak self] in
                await self?.hydrateVisibleWindow(range)
            }
        }
    }

    func hydrateVisibleWindow(_ range: Range<Int>) async {
        let revisionBefore = libraryRevision
        guard let hydrated = await hydratedVisibleWindow(in: publishedProjection, range: range) else { return }
        guard libraryRevision == revisionBefore else { return }
        commitProjection(
            hydrated.library, sections: nil, coordinates: .adding(hydrated.addedCoordinates))
    }

    /// Publishes `nodes` from `startIndex` and records where they landed — the commit a fetch of
    /// that window would have made. Test-facing: assigning `photoLibraryContentViewModel.library`
    /// directly instead would leave the index describing a library that no longer exists.
    func commitHydratedRun(from startIndex: Int, with nodes: [NodeEntity]) {
        let projection = publishedProjection
        var added: [HandleEntity: TimelineProjection.BucketCoordinate] = [:]
        for (offset, node) in nodes.enumerated() {
            guard let anchor = projection.sectionAnchor(forFlatIndex: startIndex + offset) else { continue }
            added[node.handle] = .init(
                groupId: anchor.section.groupId, localOffset: anchor.localOffset)
        }
        commitProjection(
            projection.library.replacingPhotos(from: startIndex, with: nodes),
            sections: nil,
            coordinates: .adding(added))
    }

    /// Plan, fetch and splice the real nodes for `range` against `projection`, returning the
    /// hydrated result — nil if there was nothing to fill, or a query/section change invalidated
    /// the work before it could be applied.
    ///
    /// Every stage reads the projection it is handed, never `dateSections`: planning reads a
    /// layout, the fetch suspends, then the splice resolves positions again.
    ///
    /// Pure with respect to the published library, so the reactive path can assemble a snapshot
    /// off-screen (two-phase commit) while the scroll-driven path commits straight away.
    private func hydratedVisibleWindow(
        in projection: TimelineProjection, range: Range<Int>
    ) async -> HydratedWindow? {
        guard mediaTimelineUseCase != nil else { return nil }

        let planned = planHydrationRuns(range: range, in: projection)
        guard planned.isNotEmpty else { return nil }

        let generation = timelineGeneration
        let capturedVersions = capturedVersions(spanning: range, in: projection)
        let results = await fetchHydrationRuns(planned, in: projection)

        return await applyHydrationResults(
            results, to: projection, generation: generation, capturedVersions: capturedVersions)
    }

    private func isCurrentQuery(_ generation: Int) -> Bool {
        generation == timelineGeneration
    }

    /// Split `range` into the contiguous placeholder runs it contains: a run flanked by an
    /// already-hydrated real node is grown from that anchor by cursor (drift-safe), while an
    /// isolated cold run teleports in by absolute offset. A range mixing both is handled per-run.
    private func planHydrationRuns(
        range: Range<Int>, in projection: TimelineProjection
    ) -> [PlaceholderRun] {
        let clampedUpper = min(range.upperBound, projection.itemCount)
        guard range.lowerBound < clampedUpper else { return [] }
        return placeholderRuns(in: range.lowerBound..<clampedUpper, of: projection)
    }

    /// Execute `planned` sequentially, as visible-window hydration does today.
    private func fetchHydrationRuns(
        _ planned: [PlaceholderRun],
        in projection: TimelineProjection
    ) async -> [RunFetchResult] {
        guard let mediaTimelineUseCase else { return [] }
        let generation = timelineGeneration
        var results: [RunFetchResult] = []
        for run in planned {
            // The guard is on the query generation only: a reshape mid-fetch must not abort the
            // run — its result is validated per-bucket at apply time instead.
            //
            // Cancellation drops the runs already fetched rather than returning them. A cancelled
            // hydration is one a newer visible range replaced; letting its partial result commit
            // would bump `libraryRevision` under the replacement and get *that* — the window the
            // user is actually looking at — discarded by the revision guard in
            // ``hydrateVisibleWindow(_:)``.
            guard !Task.isCancelled, isCurrentQuery(generation) else { return [] }
            switch await fetchRun(run, in: projection, using: mediaTimelineUseCase) {
            case .landed(let result):
                results.append(result)
            case .empty:
                MEGALogDebug("[\(type(of: self))] run hydration found no nodes for \(run.range)")
            case .unanchored:
                MEGALogDebug("[\(type(of: self))] run hydration found no bucket for \(run.range)")
            case .cancelled:
                // Drops what already landed, for the reason above; the loop used to see this only
                // on its next turn, so a run cancelled last still returned the ones before it.
                return []
            case .failed(let error):
                MEGALogError("[\(type(of: self))] run hydration failed: \(error)")
            }
        }
        return results
    }

    /// Maximal runs of consecutive placeholder slots inside `visible`, each tagged with the real
    /// node (if any) immediately above and below it — the anchors that decide cursor vs offset.
    /// Neighbours are read from the whole tree, so a real node just outside the visible window
    /// still seeds a cursor fetch.
    private func placeholderRuns(
        in visible: Range<Int>, of projection: TimelineProjection
    ) -> [PlaceholderRun] {
        var runs: [PlaceholderRun] = []
        var index = visible.lowerBound
        while index < visible.upperBound {
            guard projection.isPlaceholder(at: index) else {
                index += 1
                continue
            }
            var end = index
            while end < visible.upperBound, projection.isPlaceholder(at: end) { end += 1 }
            runs.append(PlaceholderRun(
                range: index..<end,
                upperNeighbour: anchor(at: index - 1, in: projection),
                lowerNeighbour: anchor(at: end, in: projection)))
            index = end
        }
        return runs
    }

    /// The real node at a flat index paired with where it sits; nil for a placeholder or outside
    /// the tree. Read together so the two cannot name different slots.
    private func anchor(at index: Int, in projection: TimelineProjection) -> RunAnchor? {
        guard let node = projection.hydratedNode(at: index),
              let section = projection.sectionAnchor(forFlatIndex: index) else { return nil }
        return RunAnchor(
            node: node,
            coordinate: .init(groupId: section.section.groupId, localOffset: section.localOffset))
    }

    /// Dispatch one run to the correct fetch. An adjacent real node is preferred as a cursor anchor
    /// (upper by convention when both sides are real); with no real neighbour the run is an isolated
    /// cold region, filled by an absolute-offset window from its date-bucket anchor.
    private func fetchRun(
        _ run: PlaceholderRun,
        in projection: TimelineProjection,
        using mediaTimelineUseCase: some MediaTimelineUseCaseProtocol
    ) async -> RunFetchOutcome {
        let filter = photoFilterOptions.toMediaTimelineFilterEntity()
        let order = mediaTimelineSortOrder
        do {
            if let upper = run.upperNeighbour {
                let nodes = try await mediaTimelineUseCase.mediaPage(
                    filter: filter, sortOrder: order, after: upper.node, limit: run.range.count)
                try Task.checkCancellation()
                return nodes.isEmpty
                    ? .empty
                    : .landed(RunFetchResult(run: run, kind: .pageAfter(upper.coordinate), nodes: nodes))
            } else if let lower = run.lowerNeighbour {
                let nodes = try await mediaTimelineUseCase.mediaPage(
                    filter: filter, sortOrder: order, before: lower.node, limit: run.range.count)
                try Task.checkCancellation()
                return nodes.isEmpty
                    ? .empty
                    : .landed(RunFetchResult(run: run, kind: .pageBefore(lower.coordinate), nodes: nodes))
            } else {
                guard let anchor = projection.sectionAnchor(
                    forFlatIndex: run.range.lowerBound) else { return .unanchored }
                let nodes = try await mediaTimelineUseCase.mediaWindow(
                    filter: filter, section: anchor.section, sortOrder: order,
                    offset: anchor.localOffset, limit: run.range.count)
                try Task.checkCancellation()
                guard nodes.isNotEmpty else { return .empty }
                return .landed(RunFetchResult(
                    run: run,
                    kind: .offset(.init(
                        groupId: anchor.section.groupId, localOffset: anchor.localOffset)),
                    nodes: nodes))
            }
        } catch is CancellationError {
            return .cancelled
        } catch {
            return .failed(error)
        }
    }

    /// Fold every run's fetched nodes into one combined splice against `projection`, nil if nothing
    /// landed. Each run resolves its start from a bucket address, so a reshape elsewhere — which
    /// shifts absolute indices — still lands it correctly. `replacingPhotos(at:)` keeps the section
    /// shape, so only the swapped cells reconfigure: no reload, no jump. Runs off the main actor.
    private func applyHydrationResults(
        _ results: [RunFetchResult],
        to projection: TimelineProjection,
        generation: Int,
        capturedVersions: [String: UInt]
    ) async -> HydratedWindow? {
        guard results.isNotEmpty else { return nil }
        // Cancellation landing inside the *last* run surfaces as that run yielding nothing, so the
        // fetch loop exits normally with the earlier runs still in hand; this is where those get
        // dropped.
        guard !Task.isCancelled else { return nil }
        guard generation == timelineGeneration,
              versionsStillValid(capturedVersions, against: projection) else { return nil }

        // The addresses this splice adds — with the projection's own, also its duplicate check: a
        // handle in either is already live in the tree, or was placed by an earlier run here.
        var added: [HandleEntity: TimelineProjection.BucketCoordinate] = [:]
        var replacements: [Int: NodeEntity] = [:]
        for result in results {
            guard let start = spliceStart(for: result, in: projection) else { continue }
            for (offset, node) in result.nodes.enumerated() where offset < result.run.range.count {
                let index = start + offset
                // Only fill placeholder slots — never overwrite a hydrated node or overflow the
                // tree, whatever the SDK returned. Nor a slot this batch already filled: taking the
                // second node would leave the first addressed at a slot it no longer occupies.
                guard projection.isPlaceholder(at: index), replacements[index] == nil,
                      projection.hydratedCoordinates[node.handle] == nil, added[node.handle] == nil,
                      let anchor = projection.sectionAnchor(forFlatIndex: index) else { continue }
                added[node.handle] = .init(
                    groupId: anchor.section.groupId, localOffset: anchor.localOffset)
                replacements[index] = node
            }
        }
        guard replacements.isNotEmpty else { return nil }

        let hydrated = await splicing(projection.library, replacing: replacements)
        guard generation == timelineGeneration,
              versionsStillValid(capturedVersions, against: projection) else { return nil }
        return HydratedWindow(library: hydrated, addedCoordinates: added)
    }

    /// Every captured bucket must still exist and carry the version it had when the hydration
    /// started; otherwise that bucket was reshaped/removed and the fetch is stale.
    private func versionsStillValid(
        _ captured: [String: UInt], against projection: TimelineProjection
    ) -> Bool {
        captured.allSatisfy { groupId, version in
            projection.containsSection(groupId: groupId) && sectionVersions[groupId, default: 0] == version
        }
    }

    /// The current version of every day bucket the flat `range` overlaps, captured when a hydration
    /// starts so ``versionsStillValid(_:)`` can reject it if any of those buckets later reshaped.
    private func capturedVersions(
        spanning range: Range<Int>, in projection: TimelineProjection
    ) -> [String: UInt] {
        var captured: [String: UInt] = [:]
        for groupId in projection.groupIds(spanning: range) {
            captured[groupId] = sectionVersions[groupId, default: 0]
        }
        return captured
    }

    /// The flat index the first fetched node lands at, resolved against the layout as it stands so
    /// a reshape elsewhere doesn't misplace the fill. An offset run starts at its own address,
    /// `after` fills below its anchor, `before` fills the run's tail just above the lower anchor.
    private func spliceStart(for result: RunFetchResult, in projection: TimelineProjection) -> Int? {
        switch result.kind {
        case .offset(let coordinate):
            return projection.flatIndex(of: coordinate)
        case .pageAfter(let anchor):
            guard let index = projection.flatIndex(of: anchor) else { return nil }
            return index + 1
        case .pageBefore(let anchor):
            guard let index = projection.flatIndex(of: anchor) else { return nil }
            return max(0, index - result.nodes.count)
        }
    }

    private nonisolated func splicing(
        _ library: PhotoLibrary, replacing replacements: [Int: NodeEntity]) async -> PhotoLibrary {
        library.replacingPhotos(at: replacements)
    }

    /// A contiguous span of placeholder slots in the visible window, plus the real nodes (if any)
    /// bordering it — the anchors that decide how the run is fetched.
    private struct PlaceholderRun: Sendable {
        let range: Range<Int>
        let upperNeighbour: RunAnchor?
        let lowerNeighbour: RunAnchor?
    }

    /// A real node bordering a run: the cursor the SDK pages from, and where that node sits.
    private struct RunAnchor: Sendable {
        let node: NodeEntity
        let coordinate: TimelineProjection.BucketCoordinate
    }

    /// How a run was fetched, with the bucket address its splice position is re-derived from, so a
    /// reshape between fetch and apply can't pin it to a stale absolute index.
    private enum RunFetchKind: Sendable {
        case pageAfter(TimelineProjection.BucketCoordinate)
        case pageBefore(TimelineProjection.BucketCoordinate)
        case offset(TimelineProjection.BucketCoordinate)
    }

    private struct RunFetchResult: Sendable {
        let run: PlaceholderRun
        let kind: RunFetchKind
        let nodes: [NodeEntity]
    }

    /// What one run fetch produced. It used to be `RunFetchResult?`, where `nil` meant a
    /// cancellation, an empty page, a missing anchor and a failure alike — and only an answered
    /// query says anything about the positions covered, which a caller that retries has to know.
    private enum RunFetchOutcome {
        /// The query answered with nodes for the run.
        case landed(RunFetchResult)
        /// The query answered, and the run is still blank.
        case empty
        /// The run no longer starts inside a date bucket, so nothing was asked.
        case unanchored
        /// Dropped before it could answer, so it says nothing about the run.
        case cancelled
        case failed(any Error)
    }

    private func timelinePhotoLibrary() async throws -> PhotoLibrary {
        let photos = try await photoLibraryUseCase.media(
            for: photoFilterOptions,
            excludeSensitive: nil)
            .lazy
            .filter(\.hasThumbnail)
        
        try Task.checkCancellation()
        
        showEmptyStateView = photos.isEmpty
        
        try Task.checkCancellation()
        
        return await buildPhotoLibrary(nodes: Array(photos), sortOrder: sortOrder)
    }
    
    private func buildPhotoLibrary(
        nodes: [NodeEntity],
        sortOrder: SortOrderEntity
    ) async -> PhotoLibrary {
        let timestampBasis = timestampBasis
        return await Task.detached(priority: .userInitiated) {
            nodes.toPhotoLibrary(withSortType: sortOrder, timestampBasis: timestampBasis)
        }.value
    }
    
    private func handleNodeUpdates(with updatedNodes: [NodeEntity]) {
        guard currentNodeUpdateTask == nil else {
            pendingNodeUpdates.append(contentsOf: updatedNodes)
            return
        }
        processNodeUpdates(updatedNodes)
    }
    
    private func processNodeUpdates(_ nodes: [NodeEntity]) {
        currentNodeUpdateTask = Task { [weak self] in
            guard let self else { return }
            
            defer { currentNodeUpdateTask = nil }
            
            do {
                let container = await photoLibraryUseCase.photoLibraryContainer()
                
                try Task.checkCancellation()
                
                guard shouldProcessOnNodesUpdate(nodes: nodes, container: container) else { return }
                
                await loadPhotos()
                
                try Task.checkCancellation()
                
                processPendingNodeUpdates()
            } catch is CancellationError {
                MEGALogDebug("[\(type(of: self))] Node update processing cancelled")
                pendingNodeUpdates.removeAll()
            } catch {
                MEGALogError("[\(type(of: self))] Error processing node updates: \(error)")
                processPendingNodeUpdates()
            }
        }
    }
    
    private func shouldProcessOnNodesUpdate(
        nodes: [NodeEntity],
        container: PhotoLibraryContainerEntity
    ) -> Bool {
        let locationSelection = photoFilterOptions.locationSelection
        return if locationSelection.contains(.cloudDrive) {
            nodes.contains {
                $0.fileExtensionGroup.isVisualMedia && $0.hasThumbnail
            }
        } else if locationSelection.contains(.cameraUploads) {
            container.cameraUploadNode?.shouldProcessOnNodeEntitiesUpdate(
                withChildNodes: photoLibraryContentViewModel.library.allPhotos,
                updatedNodes: nodes) ?? false
        } else {
            false
        }
    }
    
    private func processPendingNodeUpdates() {
        guard pendingNodeUpdates.isNotEmpty else { return }
        
        let nodesToProcess = pendingNodeUpdates
        pendingNodeUpdates.removeAll()
        processNodeUpdates(nodesToProcess)
    }
    
    private func loadSavedFilters() async throws {
        let timelineAttributes = await contentConsumptionUserAttributeUseCase.fetchTimelineAttribute()
        
        try Task.checkCancellation()
        
        guard timelineAttributes.usePreference else { return }
        
        let savedFilters = timelineAttributes.toPhotoFilterOptionsEntity()
        
        guard photoFilterOptions != savedFilters else { return }
        photoFilterOptions = savedFilters
    }
}

// MARK: - TimelineSelectionResolving

extension NewTimelineViewModel: TimelineSelectionResolving {
    var selectionProjection: TimelineProjection { publishedProjection }

    var selectionQueryGeneration: Int { timelineGeneration }

    /// Fetch and publish the nodes for a stretch of marked positions, through the same path the
    /// visible window uses — so the commit that lands them promotes their marks on its way out.
    func hydrateForSelection(_ range: Range<Int>) async -> TimelineSelectionHydrationOutcome {
        let projection = publishedProjection
        let generation = timelineGeneration
        let versions = capturedVersions(spanning: range, in: projection)
        let revisionBefore = libraryRevision

        let startedAt = Date()
        guard let hydrated = await hydratedVisibleWindow(in: projection, range: range) else {
            let invalidated = generation != timelineGeneration
                || libraryRevision != revisionBefore
                || !versionsStillValid(versions, against: publishedProjection)
            let outcome: TimelineSelectionHydrationOutcome = invalidated ? .discarded : .unproductive
            log(selectionRequest: range, from: startedAt, outcome: outcome)
            return outcome
        }
        guard libraryRevision == revisionBefore else {
            log(selectionRequest: range, from: startedAt, outcome: .discarded)
            return .discarded
        }
        commitProjection(
            hydrated.library, sections: nil, coordinates: .adding(hydrated.addedCoordinates))
        log(selectionRequest: range, from: startedAt, outcome: .committed)
        return .committed
    }

    /// The three numbers that say whether a request bound is ever needed: how many cells one
    /// selection request covers, how long its query took, and how often a reshape threw it away.
    private func log(
        selectionRequest range: Range<Int>, from startedAt: Date,
        outcome: TimelineSelectionHydrationOutcome
    ) {
        let milliseconds = Int(Date().timeIntervalSince(startedAt) * 1000)
        MEGALogDebug(
            "[TimelineSelection] \(range.count) slots in \(milliseconds)ms → \(outcome)")
    }
}
