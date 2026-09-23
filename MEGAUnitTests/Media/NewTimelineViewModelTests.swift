import ContentLibraries
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPreference
import MEGAPreferenceMocks
import MEGASwift
import Testing

struct NewTimelineViewModelTests {
    
    @MainActor
    @Suite
    struct LoadPhotos {
        @Test
        func defaultFilters() async throws {
            let photos = [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)]
            let photoLibraryUseCase = MockPhotoLibraryUseCase(
                allPhotos: photos
            )
            let sut = makeSUT(photoLibraryUseCase: photoLibraryUseCase)
            
            await sut.loadPhotos()
            
            #expect(sut.photoLibraryContentViewModel.library.allPhotos == photos)
        }
        
        @Test
        func savedFilters() async throws {
            let photos = [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)]
            let photoLibraryUseCase = MockPhotoLibraryUseCase(
                allPhotos: photos
            )
            let timelineUserAttribute = TimelineUserAttributeEntity(
                mediaType: .images,
                location: .cameraUploads,
                usePreference: true)
            let contentConsumptionUseCase = MockContentConsumptionUserAttributeUseCase(
                timelineUserAttributeEntity: timelineUserAttribute
            )
            let sut = makeSUT(
                photoLibraryUseCase: photoLibraryUseCase,
                contentConsumptionUserAttributeUseCase: contentConsumptionUseCase)
            
            await sut.loadPhotos()
            
