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
    
    private var isInitialLoadComplete = false
    private var pendingNodeUpdates: [NodeEntity] = []

    /// The count-based sections backing the current skeleton, kept so a visible flat-index
    /// window can be mapped to a `section + local offset` fetch. Only populated on the
    /// skeleton path.
    private var dateSections: [MediaDateSectionEntity] = []

    private var skeletonFilterOptions: PhotosFilterOptionsEntity?
    private var skeletonSortOrder: SortOrderEntity?

    private let initialHydrationWindowSize = 60

    /// Bumped only when the query changes (filter/sort) and the skeleton is rebuilt from scratch.
    /// Every in-flight hydration captures it and is discarded if it changed — a different query
    /// invalidates even a handle-anchored page. (The design doc calls this `timelineGeneration`.)
    private var timelineGeneration = 0

    /// Version per day bucket (`groupId`), bumped when that bucket's count changes in a reactive
    /// pass. A hydration captures the versions of the buckets its visible range spans and is
    /// discarded if any changed (or vanished) before it returns — so a reshape invalidates only
    /// fetches targeting the reshaped bucket, never hydration for the bucket the user is viewing.
    private var sectionVersions: [String: UInt] = [:]

    /// The latest settled visible flat-index range, captured on each scroll-driven hydration so the
    /// reactive path can hydrate that same window against a freshly-rebuilt skeleton *before*
    /// committing (two-phase commit) — showing real content directly instead of a placeholder flash.
    private var lastVisibleRange: Range<Int>?

    /// Bumped on every library commit made through ``commitLibrary(_:)``. The reactive section pass
    /// captures it before its `await`s and re-checks it before committing: if it changed, a metadata
    /// patch (or other commit) landed while the pass was suspended, so the pass — built from a now
    /// stale snapshot — merges the current library's fresher per-node metadata in before publishing,
    /// instead of reverting it.
    private var libraryRevision = 0

    private(set) var photoFilterOptions: PhotosFilterOptionsEntity = [.allMedia, .allLocations]
    private(set) var sortOrder: SortOrderEntity = .modificationDesc
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
    
    init(
        photoLibraryContentViewModel: PhotoLibraryContentViewModel,
        photoLibraryContentViewRouter: PhotoLibraryContentViewRouter,
        cameraUploadsSettingsViewRouter: some Routing,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol,
        mediaTimelineUseCase: (any MediaTimelineUseCaseProtocol)? = nil,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.photoLibraryContentViewModel = photoLibraryContentViewModel
        self.photoLibraryContentViewRouter = photoLibraryContentViewRouter
        self.cameraUploadsSettingsViewRouter = cameraUploadsSettingsViewRouter
        self.photoLibraryUseCase = photoLibraryUseCase
        self.nodeUseCase = nodeUseCase
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.mediaTimelineUseCase = mediaTimelineUseCase
        self.tracker = tracker
        $isCameraUploadsEnabled.useCase = preferenceUseCase
    }
    
    func onViewDisappear() {
        currentNodeUpdateTask = nil
        sortPhotoLibraryTask = nil
        saveFiltersTask = nil
        hydrationTask = nil
    }
    
    func loadPhotos() async {
        defer { isInitialLoadComplete = true }
        do {
            if !isInitialLoadComplete {
                try await loadSavedFilters()
            }
            commitLibrary(try await loadTimelineLibrary())
        } catch is CancellationError {
            MEGALogError("[\(type(of: self))] loadPhotos cancelled")
        } catch {
            MEGALogError("[\(type(of: self))] - error loading photos \(error)")
        }
    }

    /// Single funnel for publishing a new library. Bumps ``libraryRevision`` so a concurrent
    /// reactive pass can detect that the library moved under it (see ``libraryRevision``).
    private func commitLibrary(_ library: PhotoLibrary) {
        libraryRevision &+= 1
        photoLibraryContentViewModel.library = library
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
        let sectionUpdates = await mediaTimelineUseCase.monitorDateSections(
            filter: photoFilterOptions.toMediaTimelineFilterEntity(),
            granularity: .day,
            sortOrder: sortOrder.toMediaTimelineSortOrderEntity())
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
            .debounce(for: .milliseconds(300))

        for await sections in sectionUpdates {
            showEmptyStateView = sections.isEmpty

            let revisionBefore = libraryRevision

            guard let rebuilt = await resolveSkeletonLibrary(for: sections) else { continue }
            
            // Two-phase commit: rebuild the skeleton (dirty buckets → placeholders), hydrate the
            // current visible window against it in memory, then publish once — so a re-projected
            // bucket that is on screen shows real content directly instead of flashing to
            // placeholders. The old library stays visible until this new snapshot is ready.
            let range = photoLibraryContentViewModel.visiblePhotoIndexRange.value ?? lastVisibleRange
            var assembled = rebuilt
            if let range, let hydrated = await hydratedVisibleWindow(of: rebuilt, range: range) {
                assembled = hydrated
            }
            // If a metadata patch committed during the `await`s above, `assembled` was built from a
            // pre-patch snapshot and would revert it.
            if libraryRevision != revisionBefore {
                assembled = assembled.mergingMetadata(from: photoLibraryContentViewModel.library) { mine, other in
                    guard metadataDiffers(mine, other) else { return false }
                    if mine.hasThumbnail && !other.hasThumbnail { return false }
                    if mine.hasPreview && !other.hasPreview { return false }
                    return true
                }
            }
            commitLibrary(assembled)
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
    /// The O(total) flatten + scan + tree rebuild runs off the main actor so a Camera-Upload
    /// burst on a very large library doesn't do heavy work on the main thread.
    private func patchVisibleMetadata(with updatedNodes: [NodeEntity]) async {
        guard mediaTimelineUseCase != nil, updatedNodes.isNotEmpty else { return }
        let updatesByHandle = Dictionary(
            updatedNodes.map { ($0.handle, $0) }, uniquingKeysWith: { _, latest in latest })

        let maxOffActorAttempts = 3
        for _ in 0..<maxOffActorAttempts {
            let snapshot = photoLibraryContentViewModel.library
            let revisionBefore = libraryRevision
            let patched = await patchingMetadataOffActor(snapshot, with: updatesByHandle)
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
        if let rebased = applyingMetadata(to: photoLibraryContentViewModel.library, with: updatesByHandle) {
            commitLibrary(rebased)
        }
    }

    /// Off-actor wrapper so the metadata rebuild runs on the cooperative pool, not the main actor.
    private nonisolated func patchingMetadataOffActor(
        _ library: PhotoLibrary,
        with updatesByHandle: [HandleEntity: NodeEntity]
    ) async -> PhotoLibrary? {
        applyingMetadata(to: library, with: updatesByHandle)
    }

    /// Pure metadata patch: swap in each updated node whose handle matches a real (non-placeholder)
    /// slot and whose render-only metadata actually changed, keeping its flat position. Returns `nil`
    /// when nothing changed, so the caller commits only real work.
    private nonisolated func applyingMetadata(
        to library: PhotoLibrary,
        with updatesByHandle: [HandleEntity: NodeEntity]
    ) -> PhotoLibrary? {
        var replacements: [Int: NodeEntity] = [:]
        for (index, node) in library.allPhotos.enumerated() where !node.isTimelinePlaceholder {
            // A removal is a count change — leave it to the reproject path; patching it in place
            // would briefly leave a removed node on screen at a stale position.
            guard let updated = updatesByHandle[node.handle],
                  !updated.isRemoved,
                  metadataDiffers(node, updated) else { continue }
            replacements[index] = updated
        }
        guard replacements.isNotEmpty else { return nil }
        return library.replacingPhotos(at: replacements)
    }

    /// Whether two same-handle nodes differ in a field this in-place patch is allowed to refresh:
    /// render-only fields that don't change a node's **position** or **filter membership**.
    private nonisolated func metadataDiffers(_ lhs: NodeEntity, _ rhs: NodeEntity) -> Bool {
        lhs.hasThumbnail != rhs.hasThumbnail
            || lhs.hasPreview != rhs.hasPreview
            || lhs.isFavourite != rhs.isFavourite
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
    
    func updateSortOrder(_ newSortOrder: SortOrderEntity) {
        guard sortOrder != newSortOrder else { return }
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
    
    private func loadTimelineLibrary() async throws -> PhotoLibrary {
        if let mediaTimelineUseCase {
            try await skeletonPhotoLibrary(using: mediaTimelineUseCase)
        } else {
            try await timelinePhotoLibrary()
        }
    }

    /// Builds the count-sized skeleton *and* hydrates its first window in one step, so the initial
    /// commit already shows real thumbnails for the top screen rather than a wall of placeholders
    /// that fills in a moment later.
    private func skeletonPhotoLibrary(
        using mediaTimelineUseCase: some MediaTimelineUseCaseProtocol
    ) async throws -> PhotoLibrary {
        let filter = photoFilterOptions.toMediaTimelineFilterEntity()
        let order = sortOrder.toMediaTimelineSortOrderEntity()

        async let firstPageTask = mediaTimelineUseCase.mediaPage(
            filter: filter, sortOrder: order, after: nil, limit: initialHydrationWindowSize)
        let sections = try await mediaTimelineUseCase.dateSections(
            filter: filter, granularity: .day, sortOrder: order)

        try Task.checkCancellation()

        showEmptyStateView = sections.isEmpty
        guard let skeleton = await resolveSkeletonLibrary(for: sections) else {
            // Shape unchanged (a no-op reload): keep the current — possibly already hydrated —
            // library rather than dropping it back to a placeholder skeleton.
            return photoLibraryContentViewModel.library
        }

        // A failed / cancelled first page just means the top screen hydrates on scroll instead —
        // never block the skeleton on it. `try?` swallows the first-page error, so re-check
        // cancellation afterwards: a filter/sort switch cancels this `.task`, and without this a
        // stale skeleton could fall through and be committed over the newer query's result.
        let firstPage = (try? await firstPageTask) ?? []
        try Task.checkCancellation()
        guard firstPage.isNotEmpty else { return skeleton }
        return skeleton.replacingPhotos(from: 0, with: firstPage)
    }

    /// Fold freshly-fetched date sections into a rebuilt library, or return `nil` when nothing needs
    /// rebuilding. Shared by the initial / filter-driven load and the reactive section monitor.
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
    private func resolveSkeletonLibrary(for sections: [MediaDateSectionEntity]) async -> PhotoLibrary? {
        let filterUnchanged = skeletonFilterOptions == photoFilterOptions
            && skeletonSortOrder == sortOrder
        if filterUnchanged, sameShape(dateSections, sections) {
            dateSections = sections
            return nil
        }

        if filterUnchanged {
            let oldSections = dateSections
            let current = photoLibraryContentViewModel.library
            bumpVersions(from: oldSections, to: sections)
            dateSections = sections
            return await reprojecting(current, from: oldSections, to: sections)
        }

        dateSections = sections
        skeletonFilterOptions = photoFilterOptions
        skeletonSortOrder = sortOrder
        timelineGeneration += 1
        sectionVersions = [:]
        return await makeSkeleton(from: sections)
    }

    /// Bump the version of every bucket whose count changed (or that appeared under an existing
    /// `groupId`), so an in-flight hydration that captured the old version is discarded before it
    /// writes back. A bucket that vanished needs no bump — its `groupId` is simply gone from the
    /// current sections, which the apply-time presence check treats as a mismatch.
    private func bumpVersions(
        from oldSections: [MediaDateSectionEntity],
        to newSections: [MediaDateSectionEntity]
    ) {
        let oldCount = Dictionary(uniqueKeysWithValues: oldSections.map { ($0.groupId, $0.count) })
        for section in newSections where oldCount[section.groupId] != section.count {
            sectionVersions[section.groupId, default: 0] += 1
        }
    }

    private nonisolated func makeSkeleton(from sections: [MediaDateSectionEntity]) async -> PhotoLibrary {
        PhotoLibrary.skeleton(from: sections)
    }

    /// Rebuild the skeleton for `newSections`, carrying already-hydrated real nodes across so the
    /// grid keeps its thumbnails instead of flashing to placeholders. A carried node keeps its
    /// offset within its day bucket and is re-placed at that bucket's new base — its absolute flat
    /// index shifts when an earlier bucket resizes, but its content survives.
    ///
    /// Only buckets whose **count is unchanged** are carried. A bucket that grew or shrank is left
    /// entirely as placeholders: counts alone don't say *where* the change landed (a Camera-Upload
    /// insert lands at the FRONT of the newest bucket, shifting every node's offset by one), so
    /// carrying its old offsets would misplace nodes — and, worse, leave a placeholder whose true
    /// occupant is a node still present elsewhere, which the visible-window hydration would then
    /// re-fetch into a second slot, duplicating it. A changed bucket is instead re-hydrated
    /// authoritatively from the SDK-ordered result. Pure and off-actor: an O(total photos) rebuild.
    private nonisolated func reprojecting(
        _ library: PhotoLibrary,
        from oldSections: [MediaDateSectionEntity],
        to newSections: [MediaDateSectionEntity]
    ) async -> PhotoLibrary {
        let photos = library.allPhotos

        var newBucketBase: [String: Int] = [:]
        var newBucketCount: [String: Int] = [:]
        var cumulative = 0
        for section in newSections {
            newBucketBase[section.groupId] = cumulative
            newBucketCount[section.groupId] = section.count
            cumulative += section.count
        }

        // Walk the current library alongside the OLD sections (the layout it was built from) so
        // each real node's `(groupId, localOffset)` is known, then place count-unchanged buckets at
        // their new base. `defer` keeps `index` aligned with `photos` even for skipped buckets.
        var replacements: [Int: NodeEntity] = [:]
        var index = 0
        for section in oldSections {
            let carryBucket = newBucketCount[section.groupId] == section.count
            for localOffset in 0..<section.count {
                defer { index += 1 }
                guard carryBucket, photos.indices.contains(index) else { continue }
                let node = photos[index]
                guard !node.isTimelinePlaceholder,
                      let base = newBucketBase[section.groupId] else { continue }
                replacements[base + localOffset] = node
            }
        }

        return PhotoLibrary.skeleton(from: newSections).replacingPhotos(at: replacements)
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
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
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
        lastVisibleRange = range
        let current = photoLibraryContentViewModel.library
        guard let hydrated = await hydratedVisibleWindow(of: current, range: range) else { return }
        commitLibrary(hydrated)
    }

    /// Fetch and splice the real nodes for `range` against `library`, returning the hydrated result
    /// (or nil if there was nothing to fill, or the work was invalidated by a query/section change
    /// before it could be applied). Pure with respect to the published library — the caller decides
    /// when to commit, so the reactive path can assemble a new snapshot off-screen (two-phase commit)
    /// while the scroll-driven path commits straight away.
    private func hydratedVisibleWindow(of library: PhotoLibrary, range: Range<Int>) async -> PhotoLibrary? {
        guard let mediaTimelineUseCase else { return nil }

        let photos = library.allPhotos
        let clampedUpper = min(range.upperBound, photos.count)
        guard range.lowerBound < clampedUpper else { return nil }

        // Split the visible window into contiguous placeholder runs rather than fetching it as a
        // whole: a run flanked by an already-hydrated real node is grown from that anchor by cursor
        // (drift-safe), while an isolated cold run teleports in by absolute offset. A window mixing
        // both is handled per-run.
        let runs = placeholderRuns(in: range.lowerBound..<clampedUpper, photos: photos)
        guard runs.isNotEmpty else { return nil }

        let generation = timelineGeneration
        let capturedVersions = capturedVersions(spanning: range.lowerBound..<clampedUpper)
        var results: [RunFetchResult] = []
        for run in runs {
            // Loop guard is on the query generation only: a reshape mid-fetch must not abort the
            // run — its result is validated per-bucket at apply time instead.
            guard !Task.isCancelled, generation == timelineGeneration else { return nil }
            if let result = await fetchRun(run, using: mediaTimelineUseCase) {
                results.append(result)
            }
        }
        return await splicedLibrary(
            library, results: results, generation: generation, capturedVersions: capturedVersions)
    }

    /// Maximal runs of consecutive placeholder slots inside `visible`, each tagged with the real
    /// node (if any) immediately above and below it — the anchors that decide cursor vs offset.
    /// Neighbours are read from the full `photos` list, so a real node just outside the visible
    /// window still seeds a cursor fetch.
    private func placeholderRuns(in visible: Range<Int>, photos: [NodeEntity]) -> [PlaceholderRun] {
        var runs: [PlaceholderRun] = []
        var index = visible.lowerBound
        while index < visible.upperBound {
            guard photos[index].isTimelinePlaceholder else {
                index += 1
                continue
            }
            var end = index
            while end < visible.upperBound, photos[end].isTimelinePlaceholder { end += 1 }
            let above = index - 1
            let below = end
            runs.append(PlaceholderRun(
                range: index..<end,
                upperNeighbour: above >= 0 && !photos[above].isTimelinePlaceholder ? photos[above] : nil,
                lowerNeighbour: below < photos.count && !photos[below].isTimelinePlaceholder ? photos[below] : nil))
            index = end
        }
        return runs
    }

    /// Dispatch one run to the correct fetch. An adjacent real node is preferred as a cursor anchor
    /// (upper by convention when both sides are real); with no real neighbour the run is an isolated
    /// cold region, filled by an absolute-offset window from its date-bucket anchor.
    private func fetchRun(
        _ run: PlaceholderRun,
        using mediaTimelineUseCase: some MediaTimelineUseCaseProtocol
    ) async -> RunFetchResult? {
        let filter = photoFilterOptions.toMediaTimelineFilterEntity()
        let order = sortOrder.toMediaTimelineSortOrderEntity()
        do {
            if let upper = run.upperNeighbour {
                let nodes = try await mediaTimelineUseCase.mediaPage(
                    filter: filter, sortOrder: order, after: upper, limit: run.range.count)
                try Task.checkCancellation()
                return nodes.isEmpty ? nil : RunFetchResult(run: run, kind: .pageAfter(upper), nodes: nodes)
            } else if let lower = run.lowerNeighbour {
                let nodes = try await mediaTimelineUseCase.mediaPage(
                    filter: filter, sortOrder: order, before: lower, limit: run.range.count)
                try Task.checkCancellation()
                return nodes.isEmpty ? nil : RunFetchResult(run: run, kind: .pageBefore(lower), nodes: nodes)
            } else {
                guard let anchor = sectionAnchor(forFlatIndex: run.range.lowerBound) else { return nil }
                let nodes = try await mediaTimelineUseCase.mediaWindow(
                    filter: filter, section: anchor.section, sortOrder: order,
                    offset: anchor.localOffset, limit: run.range.count)
                try Task.checkCancellation()
                return nodes.isEmpty ? nil : RunFetchResult(
                    run: run,
                    kind: .offset(groupId: anchor.section.groupId, localOffset: anchor.localOffset),
                    nodes: nodes)
            }
        } catch is CancellationError {
            return nil
        } catch {
            MEGALogError("[\(type(of: self))] run hydration failed: \(error)")
            return nil
        }
    }

    /// Fold every run's fetched nodes into one combined splice against `library`, returning the
    /// result (nil if nothing landed). Positions are resolved against `library`: cursor runs
    /// re-locate their anchor by handle, offset runs re-derive their start from `(groupId,
    /// localOffset)` against the current sections — so both survive a reshape in *another* bucket
    /// (which shifts absolute indices) and land correctly. `replacingPhotos(at:)` keeps the section
    /// shape, so the layout monitor reconfigures just the swapped cells in place — no full reload,
    /// no jump. The splice runs off the main actor (O(total photos) rebuild).
    private func splicedLibrary(
        _ library: PhotoLibrary,
        results: [RunFetchResult],
        generation: Int,
        capturedVersions: [String: UInt]
    ) async -> PhotoLibrary? {
        guard results.isNotEmpty, generation == timelineGeneration,
              versionsStillValid(capturedVersions) else { return nil }
        let photos = library.allPhotos

        var replacements: [Int: NodeEntity] = [:]
        for result in results {
            guard let start = spliceStart(for: result, in: photos) else { continue }
            for (offset, node) in result.nodes.enumerated() where offset < result.run.range.count {
                let index = start + offset
                // Only fill placeholder slots — never overwrite an already-hydrated real node or
                // overflow past the tree, whatever the SDK returned.
                guard photos.indices.contains(index), photos[index].isTimelinePlaceholder else { continue }
                replacements[index] = node
            }
        }
        guard replacements.isNotEmpty else { return nil }

        let hydrated = await splicing(library, replacing: replacements)
        guard generation == timelineGeneration, versionsStillValid(capturedVersions) else { return nil }
        return hydrated
    }

    /// Every captured bucket must still exist and carry the version it had when the hydration
    /// started; otherwise that bucket was reshaped/removed and the fetch is stale.
    private func versionsStillValid(_ captured: [String: UInt]) -> Bool {
        let currentGroupIds = Set(dateSections.map(\.groupId))
        return captured.allSatisfy { groupId, version in
            currentGroupIds.contains(groupId) && sectionVersions[groupId, default: 0] == version
        }
    }

    /// The current version of every day bucket the flat `range` overlaps, captured when a hydration
    /// starts so ``versionsStillValid(_:)`` can reject it if any of those buckets later reshaped.
    private func capturedVersions(spanning range: Range<Int>) -> [String: UInt] {
        var captured: [String: UInt] = [:]
        var cumulative = 0
        for section in dateSections {
            let next = cumulative + section.count
            if cumulative < range.upperBound && next > range.lowerBound {
                captured[section.groupId] = sectionVersions[section.groupId, default: 0]
            }
            cumulative = next
            if cumulative >= range.upperBound { break }
        }
        return captured
    }

    /// The flat index the first fetched node lands at, resolved against the *current* sections so a
    /// reshape elsewhere that shifted absolute positions doesn't misplace the fill. Cursor runs page
    /// outward from an anchor re-located by handle (`after` fills below it; `before` fills the run's
    /// tail ending just above the lower anchor); offset runs re-derive their bucket's current base
    /// and add the captured local offset (nil if that bucket no longer exists).
    private func spliceStart(for result: RunFetchResult, in photos: [NodeEntity]) -> Int? {
        switch result.kind {
        case .offset(let groupId, let localOffset):
            guard let base = currentBase(ofGroupId: groupId) else { return nil }
            return base + localOffset
        case .pageAfter(let anchor):
            guard let index = photos.firstIndex(where: { $0.handle == anchor.handle }) else { return nil }
            return index + 1
        case .pageBefore(let anchor):
            guard let index = photos.firstIndex(where: { $0.handle == anchor.handle }) else { return nil }
            return max(0, index - result.nodes.count)
        }
    }

    /// The flat index where `groupId`'s bucket starts in the current layout, or nil if that bucket
    /// no longer exists (removed by a reshape).
    private func currentBase(ofGroupId groupId: String) -> Int? {
        var cumulative = 0
        for section in dateSections {
            if section.groupId == groupId { return cumulative }
            cumulative += section.count
        }
        return nil
    }

    private nonisolated func splicing(
        _ library: PhotoLibrary, replacing replacements: [Int: NodeEntity]) async -> PhotoLibrary {
        library.replacingPhotos(at: replacements)
    }

    /// A contiguous span of placeholder slots in the visible window, plus the real nodes (if any)
    /// bordering it — the anchors that decide how the run is fetched.
    private struct PlaceholderRun {
        let range: Range<Int>
        let upperNeighbour: NodeEntity?
        let lowerNeighbour: NodeEntity?
    }

    /// How a run was fetched — carries what its splice position must be re-derived from at apply
    /// time (a handle anchor for cursor pages, a bucket + local offset for offset windows) so a
    /// reshape between fetch and apply can't leave it pinned to a stale absolute index.
    private enum RunFetchKind {
        case pageAfter(NodeEntity)
        case pageBefore(NodeEntity)
        case offset(groupId: String, localOffset: Int)
    }

    private struct RunFetchResult {
        let run: PlaceholderRun
        let kind: RunFetchKind
        let nodes: [NodeEntity]
    }

    /// Maps a flat index in `allPhotos` to the date section that contains it (by cumulative
    /// count, matching the skeleton) and the local offset within that section.
    private func sectionAnchor(forFlatIndex index: Int) -> (section: MediaDateSectionEntity, localOffset: Int)? {
        var cumulative = 0
        for section in dateSections {
            let next = cumulative + section.count
            if index < next {
                return (section, index - cumulative)
            }
            cumulative = next
        }
        return nil
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
        await Task.detached(priority: .userInitiated) {
            nodes.toPhotoLibrary(withSortType: sortOrder)
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
