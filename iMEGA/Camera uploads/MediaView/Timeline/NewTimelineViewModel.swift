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

    /// Bumped only when the skeleton is genuinely rebuilt — its shape changed, or the
    /// filter/sort changed. An in-flight window hydration captures it and discards its result
    /// if a rebuild happened underneath it, so stale (offset-positioned) nodes never splice
    /// into a fresh skeleton. A shape-neutral reload does NOT bump it, so hydration in flight
    /// during such a reload survives. Identity-based reconciliation across shape changes
    /// (preserving hydration when counts move) is the cursor work.
    private var skeletonGeneration = 0
    
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
            photoLibraryContentViewModel.library = try await loadTimelineLibrary()
        } catch is CancellationError {
            MEGALogError("[\(type(of: self))] loadPhotos cancelled")
        } catch {
            MEGALogError("[\(type(of: self))] - error loading photos \(error)")
        }
    }
    
    func monitorUpdates() async {
        for await nodes in nodeUseCase.nodeUpdates where isInitialLoadComplete {
            handleNodeUpdates(with: nodes)
        }
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
            
            photoLibraryContentViewModel.library = updatedPhotoLibrary
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

    /// Builds the placeholder skeleton purely from date-bucket counts — no node is
    /// fetched here. Real thumbnails are hydrated lazily per visible window in a later
    /// change; until then the grid stays a correctly-sized skeleton.
    private func skeletonPhotoLibrary(
        using mediaTimelineUseCase: some MediaTimelineUseCaseProtocol
    ) async throws -> PhotoLibrary {
        let sections = try await mediaTimelineUseCase.dateSections(
            filter: photoFilterOptions.toMediaTimelineFilterEntity(),
            granularity: .day,
            sortOrder: sortOrder.toMediaTimelineSortOrderEntity())

        try Task.checkCancellation()

        showEmptyStateView = sections.isEmpty
        return reconcileSkeleton(with: sections)
    }

    /// Fold freshly-fetched date sections into the on-screen library.
    ///
    /// - Same filter/sort AND structurally-identical section shape → the placeholder/real
    ///   layout is still valid at every position, so keep the current (possibly hydrated)
    ///   library as-is. This is the safe subset of a merge: a node update that didn't change
    ///   the timeline shape must not wipe hydrated cells back to placeholders.
    /// - Otherwise (filter/sort changed, or the shape changed) the old positions no longer
    ///   hold, so build a fresh placeholder skeleton and bump the generation to drop any
    ///   in-flight window hydration.
    private func reconcileSkeleton(with sections: [MediaDateSectionEntity]) -> PhotoLibrary {
        let filterUnchanged = skeletonFilterOptions == photoFilterOptions
            && skeletonSortOrder == sortOrder
        if filterUnchanged, sameShape(dateSections, sections) {
            dateSections = sections
            return photoLibraryContentViewModel.library
        }

        dateSections = sections
        skeletonFilterOptions = photoFilterOptions
        skeletonSortOrder = sortOrder
        skeletonGeneration += 1
        return PhotoLibrary.skeleton(from: sections)
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
        guard let mediaTimelineUseCase else { return }

        let photos = photoLibraryContentViewModel.library.allPhotos
        let clampedUpper = min(range.upperBound, photos.count)
        guard range.lowerBound < clampedUpper else { return }

        // Split the visible window into contiguous placeholder runs rather than fetching it as a
        // whole: a run flanked by an already-hydrated real node is grown from that anchor by cursor
        // (drift-safe), while an isolated cold run teleports in by absolute offset. A window mixing
        // both is handled per-run.
        let runs = placeholderRuns(in: range.lowerBound..<clampedUpper, photos: photos)
        guard runs.isNotEmpty else { return }

        let generation = skeletonGeneration
        var results: [RunFetchResult] = []
        for run in runs {
            guard !Task.isCancelled, generation == skeletonGeneration else { return }
            if let result = await fetchRun(run, using: mediaTimelineUseCase) {
                results.append(result)
            }
        }
        await applyFills(results, generation: generation)
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
                return nodes.isEmpty ? nil : RunFetchResult(run: run, kind: .offset, nodes: nodes)
            }
        } catch is CancellationError {
            return nil
        } catch {
            MEGALogError("[\(type(of: self))] run hydration failed: \(error)")
            return nil
        }
    }

    /// Fold every run's fetched nodes into one combined splice. Positions are resolved against a
    /// single snapshot: cursor runs re-locate their anchor by handle (immune to reshape), offset
    /// runs land at their captured flat position. `replacingPhotos(at:)` keeps the section shape,
    /// so the layout monitor reconfigures just the swapped cells in place — no full reload, no jump.
    /// The splice itself runs off the main actor (O(total photos) tree rebuild).
    private func applyFills(_ results: [RunFetchResult], generation: Int) async {
        guard results.isNotEmpty, generation == skeletonGeneration else { return }
        let current = photoLibraryContentViewModel.library
        let photos = current.allPhotos

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
        guard replacements.isNotEmpty else { return }

        let hydrated = await splicing(current, replacing: replacements)
        guard generation == skeletonGeneration else { return }
        photoLibraryContentViewModel.library = hydrated
    }

    /// The flat index the first fetched node lands at. Cursor runs page outward from an anchor
    /// re-located by handle (`after` fills below it; `before` fills the run's tail ending just
    /// above the lower anchor); offset runs start at the run's captured lower bound.
    private func spliceStart(for result: RunFetchResult, in photos: [NodeEntity]) -> Int? {
        switch result.kind {
        case .offset:
            return result.run.range.lowerBound
        case .pageAfter(let anchor):
            guard let index = photos.firstIndex(where: { $0.handle == anchor.handle }) else { return nil }
            return index + 1
        case .pageBefore(let anchor):
            guard let index = photos.firstIndex(where: { $0.handle == anchor.handle }) else { return nil }
            return max(0, index - result.nodes.count)
        }
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

    /// How a run was fetched — carries the anchor so its splice position can be re-derived by
    /// identity at apply time (cursor) rather than by the position captured when the run was built.
    private enum RunFetchKind {
        case pageAfter(NodeEntity)
        case pageBefore(NodeEntity)
        case offset
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