            #expect(sut.photoFilterOptions == timelineUserAttribute.toPhotoFilterOptionsEntity())
        }
        
        @Test func empty() async throws {
            let photoLibraryUseCase = MockPhotoLibraryUseCase()
            let sut = makeSUT(photoLibraryUseCase: photoLibraryUseCase)
            
            await sut.loadPhotos()
            
            #expect(sut.showEmptyStateView)
        }
    }
    
    @MainActor
    @Suite("Node Updates")
    struct NodeUpdates {
        @Test("Non visual media node updates should not trigger an update")
        func nonVisualMediaNodeUpdate() async throws {
            let nodeUpdates = SingleItemAsyncSequence(
                item: [NodeEntity(handle: 1, hasThumbnail: false)])
                .eraseToAnyAsyncSequence()
            let photoLibraryUseCase = MockPhotoLibraryUseCase()
            
            let sut = makeSUT(
                photoLibraryUseCase: photoLibraryUseCase,
                nodeUseCase: MockNodeUseCase(
                    nodeUpdates: nodeUpdates)
            )
            await sut.loadPhotos()
            
            await sut.monitorUpdates()
            try await sut.currentNodeUpdateTask?.value
            
            await #expect(photoLibraryUseCase.messages == [.media])
        }
        
        @Test("Visual media node should trigger updates")
        func visualMediaUpdatesTriggerLoad() async throws {
            let nodeUpdates = SingleItemAsyncSequence(
                item: [NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)])
                .eraseToAnyAsyncSequence()
            let expectedPhotos = [
                NodeEntity(name: "test15.jpg", handle: 15, hasThumbnail: true)
            ]
            let photoLibraryUseCase = MockPhotoLibraryUseCase(
                allPhotos: expectedPhotos
            )
            let sut = makeSUT(
                photoLibraryUseCase: photoLibraryUseCase,
                nodeUseCase: MockNodeUseCase(
                    nodeUpdates: nodeUpdates)
            )
            await sut.loadPhotos()
            
            await sut.monitorUpdates()
            try await sut.currentNodeUpdateTask?.value
            
            #expect(sut.photoLibraryContentViewModel.library.allPhotos == expectedPhotos)
            await #expect(photoLibraryUseCase.messages == [.media, .media])
            #expect(sut.currentNodeUpdateTask == nil)
        }
    }
    
    @MainActor
    @Suite("Skeleton Path")
    struct SkeletonPath {
        /// Two UTC day buckets, counts 2 and 1.
        private static func makeSections() -> [MediaDateSectionEntity] {
            sections(day1: 2, day2: 1)
        }

        /// The same two UTC day buckets with arbitrary per-bucket counts; a bucket with count 0
        /// is omitted (as the SDK would). Used to model a reactive shape change.
        private static func sections(day1 count1: Int, day2 count2: Int) -> [MediaDateSectionEntity] {
            let day1 = Date(timeIntervalSince1970: 1_660_780_800) // 2022-08-18T00:00:00Z
            let day2 = Date(timeIntervalSince1970: 1_658_102_400) // 2022-07-18T00:00:00Z
            var result: [MediaDateSectionEntity] = []
            if count1 > 0 {
                result.append(.init(groupId: "2022-08-18", startDate: day1, endDate: day1, count: count1))
            }
            if count2 > 0 {
                result.append(.init(groupId: "2022-07-18", startDate: day2, endDate: day2, count: count2))
            }
            return result
        }

        /// One stream per section pass, in the order the monitor subscribes to them. The paginated
        /// skeleton is no longer built by `loadPhotos()`: production's `monitorDateSections` stream
        /// prepends a full load of the same query, so the monitor's *first* emission is the initial
        /// load and every later one is a reshape. Spelling the passes out is what lets a test act
        /// between them.
        private static func sectionStreams(
            _ passes: [[MediaDateSectionEntity]]
        ) -> [AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>>] {
            passes.map { SingleItemAsyncSequence(item: .success($0)).eraseToAnyAsyncSequence() }
        }

        /// Drive the initial load the way the View does: `loadPhotos()` — which on this path only
        /// applies the saved filter — followed by one section pass.
        private static func buildSkeleton(_ sut: NewTimelineViewModel) async {
            await sut.loadPhotos()
            await sut.monitorTimelineSections()
        }

        /// The same, with the grid reporting nothing on screen. The pass then plans no hydration,
        /// leaving a pure skeleton for a scroll-driven window to act on in isolation.
        private static func buildColdSkeleton(_ sut: NewTimelineViewModel) async {
            sut.photoLibraryContentViewModel.visiblePhotoIndexRange.send(0..<0)
            await buildSkeleton(sut)
            sut.photoLibraryContentViewModel.visiblePhotoIndexRange.send(nil)
        }

        @Test("Builds a placeholder skeleton from date-section counts without touching the eager use case")
        func buildsSkeletonFromDateSections() async throws {
            let recorder = MediaTimelineUseCaseRecorder()
            let photoLibraryUseCase = MockPhotoLibraryUseCase(allPhotos: [
                NodeEntity(name: "real.jpg", handle: 1, hasThumbnail: true)
            ])
            let sut = makeSUT(
                photoLibraryUseCase: photoLibraryUseCase,
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([Self.makeSections()]),
                    recorder: recorder))

            await Self.buildColdSkeleton(sut)

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            let allArePlaceholders = photos.allSatisfy(\.isTimelinePlaceholder)
            #expect(photos.count == 3) // 2 + 1
            #expect(allArePlaceholders)
            #expect(!sut.showEmptyStateView)
            // The eager media(...) path must not run when the skeleton use case is present.
            await #expect(photoLibraryUseCase.messages == [])
            // The shape arrived on the monitor's prepended first emission, so nothing on this path
            // may run a query for it a second time.
            #expect(await recorder.dateSectionsCalls == 0)
        }

        @Test("Empty date sections show the empty state and an empty library")
        func emptySectionsShowEmptyState() async throws {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([[]])))

            await Self.buildSkeleton(sut)

            #expect(sut.showEmptyStateView)
            #expect(sut.photoLibraryContentViewModel.library.allPhotos.isEmpty)
        }

        @Test("The first section pass hydrates the top window up front, so the top screen shows real nodes without a scroll")
        func initialPassEagerlyHydratesFirstWindow() async {
            // Nothing has been displayed yet, so the pass names the top window itself rather than
            // committing a wall of placeholders that only fills in once the grid reports a range.
            let recorder = MediaTimelineUseCaseRecorder()
            let sections = Self.makeSections()
            let firstWindow = [
                NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
            ]
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success(firstWindow),
                    monitorDateSectionsSequences: Self.sectionStreams([sections]), // counts 2 + 1 = 3
                    recorder: recorder))

            await Self.buildSkeleton(sut)

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos.count == 3) // total sized from the counts
            #expect(photos[0].handle == 10) // spliced in *before* the initial commit
            #expect(photos[1].handle == 11)
            #expect(photos[2].isTimelinePlaceholder) // beyond the fetched window → still a placeholder
            // A cold tree holds no real node to anchor a cursor on, so the top window teleports in
            // by one offset fetch sized to the whole window, never a forward page.
            #expect(await recorder.windowCalls == [.init(section: sections[0], offset: 0, limit: 3)])
            #expect(await recorder.pageAfterCalls.isEmpty)
        }

        @Test("Hydrating a visible window splices fetched real nodes into the skeleton in place")
        func hydrateVisibleWindowSplicesRealNodes() async {
            let reals = [
                NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
            ]
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success(reals),
                    monitorDateSectionsSequences: Self.sectionStreams([Self.makeSections()]))) // 2 + 1 = 3
            await Self.buildColdSkeleton(sut)

            await sut.hydrateVisibleWindow(0..<2)

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos.count == 3) // total preserved
            #expect(photos[0].handle == 10)
            #expect(photos[1].handle == 11)
            #expect(photos[2].isTimelinePlaceholder) // untouched slot stays a placeholder
        }

        @Test("A gap next to a real slot fills only the gap, by cursor forward from that real node")
        func hydrateVisibleWindowFillsGapNextToRealSlotByCursor() async {
            let recorder = MediaTimelineUseCaseRecorder()
            let realSlot0 = NodeEntity(name: "first.jpg", handle: 10, hasThumbnail: true)
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    // The gap borders a real node, so it must page forward from it (cursor),
                    // not teleport by offset — the offset result must stay unused.
                    mediaPageResult: .success([NodeEntity(name: "gap.jpg", handle: 99, hasThumbnail: true)]),
                    mediaWindowResult: .success([NodeEntity(name: "wrong.jpg", handle: 500, hasThumbnail: true)]),
                    monitorDateSectionsSequences: Self.sectionStreams([Self.makeSections()]), // 2 + 1 = 3
                    recorder: recorder))
            await Self.buildColdSkeleton(sut) // a pure 3-slot skeleton: no window was planned
            await recorder.reset()

            // Pre-hydrate slot 0 so the next visible window overlaps an already-real slot.
            sut.commitHydratedRun(from: 0, with: [realSlot0])

            // Window 0..<2 spans the real slot 0 and the placeholder slot 1; only slot 1 should be fetched.
            await sut.hydrateVisibleWindow(0..<2)

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos[0].handle == 10) // untouched — not re-fetched or overwritten
            #expect(photos[1].handle == 99) // gap filled from the cursor page, not the offset window
            #expect(photos[2].isTimelinePlaceholder)
            // One forward page anchored at the real slot, sized to the 1-slot gap; no offset window.
            #expect(await recorder.pageAfterCalls == [.init(after: realSlot0, limit: 1)])
            #expect(await recorder.windowCalls.isEmpty)
            #expect(await recorder.pageBeforeCalls.isEmpty)
        }

        @Test("A gap sitting above a real slot pages backward (before) into the gap's tail")
        func hydrateVisibleWindowFillsGapAboveRealSlotByBackwardCursor() async {
            let recorder = MediaTimelineUseCaseRecorder()
            let realSlot2 = NodeEntity(name: "last.jpg", handle: 20, hasThumbnail: true)
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaPageBeforeResult: .success([NodeEntity(name: "up.jpg", handle: 77, hasThumbnail: true)]),
                    mediaWindowResult: .success([NodeEntity(name: "wrong.jpg", handle: 500, hasThumbnail: true)]),
                    monitorDateSectionsSequences: Self.sectionStreams([Self.makeSections()]), // 2 + 1 = 3
                    recorder: recorder))
            await Self.buildColdSkeleton(sut) // a pure 3-slot skeleton: no window was planned
            await recorder.reset()

            // Pre-hydrate the LAST slot so the gap above it has a real lower neighbour and no real
            // upper neighbour → backward paging.
            sut.commitHydratedRun(from: 2, with: [realSlot2])

            await sut.hydrateVisibleWindow(1..<3) // gap at slot 1, real at slot 2

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos[1].handle == 77) // filled from the backward page, adjacent to slot 2
            #expect(photos[2].handle == 20) // untouched
            // One backward page anchored at the lower real slot, sized to the 1-slot gap; no offset window.
            #expect(await recorder.pageBeforeCalls == [.init(before: realSlot2, limit: 1)])
            #expect(await recorder.windowCalls.isEmpty)
            #expect(await recorder.pageAfterCalls.isEmpty)
        }

        @Test("An isolated cold run with no real neighbour teleports in by a single offset window")
        func hydrateVisibleWindowIsolatedRunUsesOffset() async {
            let recorder = MediaTimelineUseCaseRecorder()
            let sections = Self.makeSections()
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success([
                        NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequences: Self.sectionStreams([sections]), // counts 2 + 1 = 3
                    recorder: recorder))
            await Self.buildColdSkeleton(sut)
            await recorder.reset() // the empty pageAfterCalls below proves the isolated run
                                   // teleported by offset, not by a cursor page

            await sut.hydrateVisibleWindow(0..<2) // both neighbours are placeholders → offset

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos[0].handle == 10) // from the offset window, not the cursor page
            #expect(photos[1].handle == 11)
            #expect(photos[2].isTimelinePlaceholder)
            // Anchored at the first section, local offset 0, sized to the 2-slot run; no cursor page.
            #expect(await recorder.windowCalls == [.init(section: sections[0], offset: 0, limit: 2)])
            #expect(await recorder.pageAfterCalls.isEmpty)
            #expect(await recorder.pageBeforeCalls.isEmpty)
        }

        /// A five-slot skeleton with a real node in the middle: one window then plans two runs
        /// fetched by different calls — backward above it, forward below — so a test can give one
        /// run a landing and the other an empty page, a failure or a cancellation.
        private static func makeSplitRunSUT(
            pageBefore: Result<[NodeEntity], any Error>,
            pageAfter: Result<[NodeEntity], any Error>
        ) async -> NewTimelineViewModel {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaPageResult: pageAfter,
                    mediaPageBeforeResult: pageBefore,
                    monitorDateSectionsSequences: Self.sectionStreams([Self.sections(day1: 3, day2: 2)])))
            await Self.buildColdSkeleton(sut)
            sut.commitHydratedRun(from: 2, with: [NodeEntity(name: "mid.jpg", handle: 20, hasThumbnail: true)])
            return sut
        }

        @Test("A run whose query fails leaves its own slots blank without costing the runs that answered")
        func hydrateVisibleWindowFailedRunDoesNotAbortTheBatch() async {
            let sut = await Self.makeSplitRunSUT(
                pageBefore: .failure(GenericErrorEntity()),
                pageAfter: .success([
                    NodeEntity(name: "d.jpg", handle: 30, hasThumbnail: true),
                    NodeEntity(name: "e.jpg", handle: 31, hasThumbnail: true)
                ]))

            await sut.hydrateVisibleWindow(0..<5)

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos[0].isTimelinePlaceholder) // the failed run
            #expect(photos[1].isTimelinePlaceholder)
            #expect(photos[2].handle == 20)
            #expect(photos[3].handle == 30) // the run that answered still landed
            #expect(photos[4].handle == 31)
        }

        @Test("A run the query answers with nothing is left blank, and says nothing about the rest of the batch")
        func hydrateVisibleWindowEmptyRunDoesNotAbortTheBatch() async {
            let sut = await Self.makeSplitRunSUT(
                pageBefore: .success([]),
                pageAfter: .success([
                    NodeEntity(name: "d.jpg", handle: 30, hasThumbnail: true),
                    NodeEntity(name: "e.jpg", handle: 31, hasThumbnail: true)
                ]))

            await sut.hydrateVisibleWindow(0..<5)

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos[0].isTimelinePlaceholder) // answered, and still blank
            #expect(photos[1].isTimelinePlaceholder)
            #expect(photos[3].handle == 30)
            #expect(photos[4].handle == 31)
        }

        @Test("A cancelled run drops the runs that already landed with it, rather than committing half a window")
        func hydrateVisibleWindowCancelledRunCommitsNothing() async {
            // A cancelled hydration is one a newer visible range replaced; committing half of it
            // would get that newer window discarded. The first run lands, the second is cancelled,
            // and the landing must go with it.
            let sut = await Self.makeSplitRunSUT(
                pageBefore: .success([
                    NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                    NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
                ]),
                pageAfter: .failure(CancellationError()))

            await sut.hydrateVisibleWindow(0..<5)

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos[0].isTimelinePlaceholder) // the run that landed was dropped too
            #expect(photos[1].isTimelinePlaceholder)
            #expect(photos[2].handle == 20) // what was already committed is untouched
            #expect(photos[3].isTimelinePlaceholder)
            #expect(photos[4].isTimelinePlaceholder)
        }

        @Test("A reshape that drops the grid's reported range off the end hydrates the top instead of nothing")
        func reshapePastReportedRangeFallsBackToTopWindow() async {
            // The grid keeps reporting the last range it displayed — nothing ever clears it — so a
            // filter change down to a much shorter set leaves that range pointing past the end of
            // the new one. Hydrating nothing there would publish a screen of placeholders until the
            // collection view reported again.
            let recorder = MediaTimelineUseCaseRecorder()
            let big = Self.sections(day1: 200, day2: 0)
            let small = Self.sections(day1: 3, day2: 0)
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success([
                        NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true),
                        NodeEntity(name: "c.jpg", handle: 12, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequences: Self.sectionStreams([big, small]),
                    recorder: recorder))

            await Self.buildSkeleton(sut)
            sut.photoLibraryContentViewModel.visiblePhotoIndexRange.send(150..<170)
            await recorder.reset()

            await sut.monitorTimelineSections() // the reshape down to 3 items

            #expect(await recorder.windowCalls == [.init(section: small[0], offset: 0, limit: 3)])
            #expect(sut.photoLibraryContentViewModel.library.allPhotos.map(\.handle) == [10, 11, 12])
        }

        @Test("A cold run spanning two sections is filled by ONE offset window across the boundary")
        func hydrateVisibleWindowCrossSectionRunUsesSingleWindow() async {
            // The SDK's timestamp anchor is half-bounded and pages across adjacent sections, so a
            // window spanning a section boundary is a single fetch sized to the whole run — not one
            // request per section (see byTimestampAnchor: "Pagination continues into adjacent sections").
            let recorder = MediaTimelineUseCaseRecorder()
            let sections = Self.makeSections()
            let reals = [
                NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true), // section 0, slot 0
                NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true), // section 0, slot 1
                NodeEntity(name: "c.jpg", handle: 12, hasThumbnail: true)  // section 1, slot 0
            ]
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success(reals),
                    monitorDateSectionsSequences: Self.sectionStreams([sections]), // counts 2 + 1 = 3
                    recorder: recorder))
            await Self.buildColdSkeleton(sut)
            await recorder.reset()

            await sut.hydrateVisibleWindow(0..<3) // one isolated run spanning both sections

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos.map(\.handle) == [10, 11, 12]) // spliced across the boundary
            #expect(await recorder.windowCalls == [.init(section: sections[0], offset: 0, limit: 3)])
        }

        /// Runs a reactive section pass from inside a mock fetch, exactly once. Must be armed
        /// explicitly: the pass that builds the initial skeleton issues fetches of its own, and the
        /// reactive pass this triggers issues another — none of them should consume the shot.
        @MainActor
        private final class ReactivePassTrigger {
            var sut: NewTimelineViewModel?
            private var isArmed = false

            func arm() { isArmed = true }

            func fireOnce() async {
                guard isArmed else { return }
                isArmed = false
                await sut?.monitorTimelineSections()
            }
        }

        /// Runs a scroll hydration from inside a mock fetch, once — so its commit lands while a
        /// reactive pass is suspended on its own.
        @MainActor
        private final class ScrollHydrationTrigger {
            var sut: NewTimelineViewModel?
            var range: Range<Int> = 0..<0
            private var isArmed = false

            func arm() { isArmed = true }

            func fireOnce() async {
                guard isArmed else { return }
                isArmed = false
                await sut?.hydrateVisibleWindow(range)
            }
        }

        /// Commits a node-metadata patch from inside a mock fetch, exactly once — so a test can land
        /// one while a reactive pass is suspended on its hydration.
        @MainActor
        private final class MetadataPatchTrigger {
            var sut: NewTimelineViewModel?
            private var isArmed = false

            func arm() { isArmed = true }

            func fireOnce() async {
                guard isArmed else { return }
                isArmed = false
                await sut?.monitorNodeMetadataUpdates()
            }
        }

        @Test("Loading the saved filter re-keys the section monitor, so it can't keep counting the default filter's photo set")
        func loadingSavedFiltersRekeysTheSectionMonitor() async {
            // The View starts `monitorTimelineSections()` keyed on `timelineQueryId`, and that monitor
            // captures the filter when it subscribes. The saved filter arrives asynchronously during
            // the first `loadPhotos()`, i.e. after the monitor already subscribed with the default
            // `[.allMedia, .allLocations]`. Without a re-key the monitor keeps counting a wider photo
            // set than the skeleton and every page fetch use, and the surplus counts become slots no
            // node can ever fill — placeholders stranded mid-grid.
            let saved = TimelineUserAttributeEntity(
                mediaType: .images, location: .cameraUploads, usePreference: true)
            let sut = makeSUT(
                contentConsumptionUserAttributeUseCase: MockContentConsumptionUserAttributeUseCase(
                    timelineUserAttributeEntity: saved),
                mediaTimelineUseCase: MockMediaTimelineUseCase())
            let queryIdBefore = sut.timelineQueryId

            await sut.loadPhotos()

            #expect(sut.photoFilterOptions == saved.toPhotoFilterOptionsEntity()) // filter did change
            #expect(sut.timelineQueryId != queryIdBefore) // …so the monitor is re-subscribed
        }

        @Test("A sort-order change re-keys the section monitor")
        func sortOrderChangeRekeysTheSectionMonitor() {
            let sut = makeSUT(mediaTimelineUseCase: MockMediaTimelineUseCase())
            let queryIdBefore = sut.timelineQueryId

            sut.updateSortOrder(.modificationAsc)

            #expect(sut.timelineQueryId != queryIdBefore)
        }

        @Test("A hydration whose library moved during the fetch is discarded instead of reverting the newer commit")
        func hydrateVisibleWindowDiscardsResultWhenLibraryMovedDuringFetch() async {
            // The real race: the user is parked in day2, a Camera-Upload insert grows day1 off-screen,
            // and the reactive pass commits the re-projected skeleton while this hydration is still
            // awaiting its page. Committing the stale result would revert that reproject, leaving the
            // library's slot count out of step with `dateSections` — a desync `sameShape` can never
            // detect (it compares incoming sections against `dateSections`, never against the
            // library), so later windows splice at the wrong offset and duplicate a node.
            let trigger = ReactivePassTrigger()
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success([
                        NodeEntity(name: "d2a.jpg", handle: 20, hasThumbnail: true),
                        NodeEntity(name: "d2b.jpg", handle: 21, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.sections(day1: 2, day2: 2), // 4 slots
                        Self.sections(day1: 3, day2: 2)  // the reactive reshape
                    ]),
                    onFetch: { await trigger.fireOnce() }))
            trigger.sut = sut
            await Self.buildColdSkeleton(sut) // pure skeleton, so the window below is an isolated run
            trigger.arm() // only race the scroll-driven hydration, not the initial pass

            // 2..<4 lies entirely inside day2, so the day1-only reshape bumps no version this
            // hydration captured: `versionsStillValid` passes and only the library-revision check
            // can reject the stale result.
            await sut.hydrateVisibleWindow(2..<4)

            // day1: 3 + day2: 2 — the reproject survived, so the library still matches `dateSections`.
            #expect(sut.photoLibraryContentViewModel.library.allPhotos.count == 5)
        }

        @Test("A run whose fetched page overlaps an already-hydrated node skips the duplicate but still splices the new one")
        func hydrateVisibleWindowNeverAliasesAnAlreadyHydratedNode() async {
            // A slot's *position* comes from the `dateSections` counts, its *content* from a separate
            // media query — two snapshots that can disagree. Here day2's window returns a node (10)
            // that is already live in day1, alongside a genuinely new one (99). Writing 10 a second
            // time would put the same node at two visible positions, which crashes duplicate-key
            // consumers (e.g. the collection view's visible-position lookup).
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success([
                        NodeEntity(name: "stale.jpg", handle: 10, hasThumbnail: true), // already at slot 0
                        NodeEntity(name: "new.jpg", handle: 99, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequences: Self.sectionStreams([Self.sections(day1: 2, day2: 2)])))
            await Self.buildColdSkeleton(sut) // a pure 4-slot skeleton
            sut.commitHydratedRun(from: 0, with: [NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true)])

            // Slots 2, 3 are an isolated cold run (both neighbours are placeholders) → offset fetch.
            await sut.hydrateVisibleWindow(2..<4)

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            let realHandles = photos.filter { !$0.isTimelinePlaceholder }.map(\.handle)
            #expect(realHandles == [10, 99]) // stale copy of 10 dropped, 99 still landed
            #expect(Set(realHandles).count == realHandles.count) // no node aliased into two slots
            // The skipped slot stays open, so a later authoritative fetch can fill it correctly.
            #expect(photos[2].isTimelinePlaceholder)
            #expect(photos[3].handle == 99)
        }

        @Test("A shape-neutral reload preserves hydrated nodes instead of flashing back to placeholders")
        func reloadWithUnchangedShapePreservesHydration() async {
            let reals = [
                NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
            ]
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success(reals),
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.makeSections(), // counts 2 + 1
                        Self.makeSections()  // a node-update-style reload: same shape, same filter
                    ])))
            await Self.buildColdSkeleton(sut)
            await sut.hydrateVisibleWindow(0..<2) // slots 0, 1 now real

            await sut.monitorTimelineSections()

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos[0].handle == 10) // hydrated content preserved, not wiped
            #expect(photos[1].handle == 11)
            #expect(photos[2].isTimelinePlaceholder)
        }

        @Test("Changing the filter rebuilds the skeleton, dropping hydration that no longer applies")
        func filterChangeRebuildsSkeletonDiscardingHydration() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success([
                        NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.makeSections(),
                        Self.makeSections() // the re-subscription the filter change forces
                    ])))
            await Self.buildColdSkeleton(sut)
            await sut.hydrateVisibleWindow(0..<2) // hydrate under the initial filter

            await sut.updatePhotoFilter(option: .images) // a different dataset
            // Nothing is on screen across the switch, so the rebuilt skeleton is asserted as it is
            // committed rather than after the pass has hydrated its top window back in.
            sut.photoLibraryContentViewModel.visiblePhotoIndexRange.send(0..<0)
            await sut.monitorTimelineSections()

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            let allArePlaceholders = photos.allSatisfy(\.isTimelinePlaceholder)
            #expect(allArePlaceholders) // stale hydration dropped; grid is a fresh skeleton
        }

        @Test("Changing sort order reloads (re-fetches sections) instead of locally re-sorting placeholders")
        func sortOrderChangeReloads() async throws {
            let sut = makeSUT(mediaTimelineUseCase: MockMediaTimelineUseCase())
            let taskId = sut.loadPhotosTaskId

            sut.updateSortOrder(.modificationAsc)

            #expect(sut.loadPhotosTaskId != taskId)
            #expect(sut.sortPhotoLibraryTask == nil) // no local re-sort task spawned
        }

        @Test("A reactive shape change keeps hydrated nodes from an unaffected bucket in place")
        func reactiveShapeChangePreservesHydrationByIdentity() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success([
                        NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.makeSections(),            // day1: 2, day2: 1
                        Self.sections(day1: 2, day2: 2) // day2 grows by one
                    ])))
            await Self.buildColdSkeleton(sut)
            await sut.hydrateVisibleWindow(0..<2) // day1 slots 0, 1 now real (10, 11)

            await sut.monitorTimelineSections() // day2 grows by one → reshape + re-project

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos.count == 4) // 2 + 2
            #expect(photos[0].handle == 10) // day1 hydration carried across the reshape by identity
            #expect(photos[1].handle == 11)
            #expect(photos[2].isTimelinePlaceholder) // grown day2 slots await hydration
            #expect(photos[3].isTimelinePlaceholder)
        }

        @Test("A reactive growth in an earlier bucket relocates a hydrated node, preserving its offset within its own bucket")
        func reactiveEarlierBucketGrowthRelocatesHydratedNode() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.sections(day1: 1, day2: 1), // 2 slots
                        Self.sections(day1: 2, day2: 1)  // day1 grows 1 → 2
                    ])))
            await Self.buildColdSkeleton(sut)
            // Pre-hydrate the day2 slot (index 1, local offset 0 within day2).
            sut.commitHydratedRun(from: 1, with: [NodeEntity(name: "d2.jpg", handle: 20, hasThumbnail: true)])

            await sut.monitorTimelineSections() // day1 grows 1 → 2

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos.count == 3)
            #expect(photos[0].isTimelinePlaceholder) // day1 offsets 0, 1
            #expect(photos[1].isTimelinePlaceholder)
            #expect(photos[2].handle == 20) // moved from index 1 to index 2, same (day2, offset 0)
        }

        @Test("A reactive count change drops the whole affected bucket to placeholders (never aliases a node)")
        func reactiveCountChangeDropsBucketToPlaceholders() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.sections(day1: 2, day2: 0), // single bucket, 2 slots
                        Self.sections(day1: 1, day2: 0)  // its count changes
                    ])))
            await Self.buildColdSkeleton(sut)
            sut.commitHydratedRun(from: 0, with: [
                NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
            ])

            await sut.monitorTimelineSections() // day1's count changed → the bucket can't be trusted, drop it whole

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos.count == 1)
            // The whole changed bucket becomes placeholders, awaiting authoritative re-hydration —
            // rather than keeping a shifted node that could alias into two slots.
            #expect(photos[0].isTimelinePlaceholder)
        }

        @Test("Camera-Upload insert at the front of a bucket re-projects without aliasing a node into two slots")
        func reactiveFrontInsertDoesNotDuplicate() async {
            // Newest-first: a new upload N lands at the FRONT of day1, so day1 grows 2 → 3 and every
            // existing day1 node shifts down one offset. Carrying day1 by its old offsets would leave
            // a placeholder whose true occupant (P1) is still present, and the gap-fill would re-fetch
            // a node already carried elsewhere — the duplicate that crashes duplicate-key consumers.
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    // day1 dropped to placeholders → re-hydrated by paging backward from the day2 anchor.
                    mediaPageResult: .success([NodeEntity(name: "spill.jpg", handle: 12, hasThumbnail: true)]),
                    mediaPageBeforeResult: .success([
                        NodeEntity(name: "n.jpg", handle: 99, hasThumbnail: true),  // the new upload
                        NodeEntity(name: "p0.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "p1.jpg", handle: 11, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.sections(day1: 2, day2: 1),
                        Self.sections(day1: 3, day2: 1) // day1 grew at the front
                    ])))
            await Self.buildColdSkeleton(sut)
            // Fully hydrate the initial 3 slots: day1 [10, 11], day2 [12].
            sut.commitHydratedRun(from: 0, with: [
                NodeEntity(name: "p0.jpg", handle: 10, hasThumbnail: true),
                NodeEntity(name: "p1.jpg", handle: 11, hasThumbnail: true),
                NodeEntity(name: "q0.jpg", handle: 12, hasThumbnail: true)
            ])

            await sut.monitorTimelineSections()   // day1 grew at the front → dropped to placeholders
            await sut.hydrateVisibleWindow(0..<4) // authoritative re-fill of the dropped day1

            let handles = sut.photoLibraryContentViewModel.library.allPhotos
                .filter { !$0.isTimelinePlaceholder }
                .map(\.handle)
            #expect(Set(handles).count == handles.count) // no node aliased into two slots
            #expect(handles == [99, 10, 11, 12])         // N, P0, P1 (day1) then Q0 (day2), in order
        }

        @Test("The reactive commit hydrates the visible window inline, so a re-projected visible bucket doesn't flash to placeholders")
        func reactiveTwoPhaseCommitHydratesVisibleWindowInline() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaPageBeforeResult: .success([
                        NodeEntity(name: "n.jpg", handle: 99, hasThumbnail: true),  // the new upload
                        NodeEntity(name: "p0.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "p1.jpg", handle: 11, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.sections(day1: 2, day2: 1),
                        Self.sections(day1: 3, day2: 1) // day1 grows at the front
                    ])))
            await Self.buildColdSkeleton(sut)
            sut.commitHydratedRun(from: 0, with: [
                NodeEntity(name: "p0.jpg", handle: 10, hasThumbnail: true),
                NodeEntity(name: "p1.jpg", handle: 11, hasThumbnail: true),
                NodeEntity(name: "q0.jpg", handle: 12, hasThumbnail: true)
            ])
            // The user is viewing the top; record that as the last visible range (all real → no-op fetch).
            await sut.hydrateVisibleWindow(0..<3)

            // A single reactive pass must leave the visible window already real — no separate,
            // later hydration needed — proving the rebuilt skeleton was hydrated before committing.
            await sut.monitorTimelineSections() // day1 grows at the front

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos.map(\.handle) == [99, 10, 11, 12]) // visible top hydrated in the same commit
            #expect(photos.allSatisfy { !$0.isTimelinePlaceholder })
        }

        @Test("A reactive change with the same shape preserves hydrated nodes")
        func reactiveSameShapePreservesHydration() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success([
                        NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.makeSections(),
                        Self.makeSections() // identical shape
                    ])))
            await Self.buildColdSkeleton(sut)
            await sut.hydrateVisibleWindow(0..<2)

            await sut.monitorTimelineSections() // same shape → keep the hydrated library untouched

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos[0].handle == 10)
            #expect(photos[1].handle == 11)
            #expect(photos[2].isTimelinePlaceholder)
        }

        @Test("A reactive change to no sections shows the empty state")
        func reactiveEmptySectionsShowEmptyState() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([Self.makeSections(), []])))
            await Self.buildColdSkeleton(sut)
            #expect(!sut.showEmptyStateView)

            await sut.monitorTimelineSections()

            #expect(sut.showEmptyStateView)
            #expect(sut.photoLibraryContentViewModel.library.allPhotos.isEmpty)
        }

        @Test("A node metadata update patches the matching hydrated node in place (thumbnail becomes available)")
        func nodeMetadataUpdatePatchesHydratedNodeInPlace() async {
            // A just-uploaded node is hydrated with hasThumbnail == false (its first thumbnail load
            // throws noThumbnail). When the thumbnail becomes available a node update arrives; it
            // must patch the same-handle node in place so the cell reconfigures and reloads —
            // without this the node stays on its placeholder icon until scrolled off and back.
            let sut = makeSUT(
                nodeUseCase: MockNodeUseCase(
                    nodeUpdates: SingleItemAsyncSequence(
                        item: [NodeEntity(name: "n.jpg", handle: 10, hasThumbnail: true)])
                        .eraseToAnyAsyncSequence()),
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([Self.sections(day1: 2, day2: 1)])))
            await Self.buildColdSkeleton(sut)
            sut.commitHydratedRun(from: 0, with: [NodeEntity(name: "n.jpg", handle: 10, hasThumbnail: false)])

            await sut.monitorNodeMetadataUpdates()

            let node = sut.photoLibraryContentViewModel.library.allPhotos[0]
            #expect(node.handle == 10)
            #expect(node.hasThumbnail) // patched in place → cell reconfigures and retries the load
        }

        @Test("A node metadata update for a handle not in the library is a no-op")
        func nodeMetadataUpdateForAbsentHandleIsNoOp() async {
            let sut = makeSUT(
                nodeUseCase: MockNodeUseCase(
                    nodeUpdates: SingleItemAsyncSequence(
                        item: [NodeEntity(name: "other.jpg", handle: 999, hasThumbnail: true)])
                        .eraseToAnyAsyncSequence()),
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([Self.sections(day1: 2, day2: 1)])))
            await Self.buildColdSkeleton(sut)
            let hydrated = NodeEntity(name: "n.jpg", handle: 10, hasThumbnail: false)
            sut.commitHydratedRun(from: 0, with: [hydrated])

            await sut.monitorNodeMetadataUpdates()

            #expect(sut.photoLibraryContentViewModel.library.allPhotos[0].hasThumbnail == false) // unchanged
        }

        @Test("A sensitivity-only update is NOT patched when hidden items are excluded (left to the shape reconcile)")
        func nodeMetadataUpdateForSensitivityOnlyChangeIsNotPatchedWhenHiddenExcluded() async {
            // With hidden items excluded, isMarkedSensitive is a membership change: the section
            // monitor must reproject the node out, not this patch (which would briefly keep a
            // should-be-hidden node on screen). So the update must leave the library untouched.
            let sut = makeSUT(
                nodeUseCase: MockNodeUseCase(
                    nodeUpdates: SingleItemAsyncSequence(
                        item: [NodeEntity(name: "n.jpg", handle: 10, hasThumbnail: true, isMarkedSensitive: true)])
                        .eraseToAnyAsyncSequence()),
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([Self.sections(day1: 2, day2: 1)]),
                    excludeSensitivesResult: true))
            await Self.buildColdSkeleton(sut)
            sut.commitHydratedRun(from: 0, with: [
                NodeEntity(name: "n.jpg", handle: 10, hasThumbnail: true, isMarkedSensitive: false)])

            await sut.monitorNodeMetadataUpdates()

            // Same render fields (hasThumbnail true both sides) → no patch; sensitivity flip ignored here.
            #expect(sut.photoLibraryContentViewModel.library.allPhotos[0].isMarkedSensitive == false)
        }

        /// The reconcile in isolation: two libraries over the same layout, each with its own index.
        @MainActor
        @Suite("Concurrent metadata reconcile")
        struct MetadataReconcile {
            /// Two 2-slot day buckets — the same shape both sides.
            private static let sections: [MediaDateSectionEntity] = {
                let day1 = Date(timeIntervalSince1970: 1_660_780_800) // 2022-08-18T00:00:00Z
                let day2 = Date(timeIntervalSince1970: 1_658_102_400) // 2022-07-18T00:00:00Z
                return [
                    .init(groupId: "2022-08-18", startDate: day1, endDate: day1, count: 2),
                    .init(groupId: "2022-07-18", startDate: day2, endDate: day2, count: 2)
                ]
            }()

            /// A library with `nodes` spliced in from slot 0, plus the index addressing them.
            private static func side(
                _ nodes: [NodeEntity]
            ) -> (library: PhotoLibrary, coordinates: [HandleEntity: TimelineProjection.BucketCoordinate]) {
                let skeleton = TimelineProjection(
                    library: PhotoLibrary.skeleton(from: sections),
                    sections: sections, hydratedCoordinates: [:])
                var coordinates: [HandleEntity: TimelineProjection.BucketCoordinate] = [:]
                for (offset, node) in nodes.enumerated() {
                    guard let anchor = skeleton.sectionAnchor(forFlatIndex: offset) else { continue }
                    coordinates[node.handle] = .init(
                        groupId: anchor.section.groupId, localOffset: anchor.localOffset)
                }
                return (skeleton.library.replacingPhotos(from: 0, with: nodes), coordinates)
            }

            private static func reconciling(
                _ mine: [NodeEntity],
                with theirs: [NodeEntity],
                carryingUnseenNodes: Bool = true,
                showsHiddenNodes: Bool = false
            ) -> NewTimelineViewModel.IndexedLibrary {
                let assembled = side(mine)
                let published = side(theirs)
                return makeSUT().reconciling(
                    .init(library: assembled.library, coordinates: assembled.coordinates),
                    describedBy: sections,
                    with: TimelineProjection(
                        library: published.library, sections: sections,
                        hydratedCoordinates: published.coordinates),
                    carryingUnseenNodes: carryingUnseenNodes,
                    showsHiddenNodes: showsHiddenNodes)
            }

            /// Same buckets on both sides, so the node's address still means what it meant.
            @Test("A node only the other side has fetched is carried in, index and all")
            func carriesInNodesOnlyTheOtherSideFetched() {
                let result = Self.reconciling([], with: [NodeEntity(handle: 10, hasThumbnail: true)])

                #expect(result.library.allPhotos[0].handle == 10)
                #expect(result.coordinates[10] == .init(groupId: "2022-08-18", localOffset: 0))
            }

            /// Across a query change the two are different sequences, so a slot the other side
            /// filled says nothing about what belongs here. Shared-handle metadata still moves.
            @Test("A node only the other side has fetched is not adopted across a query change")
            func doesNotAdoptUnseenNodesAcrossAQueryChange() {
                let result = Self.reconciling(
                    [NodeEntity(handle: 11, hasThumbnail: false)],
                    with: [
                        NodeEntity(handle: 10, hasThumbnail: true),
                        NodeEntity(handle: 11, hasThumbnail: true)
                    ],
                    carryingUnseenNodes: false)

                #expect(result.library.allPhotos[0].handle == 11) // this query's own slot 0, untouched
                #expect(result.library.allPhotos[0].hasThumbnail) // same node, so its thumbnail moves
                #expect(result.coordinates.keys.sorted() == [11]) // 10 was never taken in
                #expect(result.library.allPhotos[1].isTimelinePlaceholder)
            }

            /// A resized bucket makes a local offset meaningless, so nothing addressed in it lands.
            @Test("A node in a bucket that resized is not carried in")
            func doesNotCarryIntoAResizedBucket() {
                let published = Self.side([NodeEntity(handle: 10, hasThumbnail: true)])
                // The same buckets, but the first one grew by a slot under the other side's feet.
                let grown: [MediaDateSectionEntity] = [
                    .init(groupId: "2022-08-18", startDate: Date(timeIntervalSince1970: 1_660_780_800),
                          endDate: Date(timeIntervalSince1970: 1_660_780_800), count: 3),
                    Self.sections[1]
                ]

                let result = makeSUT().reconciling(
                    .init(library: PhotoLibrary.skeleton(from: grown), coordinates: [:]),
                    describedBy: grown,
                    with: TimelineProjection(
                        library: published.library, sections: Self.sections,
                        hydratedCoordinates: published.coordinates),
                    carryingUnseenNodes: true,
                    showsHiddenNodes: false)

                #expect(result.library.allPhotos.allSatisfy { $0.isTimelinePlaceholder })
                #expect(result.coordinates.isEmpty)
            }

            @Test("A node the other side has fresher is adopted, keeping its slot")
            func adoptsTheFresherNodeInPlace() {
                let photos = Self.reconciling(
                    [NodeEntity(handle: 10, isFavourite: false), NodeEntity(handle: 11, isFavourite: false)],
                    with: [NodeEntity(handle: 10, isFavourite: true), NodeEntity(handle: 11, isFavourite: false)]
                ).library.allPhotos

                #expect(photos[0].handle == 10) // same slot
                #expect(photos[0].isFavourite)
                #expect(photos[1].isFavourite == false)
                #expect(photos.count == 4) // shape preserved
            }

            /// The other side's index doesn't address it, so there is nothing to reconcile against.
            @Test("A node the other side has not fetched is left alone")
            func keepsNodesAbsentFromTheOtherSide() {
                let photos = Self.reconciling(
                    [NodeEntity(handle: 10, hasThumbnail: true)], with: []).library.allPhotos

                #expect(photos[0].handle == 10)
                #expect(photos[0].hasThumbnail)
            }

            @Test("Readiness never regresses — a thumbnail in hand is not traded for one that is missing")
            func neverRegressesReadiness() {
                let photos = Self.reconciling(
                    [NodeEntity(handle: 10, hasThumbnail: true, hasPreview: true)],
                    with: [NodeEntity(handle: 10, hasThumbnail: false, hasPreview: false)]
                ).library.allPhotos

                #expect(photos[0].hasThumbnail)
                #expect(photos[0].hasPreview)
            }

            @Test("Nothing to move leaves the tree untouched")
            func unchangedWhenNothingDiffers() {
                let mine = [NodeEntity(handle: 10, hasThumbnail: true)]
                let photos = Self.reconciling(mine, with: mine).library.allPhotos

                #expect(photos[0] == mine[0])
            }

            /// When hidden items are excluded, hiding a node is a membership change for the section
            /// monitor, not a re-render.
            @Test("A sensitivity flip moves only when hidden items are shown", arguments: [false, true])
            func sensitivityMovesOnlyWhenHiddenShown(showsHiddenNodes: Bool) {
                let photos = Self.reconciling(
                    [NodeEntity(handle: 10, isMarkedSensitive: false)],
                    with: [NodeEntity(handle: 10, isMarkedSensitive: true)],
                    showsHiddenNodes: showsHiddenNodes
                ).library.allPhotos

                #expect(photos[0].isMarkedSensitive == showsHiddenNodes)
            }
        }

        /// Both the pass and the scroll bump `libraryRevision`, so a hydration settling mid-pass is
        /// also a commit to fold in. Dropping it would revert the node to a placeholder, and the
        /// visible range is de-duplicated — parked where they are, the user never refetches it.
        @Test("A scroll hydration that commits mid-pass survives the reactive commit")
        func reactivePassKeepsAScrollHydrationThatLandedDuringIt() async {
            let scroll = ScrollHydrationTrigger()
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    // What the scroll's cursor run fetches: day1's second slot and day2's only slot.
                    mediaPageResult: .success([
                        NodeEntity(name: "d1b.jpg", handle: 11, hasThumbnail: true),
                        NodeEntity(name: "d2.jpg", handle: 20, hasThumbnail: true)
                    ]),
                    // The reactive pass's own window finds nothing, keeping the two apart.
                    mediaWindowResult: .success([]),
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.sections(day1: 2, day2: 1),
                        Self.sections(day1: 3, day2: 1) // day1 reshapes, day2 is untouched
                    ]),
                    onFetch: { await scroll.fireOnce() }))
            scroll.sut = sut
            scroll.range = 1..<3 // the gap below the planted anchor, in the layout on screen
            await Self.buildColdSkeleton(sut)
            sut.commitHydratedRun(from: 0, with: [NodeEntity(name: "d1a.jpg", handle: 10, hasThumbnail: true)])
            scroll.arm()

            await sut.monitorTimelineSections()

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos.count == 4)
            // day1 resized, so everything addressed inside it goes back to placeholders — 10 and 11.
            #expect(photos[0...2].allSatisfy { $0.isTimelinePlaceholder })
            // day2 did not, so the node the scroll landed there is carried to its new base.
            #expect(photos[3].handle == 20)
        }

        /// Planting through `commitHydratedRun` proves the index's consumers work; only a real fetch
        /// proves its producer does. If `applyHydrationResults` stopped recording where it put
        /// things, every planting test would still pass and the reshape below would lose the node.
        @Test("A node hydrated by a real fetch is indexed, so a later reshape can carry it")
        func realHydrationRecordsWhereItPutThings() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    mediaWindowResult: .success([NodeEntity(name: "d2.jpg", handle: 20, hasThumbnail: true)]),
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.sections(day1: 1, day2: 1), // 2 slots
                        Self.sections(day1: 2, day2: 1)  // day1 grows; day2 is untouched
                    ])))
            await Self.buildColdSkeleton(sut)

            // Slot 1 is day2's only slot and has no real neighbour → an offset window, spliced and
            // indexed by the production path alone.
            await sut.hydrateVisibleWindow(1..<2)
            #expect(sut.photoLibraryContentViewModel.library.allPhotos[1].handle == 20)

            await sut.monitorTimelineSections() // day1: 1 → 2

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos.count == 3)
            #expect(photos[0...1].allSatisfy { $0.isTimelinePlaceholder }) // day1's two slots
            #expect(photos[2].handle == 20) // carried: only the index knew it was day2's offset 0
        }

        /// The pass assembles from the library as it stood when it started, so a patch landing
        /// during its awaits is not in it — publishing it unchanged would revert the node.
        @Test("A metadata patch landing mid-pass survives the reactive commit instead of being reverted")
        func reactivePassKeepsAMetadataPatchThatLandedDuringIt() async {
            let patch = MetadataPatchTrigger()
            let sut = makeSUT(
                nodeUseCase: MockNodeUseCase(
                    nodeUpdates: SingleItemAsyncSequence(
                        item: [NodeEntity(name: "d1.jpg", handle: 10, hasThumbnail: true)])
                        .eraseToAnyAsyncSequence()),
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.sections(day1: 2, day2: 1),
                        Self.sections(day1: 2, day2: 2) // day2 reshapes; day1 carries node 10 across
                    ]),
                    onFetch: { await patch.fireOnce() }))
            patch.sut = sut
            await Self.buildColdSkeleton(sut)
            // Hydrated without a thumbnail — how a just-uploaded node is first fetched.
            sut.commitHydratedRun(
                from: 0, with: [NodeEntity(name: "d1.jpg", handle: 10, hasThumbnail: false)])
            patch.arm() // land the patch inside the reactive pass's own hydration fetch

            await sut.monitorTimelineSections()

            let node = sut.photoLibraryContentViewModel.library.allPhotos[0]
            #expect(node.handle == 10)
            #expect(node.hasThumbnail) // reconciled in, not reverted to the pass's pre-patch snapshot
        }

        @Test("A sensitivity-only update IS patched in place when hidden items are shown (re-render blurred)")
        func nodeMetadataUpdateForSensitivityOnlyChangeIsPatchedWhenHiddenShown() async {
            // With hidden items shown, hiding a node keeps it in the set (unchanged count, so the
            // section monitor does nothing); only this in-place patch can re-render it blurred.
            let sut = makeSUT(
                nodeUseCase: MockNodeUseCase(
                    nodeUpdates: SingleItemAsyncSequence(
                        item: [NodeEntity(name: "n.jpg", handle: 10, hasThumbnail: true, isMarkedSensitive: true)])
                        .eraseToAnyAsyncSequence()),
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([Self.sections(day1: 2, day2: 1)]),
                    excludeSensitivesResult: false))
            await Self.buildColdSkeleton(sut)
            sut.commitHydratedRun(from: 0, with: [
                NodeEntity(name: "n.jpg", handle: 10, hasThumbnail: true, isMarkedSensitive: false)])

            await sut.monitorNodeMetadataUpdates()

            let node = sut.photoLibraryContentViewModel.library.allPhotos[0]
            #expect(node.handle == 10)
            #expect(node.isMarkedSensitive) // patched in place → cell reconfigures and blurs
        }

        // MARK: - Selecting cells that have not loaded

        private static func handler(_ sut: NewTimelineViewModel) -> (any PositionalSelectionHandling)? {
            sut.photoLibraryContentViewModel.positionalSelectionHandler
        }

        /// Stamped with the version of the library on screen. Nothing here renders, so there is no
        /// grid lagging a debounce behind one — that gap is the coordinator's side of the contract.
        private static func position(_ flatIndex: Int, in sut: NewTimelineViewModel) -> SelectionPosition {
            SelectionPosition(
                flatIndex: flatIndex,
                layoutVersion: sut.photoLibraryContentViewModel.library.layoutVersion)
        }

        @Test("A reshape stamps a new layout version on the grid; filling a slot leaves it where it was")
        func reshapeMovesTheLayoutVersionAndHydrationDoesNot() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.sections(day1: 2, day2: 1),
                        Self.sections(day1: 3, day2: 1)
                    ])))
            await Self.buildColdSkeleton(sut)
            let version = sut.photoLibraryContentViewModel.library.layoutVersion

            sut.commitHydratedRun(from: 0, with: [NodeEntity(name: "a.jpg", handle: 10)])
            #expect(sut.photoLibraryContentViewModel.library.layoutVersion == version)

            sut.photoLibraryContentViewModel.visiblePhotoIndexRange.send(0..<0)
            await sut.monitorTimelineSections() // day1 grows by one

            #expect(sut.photoLibraryContentViewModel.library.layoutVersion == version + 1)
        }

        @Test("A mark on a cell with no photo is pinned to that photo the moment it arrives")
        func markingAPlaceholderCommitsOnceItsPhotoLands() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([Self.sections(day1: 2, day2: 1)])))
            await Self.buildColdSkeleton(sut)
            sut.updateEditMode(.active)

            Self.handler(sut)?.apply(.tap, at: Self.position(0, in: sut))
            #expect(sut.markedItemCount == 1)
            #expect(sut.photoLibraryContentViewModel.selection.photos.isEmpty) // no node to commit yet

            let node = NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true)
            sut.commitHydratedRun(from: 0, with: [node])

            #expect(sut.photoLibraryContentViewModel.selection.photos[10] == node)
            #expect(sut.markedItemCount == 1) // the same one cell, now named by its handle
        }

        @Test("A mark in a bucket that resized is dropped, and one in a bucket that did not is kept")
        func aReshapedBucketDropsItsMarks() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.sections(day1: 2, day2: 1),
                        Self.sections(day1: 3, day2: 1)
                    ])))
            await Self.buildColdSkeleton(sut)
            sut.updateEditMode(.active)
            Self.handler(sut)?.apply(.tap, at: Self.position(0, in: sut)) // day1
            Self.handler(sut)?.apply(.tap, at: Self.position(2, in: sut)) // day2
            #expect(sut.markedItemCount == 2)

            sut.photoLibraryContentViewModel.visiblePhotoIndexRange.send(0..<0)
            await sut.monitorTimelineSections() // day1 grows at the front

            #expect(sut.markedItemCount == 1)
            #expect(Self.handler(sut)?.isSelected(at: Self.position(3, in: sut)) == true) // day2, moved down
        }

        @Test("A filter change takes every mark with it — the positions were counted under the old query")
        func aQueryChangeClearsMarks() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams([
                        Self.sections(day1: 2, day2: 1),
                        Self.sections(day1: 2, day2: 1)
                    ])))
            await Self.buildColdSkeleton(sut)
            sut.updateEditMode(.active)
            Self.handler(sut)?.apply(.tap, at: Self.position(0, in: sut))

            await sut.updatePhotoFilter(option: .images)
            sut.photoLibraryContentViewModel.visiblePhotoIndexRange.send(0..<0)
            await sut.monitorTimelineSections()

            #expect(sut.markedItemCount == 0)
        }
    }

    @MainActor
    @Suite("Empty View")
    struct EmptyView {
        @Test("Camera upload enabled ensure correct no media found empty type returned")
        func emptyViewCameraUploadEnabled() async {
            let sut = makeSUT(preferenceUseCase: MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: true]))
            await sut.updatePhotoFilter(option: .allMedia)
            await sut.updatePhotoFilter(option: .allLocations)
            
            let emptyScreenType = sut.emptyScreenTypeToShow()
            
            #expect(emptyScreenType == .noMediaFound)
        }
        
        @Test("Ensure the correct empty view type is shown for filter when camera upload is not enabled",
              arguments: [
                (filterType: PhotosFilterOptionsEntity.allMedia,
                 filterLocation: PhotosFilterOptionsEntity.allLocations, expectedViewType: PhotosEmptyScreenViewType.enableCameraUploads),
                (filterType: .allMedia, filterLocation: .cloudDrive, expectedViewType: .noMediaFound),
                (filterType: .allMedia, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads),
                (filterType: .images, filterLocation: .allLocations, expectedViewType: .enableCameraUploads),
                (filterType: .images, filterLocation: .cloudDrive, expectedViewType: .noImagesFound),
                (filterType: .images, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads),
                (filterType: .videos, filterLocation: .allLocations, expectedViewType: .enableCameraUploads),
                (filterType: .videos, filterLocation: .cloudDrive, expectedViewType: .noVideosFound),
                (filterType: .videos, filterLocation: .cameraUploads, expectedViewType: .enableCameraUploads)
              ])
        func emptyViewType(
            filterType: PhotosFilterOptionsEntity,
            filterLocation: PhotosFilterOptionsEntity,
            expectedViewType: PhotosEmptyScreenViewType
        ) async throws {
            let sut = makeSUT(preferenceUseCase: MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false]))
            await sut.updatePhotoFilter(option: filterType)
            await sut.updatePhotoFilter(option: filterLocation)
            
            let emptyScreenType = sut.emptyScreenTypeToShow()
            
            #expect(emptyScreenType == expectedViewType)
        }
    }
    
    @MainActor
    @Test
    func updateSortOrder() async throws {
        let photos = [
            NodeEntity(name: "test.jpg", handle: 1, hasThumbnail: true)
        ]
        let photoLibraryContentViewModel = PhotoLibraryContentViewModel(
            library: photos.toPhotoLibrary(withSortType: .modificationDesc))
        
        let sut = Self.makeSUT(
            photoLibraryContentViewModel: photoLibraryContentViewModel
        )
        
        try await confirmation { confirmation in
            let cancellable = photoLibraryContentViewModel
                .$library
                .sink { _ in
                    confirmation()
                }
            
            sut.updateSortOrder(.modificationDesc)
            
            try await sut.sortPhotoLibraryTask?.value
            cancellable.cancel()
        }
    }
    
    /// The direction is the timeline's own preference: it must never reach the app-wide sort
    /// preference, which Cloud Drive and every other screen read.
    @MainActor
    @Suite("Sort Order Persistence")
    struct SortOrderPersistence {
        private static let oldestFirstKey = PreferenceKeyEntity.mediaTimelineSortedOldestFirst.rawValue

        @Test("Selecting a sort order saves it in the timeline's own preference")
        func savesSelectedSortOrder() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(preferenceUseCase: preferenceUseCase)

            sut.updateSortOrder(.modificationAsc)

            #expect(preferenceUseCase.dict[Self.oldestFirstKey] as? Bool == true)
            #expect(sut.sortOrder == .modificationAsc)
        }

        @Test("Selecting the current sort order again leaves it where it was")
        func unchangedSortOrderIsNotSaved() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(preferenceUseCase: preferenceUseCase)

            sut.updateSortOrder(.modificationDesc)

            #expect(preferenceUseCase.dict[Self.oldestFirstKey] as? Bool == false)
            #expect(sut.sortOrder == .modificationDesc)
        }

        @Test("A direction chosen before the timeline kept its own order is inherited once",
              arguments: [
                (inherited: SortOrderEntity.modificationAsc, expected: SortOrderEntity.modificationAsc),
                (inherited: .modificationDesc, expected: .modificationDesc),
                (inherited: .defaultAsc, expected: .modificationDesc),
                (inherited: .none, expected: .modificationDesc)
              ])
        func inheritsTheDirectionFromTheAppWidePreference(
            inherited: SortOrderEntity,
            expected: SortOrderEntity
        ) {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(
                preferenceUseCase: preferenceUseCase,
                sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: inherited))

            #expect(sut.sortOrder == expected)
            // Persisted straight away, so the app-wide preference is read on this launch only.
            #expect(preferenceUseCase.dict[Self.oldestFirstKey] as? Bool == (expected == .modificationAsc))
        }

        @Test("Once the timeline has its own order, the app-wide preference is never consulted")
        func storedOrderWinsOverTheAppWidePreference() {
            let sortOrderPreferenceUseCase = MockSortOrderPreferenceUseCase(sortOrderEntity: .modificationAsc)
            let sut = makeSUT(
                preferenceUseCase: MockPreferenceUseCase(dict: [Self.oldestFirstKey: false]),
                sortOrderPreferenceUseCase: sortOrderPreferenceUseCase)

            #expect(sut.sortOrder == .modificationDesc)
            #expect(sortOrderPreferenceUseCase.getSortOrderCallCount == 0)
        }

        @Test("The stored sort order is restored before the first load",
              arguments: [
                (stored: true, expected: SortOrderEntity.modificationAsc),
                (stored: false, expected: .modificationDesc)
              ])
        func restoresStoredSortOrder(stored: Bool, expected: SortOrderEntity) {
            let sut = makeSUT(preferenceUseCase: MockPreferenceUseCase(
                dict: [Self.oldestFirstKey: stored]))

            #expect(sut.sortOrder == expected)
        }

        @Test("An order the menu doesn't offer normalises to newest first")
        func normalisesAnOrderTheMenuDoesNotOffer() {
            let preferenceUseCase = MockPreferenceUseCase(dict: [Self.oldestFirstKey: true])
            let sut = makeSUT(preferenceUseCase: preferenceUseCase)

            sut.updateSortOrder(.defaultAsc)

            #expect(sut.sortOrder == .modificationDesc)
            #expect(preferenceUseCase.dict[Self.oldestFirstKey] as? Bool == false)
        }
    }

    @MainActor
    @Test
    func updatePhotoFilter() async {
        let contentConsumption = MockContentConsumptionUserAttributeUseCase()
        let sut = Self.makeSUT(
            contentConsumptionUserAttributeUseCase: contentConsumption
        )
        let taskId = sut.loadPhotosTaskId
        #expect(sut.photoFilterOptions == [.allMedia, .allLocations])
        
        let newFilter: PhotosFilterOptionsEntity = [.images, .allLocations]
        await sut.updatePhotoFilter(option: newFilter)
        
        #expect(sut.photoFilterOptions == newFilter)
        #expect(sut.loadPhotosTaskId != taskId)
        
        await sut.saveFiltersTask?.value
        
        #expect(contentConsumption.savedTimelineUserAttribute == .init(mediaType: .images, location: .allLocations, usePreference: true))
    }
    
    @MainActor
    @Test(arguments: [
        (PhotosFilterOptions.allLocations, true, false),
        (PhotosFilterOptions.allLocations, false, false),
        (PhotosFilterOptions.cloudDrive, false, true)
    ])
    func enableCameraBannerAction(
        location: PhotosFilterOptions,
        cameraUploadEnabled: Bool,
        actionShouldRoute: Bool
    ) {
        let cameraUploadsSettingsViewRouter = MockRouter()
        let sut = Self.makeSUT(
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            preferenceUseCase: MockPreferenceUseCase(
                dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: cameraUploadEnabled]))
        
        let action = sut.enableCameraUploadsBannerAction(filterLocation: location)
        if actionShouldRoute {
            action?()
            #expect(cameraUploadsSettingsViewRouter.startCalled == 1)
        } else {
            #expect(action == nil)
        }
    }
    
    @MainActor
    @Test
    func filterChangesTrackAnalyticsCorrectly() async {
        let tracker = MockTracker()
        let sut = Self.makeSUT(
            tracker: tracker
        )
        await sut.updatePhotoFilter(option: .images)
        await sut.updatePhotoFilter(option: .videos)
        await sut.updatePhotoFilter(option: .allMedia)
        await sut.updatePhotoFilter(option: .cloudDrive)
        await sut.updatePhotoFilter(option: .cameraUploads)
        await sut.updatePhotoFilter(option: .allLocations)
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                MediaScreenFilterImagesSelectedEvent(),
                MediaScreenFilterVideosSelectedEvent(),
                MediaScreenFilterAllMediaSelectedEvent(),
                MediaScreenFilterCloudDriveSelectedEvent(),
                MediaScreenFilterCameraUploadsSelectedEvent(),
                MediaScreenFilterAllLocationsSelectedEvent()
            ]
        )
    }
    
    @MainActor
    private static func makeSUT(
        photoLibraryContentViewModel: PhotoLibraryContentViewModel = .init(library: PhotoLibrary()),
        photoLibraryContentViewRouter: PhotoLibraryContentViewRouter = PhotoLibraryContentViewRouter(),
        cameraUploadsSettingsViewRouter: some Routing = MockRouter(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        contentConsumptionUserAttributeUseCase: some ContentConsumptionUserAttributeUseCaseProtocol = MockContentConsumptionUserAttributeUseCase(),
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = MockSortOrderPreferenceUseCase(),
        mediaTimelineUseCase: (any MediaTimelineUseCaseProtocol)? = nil,
        isDateTakenSortEnabled: Bool = false,
        tracker: some AnalyticsTracking = MockTracker()
    ) -> NewTimelineViewModel {
        .init(
            photoLibraryContentViewModel: photoLibraryContentViewModel,
            photoLibraryContentViewRouter: photoLibraryContentViewRouter,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            preferenceUseCase: preferenceUseCase,
            photoLibraryUseCase: photoLibraryUseCase,
            nodeUseCase: nodeUseCase,
            contentConsumptionUserAttributeUseCase: contentConsumptionUserAttributeUseCase,
            sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
            mediaTimelineUseCase: mediaTimelineUseCase,
            isDateTakenSortEnabled: isDateTakenSortEnabled,
            tracker: tracker
        )
    }

    /// The timeline's sort order carries two axes — direction and timestamp — both of them local
    /// preferences of its own; the timestamp one only exists while the feature flag is on.
    @MainActor
    @Suite
    struct MediaTimelineSortOrder {
        private static let dateTakenKey = PreferenceKeyEntity.mediaTimelineSortedByDateTaken.rawValue
        private static let oldestFirstKey = PreferenceKeyEntity.mediaTimelineSortedOldestFirst.rawValue

        private static func makeSections() -> [MediaDateSectionEntity] {
            [MediaDateSectionEntity(
                groupId: "2026-08-21",
                startDate: Date(timeIntervalSince1970: 1_755_734_400),
                endDate: Date(timeIntervalSince1970: 1_755_820_800),
                count: 2)]
        }

        private static func sectionStreams() -> [AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>>] {
            [SingleItemAsyncSequence(item: .success(makeSections())).eraseToAnyAsyncSequence()]
        }

        /// The paginated path queries under the sort order from the section monitor, not from
        /// `loadPhotos()` — so drive both, the way the View does.
        private static func loadUnderCurrentSortOrder(_ sut: NewTimelineViewModel) async {
            await sut.loadPhotos()
            await sut.monitorTimelineSections()
        }

        @Test("The menu offers nothing while the flag is off, even on the paginated path")
        func sortTypeIsNilWhenFlagIsOff() {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(),
                isDateTakenSortEnabled: false)

            #expect(sut.mediaTimelineSortType == nil)
        }

        @Test("The eager path offers the order too — it groups its loaded nodes by the timestamp")
        func sortTypeIsOfferedOnTheEagerPathAsWell() {
            let sut = makeSUT(mediaTimelineUseCase: nil, isDateTakenSortEnabled: true)

            #expect(sut.mediaTimelineSortType == .newest)
        }

        @Test("The eager path orders and buckets by the stored timestamp")
        func eagerPathHonoursTheStoredTimestamp() async {
            // Capture times run opposite to modification times, so the two bases invert the grid.
            let photos = [
                NodeEntity(name: "a.jpg", handle: 1, hasThumbnail: true,
                           modificationTime: Date(timeIntervalSince1970: 1_000_000),
                           mediaCaptureTime: Date(timeIntervalSince1970: 3_000_000)),
                NodeEntity(name: "b.jpg", handle: 2, hasThumbnail: true,
                           modificationTime: Date(timeIntervalSince1970: 2_000_000),
                           mediaCaptureTime: Date(timeIntervalSince1970: 500_000))
            ]
            let sut = makeSUT(
                preferenceUseCase: MockPreferenceUseCase(dict: [Self.dateTakenKey: true]),
                photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: photos),
                mediaTimelineUseCase: nil,
                isDateTakenSortEnabled: true)

            await sut.loadPhotos()

            #expect(sut.photoLibraryContentViewModel.library.allPhotos.map(\.handle) == [1, 2])
        }

        @Test("Changing only the timestamp re-groups the loaded nodes instead of reloading them")
        func eagerPathTimestampChangeReSortsInPlace() async throws {
            let photos = [
                NodeEntity(name: "a.jpg", handle: 1, hasThumbnail: true,
                           modificationTime: Date(timeIntervalSince1970: 1_000_000),
                           mediaCaptureTime: Date(timeIntervalSince1970: 3_000_000)),
                NodeEntity(name: "b.jpg", handle: 2, hasThumbnail: true,
                           modificationTime: Date(timeIntervalSince1970: 2_000_000),
                           mediaCaptureTime: Date(timeIntervalSince1970: 500_000))
            ]
            let sut = makeSUT(
                photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: photos),
                mediaTimelineUseCase: nil,
                isDateTakenSortEnabled: true)
            await sut.loadPhotos()
            #expect(sut.photoLibraryContentViewModel.library.allPhotos.map(\.handle) == [2, 1])
            let loadId = sut.loadPhotosTaskId

            sut.updateMediaTimelineSortOrder(.newestByCaptureTime)
            try await sut.sortPhotoLibraryTask?.value

            #expect(sut.photoLibraryContentViewModel.library.allPhotos.map(\.handle) == [1, 2])
            #expect(sut.loadPhotosTaskId == loadId, "the eager path already holds every node")
        }

        @Test("The offered order combines both stored axes",
              arguments: [
                (false, true, MediaTimelineSortOrderEntity.newestByCaptureTime),
                (true, true, .oldestByCaptureTime),
                (false, false, .newest),
                (true, false, .oldest)
              ])
        func sortTypeCombinesBothAxes(
            storedOldestFirst: Bool,
            storedDateTaken: Bool,
            expected: MediaTimelineSortOrderEntity
        ) {
            let sut = makeSUT(
                preferenceUseCase: MockPreferenceUseCase(dict: [
                    Self.dateTakenKey: storedDateTaken,
                    Self.oldestFirstKey: storedOldestFirst
                ]),
                mediaTimelineUseCase: MockMediaTimelineUseCase(),
                isDateTakenSortEnabled: true)

            #expect(sut.mediaTimelineSortType == expected)
        }

        @Test("A stored date-taken choice is ignored — not cleared — while the flag is off")
        func storedChoiceIsOverriddenWhileTheFlagIsOff() async {
            let recorder = MediaTimelineUseCaseRecorder()
            let preferenceUseCase = MockPreferenceUseCase(dict: [Self.dateTakenKey: true])
            let sut = makeSUT(
                preferenceUseCase: preferenceUseCase,
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams(),
                    recorder: recorder),
                isDateTakenSortEnabled: false)

            await Self.loadUnderCurrentSortOrder(sut)

            let queried = await recorder.sortOrders
            #expect(!queried.isEmpty)
            #expect(queried.allSatisfy { $0 == .newest })
            // The choice survives for when the flag comes back.
            #expect(preferenceUseCase.dict[Self.dateTakenKey] as? Bool == true)
        }

        @Test("With the flag on, the stored choice reaches the query")
        func storedChoiceReachesTheQuery() async {
            let recorder = MediaTimelineUseCaseRecorder()
            let sut = makeSUT(
                preferenceUseCase: MockPreferenceUseCase(dict: [Self.dateTakenKey: true]),
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    monitorDateSectionsSequences: Self.sectionStreams(),
                    recorder: recorder),
                isDateTakenSortEnabled: true)

            await Self.loadUnderCurrentSortOrder(sut)

            let queried = await recorder.sortOrders
            #expect(!queried.isEmpty)
            #expect(queried.allSatisfy { $0 == .newestByCaptureTime })
        }

        @Test("Changing only the timestamp persists it and reloads, leaving the direction alone")
        func timestampOnlyChangePersistsLocallyAndReloads() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(
                preferenceUseCase: preferenceUseCase,
                mediaTimelineUseCase: MockMediaTimelineUseCase(),
                isDateTakenSortEnabled: true)
            let loadId = sut.loadPhotosTaskId
            let queryId = sut.timelineQueryId

            sut.updateMediaTimelineSortOrder(.newestByCaptureTime)

            #expect(preferenceUseCase.dict[Self.dateTakenKey] as? Bool == true)
            #expect(sut.mediaTimelineSortType == .newestByCaptureTime)
            #expect(sut.loadPhotosTaskId != loadId)
            #expect(sut.timelineQueryId != queryId)
            // The direction did not move.
            #expect(preferenceUseCase.dict[Self.oldestFirstKey] as? Bool == false)
        }

        @Test("Changing the direction persists it in the timeline's own preference")
        func directionChangePersistsLocally() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(
                preferenceUseCase: preferenceUseCase,
                mediaTimelineUseCase: MockMediaTimelineUseCase(),
                isDateTakenSortEnabled: true)

            sut.updateMediaTimelineSortOrder(.oldestByCaptureTime)

            #expect(preferenceUseCase.dict[Self.oldestFirstKey] as? Bool == true)
            #expect(preferenceUseCase.dict[Self.dateTakenKey] as? Bool == true)
            #expect(sut.mediaTimelineSortType == .oldestByCaptureTime)
        }

        @Test("Switching back to the modification time clears the local choice")
        func switchingBackClearsTheLocalChoice() {
            let preferenceUseCase = MockPreferenceUseCase(dict: [Self.dateTakenKey: true])
            let sut = makeSUT(
                preferenceUseCase: preferenceUseCase,
                mediaTimelineUseCase: MockMediaTimelineUseCase(),
                isDateTakenSortEnabled: true)

            sut.updateMediaTimelineSortOrder(.newest)

            #expect(preferenceUseCase.dict[Self.dateTakenKey] as? Bool == false)
            #expect(sut.mediaTimelineSortType == .newest)
        }

        @Test("Re-picking the active order changes nothing")
        func rePickingTheActiveOrderIsANoOp() {
            let preferenceUseCase = MockPreferenceUseCase()
            let sut = makeSUT(
                preferenceUseCase: preferenceUseCase,
                mediaTimelineUseCase: MockMediaTimelineUseCase(),
                isDateTakenSortEnabled: true)
            let loadId = sut.loadPhotosTaskId
            let queryId = sut.timelineQueryId

            sut.updateMediaTimelineSortOrder(.newest)

            #expect(sut.loadPhotosTaskId == loadId)
            #expect(sut.timelineQueryId == queryId)
            #expect(preferenceUseCase.dict[Self.dateTakenKey] as? Bool == nil)
            #expect(preferenceUseCase.dict[Self.oldestFirstKey] as? Bool == false)
        }
    }
}
