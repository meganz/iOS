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

        private static func sectionStream(
            _ sections: [MediaDateSectionEntity]
        ) -> AnyAsyncSequence<Result<[MediaDateSectionEntity], any Error>> {
            SingleItemAsyncSequence(item: .success(sections)).eraseToAnyAsyncSequence()
        }

        @Test("Builds a placeholder skeleton from date-section counts without touching the eager use case")
        func buildsSkeletonFromDateSections() async throws {
            let photoLibraryUseCase = MockPhotoLibraryUseCase(allPhotos: [
                NodeEntity(name: "real.jpg", handle: 1, hasThumbnail: true)
            ])
            let sut = makeSUT(
                photoLibraryUseCase: photoLibraryUseCase,
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    dateSectionsResult: .success(Self.makeSections())))

            await sut.loadPhotos()

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            let allArePlaceholders = photos.allSatisfy(\.isTimelinePlaceholder)
            #expect(photos.count == 3) // 2 + 1
            #expect(allArePlaceholders)
            #expect(!sut.showEmptyStateView)
            // The eager media(...) path must not run when the skeleton use case is present.
            await #expect(photoLibraryUseCase.messages == [])
        }

        @Test("Empty date sections show the empty state and an empty library")
        func emptySectionsShowEmptyState() async throws {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    dateSectionsResult: .success([])))

            await sut.loadPhotos()

            #expect(sut.showEmptyStateView)
            #expect(sut.photoLibraryContentViewModel.library.allPhotos.isEmpty)
        }

        @Test("The initial load hydrates the first window up front, so the top screen shows real nodes without a scroll")
        func initialLoadEagerlyHydratesFirstWindow() async {
            let recorder = MediaTimelineUseCaseRecorder()
            let firstPage = [
                NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
            ]
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    dateSectionsResult: .success(Self.makeSections()), // counts 2 + 1 = 3
                    mediaPageResult: .success(firstPage),
                    recorder: recorder))

            await sut.loadPhotos()

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos.count == 3) // total sized from the counts
            #expect(photos[0].handle == 10) // first page spliced at the top *before* the initial commit
            #expect(photos[1].handle == 11)
            #expect(photos[2].isTimelinePlaceholder) // beyond the fetched page → still a placeholder
            // The first window is fetched once, as a forward page from the very top (after: nil).
            let pageAfterCalls = await recorder.pageAfterCalls
            #expect(pageAfterCalls.count == 1)
            #expect(pageAfterCalls.first?.after == nil)
        }

        @Test("Hydrating a visible window splices fetched real nodes into the skeleton in place")
        func hydrateVisibleWindowSplicesRealNodes() async {
            let reals = [
                NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
            ]
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    dateSectionsResult: .success(Self.makeSections()), // counts 2 + 1 = 3
                    mediaWindowResult: .success(reals)))
            await sut.loadPhotos() // builds the 3-slot skeleton and stores the sections

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
                    dateSectionsResult: .success(Self.makeSections()), // counts 2 + 1 = 3
                    // The gap borders a real node, so it must page forward from it (cursor),
                    // not teleport by offset — the offset result must stay unused.
                    mediaPageResult: .success([NodeEntity(name: "gap.jpg", handle: 99, hasThumbnail: true)]),
                    mediaWindowResult: .success([NodeEntity(name: "wrong.jpg", handle: 500, hasThumbnail: true)]),
                    recorder: recorder))
            await sut.loadPhotos() // 3-slot skeleton (eagerly hydrates the first window)
            await recorder.reset() // ignore the initial eager fetch; assert only the scroll hydration below

            // Pre-hydrate slot 0 so the next visible window overlaps an already-real slot.
            let library = sut.photoLibraryContentViewModel.library
            sut.photoLibraryContentViewModel.library = library.replacingPhotos(from: 0, with: [realSlot0])

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
                    dateSectionsResult: .success(Self.makeSections()), // counts 2 + 1 = 3
                    mediaPageBeforeResult: .success([NodeEntity(name: "up.jpg", handle: 77, hasThumbnail: true)]),
                    mediaWindowResult: .success([NodeEntity(name: "wrong.jpg", handle: 500, hasThumbnail: true)]),
                    recorder: recorder))
            await sut.loadPhotos() // 3-slot skeleton (eagerly hydrates the first window)
            await recorder.reset() // ignore the initial eager fetch; assert only the scroll hydration below

            // Pre-hydrate the LAST slot so the gap above it has a real lower neighbour and no real
            // upper neighbour → backward paging.
            let library = sut.photoLibraryContentViewModel.library
            sut.photoLibraryContentViewModel.library = library.replacingPhotos(from: 2, with: [realSlot2])

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
                    dateSectionsResult: .success(sections), // counts 2 + 1 = 3
                    mediaWindowResult: .success([
                        NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
                    ]),
                    recorder: recorder))
            await sut.loadPhotos() // eagerly hydrates the first window
            await recorder.reset() // ignore the eager fetch; the empty pageAfterCalls below proves
                                   // the isolated run teleported by offset, not by a cursor page

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
                    dateSectionsResult: .success(sections), // counts 2 + 1 = 3
                    mediaWindowResult: .success(reals),
                    recorder: recorder))
            await sut.loadPhotos()

            await sut.hydrateVisibleWindow(0..<3) // one isolated run spanning both sections

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos.map(\.handle) == [10, 11, 12]) // spliced across the boundary
            #expect(await recorder.windowCalls == [.init(section: sections[0], offset: 0, limit: 3)])
        }

        @Test("A shape-neutral reload preserves hydrated nodes instead of flashing back to placeholders")
        func reloadWithUnchangedShapePreservesHydration() async {
            let reals = [
                NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
            ]
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    dateSectionsResult: .success(Self.makeSections()), // counts 2 + 1
                    mediaWindowResult: .success(reals)))
            await sut.loadPhotos()
            await sut.hydrateVisibleWindow(0..<2) // slots 0, 1 now real

            // A node-update-style reload fetches the same sections (same shape, same filter).
            await sut.loadPhotos()

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            #expect(photos[0].handle == 10) // hydrated content preserved, not wiped
            #expect(photos[1].handle == 11)
            #expect(photos[2].isTimelinePlaceholder)
        }

        @Test("Changing the filter rebuilds the skeleton, dropping hydration that no longer applies")
        func filterChangeRebuildsSkeletonDiscardingHydration() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    dateSectionsResult: .success(Self.makeSections()),
                    mediaWindowResult: .success([
                        NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
                    ])))
            await sut.loadPhotos()
            await sut.hydrateVisibleWindow(0..<2) // hydrate under the initial filter

            await sut.updatePhotoFilter(option: .images) // a different dataset
            await sut.loadPhotos()

            let photos = sut.photoLibraryContentViewModel.library.allPhotos
            let allArePlaceholders = photos.allSatisfy(\.isTimelinePlaceholder)
            #expect(allArePlaceholders) // stale hydration dropped; grid is a fresh skeleton
        }

        @Test("Changing sort order reloads (re-fetches sections) instead of locally re-sorting placeholders")
        func sortOrderChangeReloads() async throws {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    dateSectionsResult: .success(Self.makeSections())))
            let taskId = sut.loadPhotosTaskId

            sut.updateSortOrder(.modificationAsc)

            #expect(sut.loadPhotosTaskId != taskId)
            #expect(sut.sortPhotoLibraryTask == nil) // no local re-sort task spawned
        }

        @Test("A reactive shape change keeps hydrated nodes from an unaffected bucket in place")
        func reactiveShapeChangePreservesHydrationByIdentity() async {
            let sut = makeSUT(
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    dateSectionsResult: .success(Self.makeSections()), // day1: 2, day2: 1
                    mediaWindowResult: .success([
                        NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequence: Self.sectionStream(Self.sections(day1: 2, day2: 2))))
            await sut.loadPhotos()
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
                    dateSectionsResult: .success(Self.sections(day1: 1, day2: 1)), // 2 slots
                    monitorDateSectionsSequence: Self.sectionStream(Self.sections(day1: 2, day2: 1))))
            await sut.loadPhotos()
            // Pre-hydrate the day2 slot (index 1, local offset 0 within day2).
            sut.photoLibraryContentViewModel.library = sut.photoLibraryContentViewModel.library
                .replacingPhotos(from: 1, with: [NodeEntity(name: "d2.jpg", handle: 20, hasThumbnail: true)])

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
                    dateSectionsResult: .success(Self.sections(day1: 2, day2: 0)), // single bucket, 2 slots
                    monitorDateSectionsSequence: Self.sectionStream(Self.sections(day1: 1, day2: 0))))
            await sut.loadPhotos()
            sut.photoLibraryContentViewModel.library = sut.photoLibraryContentViewModel.library
                .replacingPhotos(from: 0, with: [
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
                    dateSectionsResult: .success(Self.sections(day1: 2, day2: 1)),
                    // day1 dropped to placeholders → re-hydrated by paging backward from the day2 anchor.
                    mediaPageResult: .success([NodeEntity(name: "spill.jpg", handle: 12, hasThumbnail: true)]),
                    mediaPageBeforeResult: .success([
                        NodeEntity(name: "n.jpg", handle: 99, hasThumbnail: true),  // the new upload
                        NodeEntity(name: "p0.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "p1.jpg", handle: 11, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequence: Self.sectionStream(Self.sections(day1: 3, day2: 1))))
            await sut.loadPhotos()
            // Fully hydrate the initial 3 slots: day1 [10, 11], day2 [12].
            sut.photoLibraryContentViewModel.library = sut.photoLibraryContentViewModel.library
                .replacingPhotos(from: 0, with: [
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
                    dateSectionsResult: .success(Self.sections(day1: 2, day2: 1)),
                    mediaPageBeforeResult: .success([
                        NodeEntity(name: "n.jpg", handle: 99, hasThumbnail: true),  // the new upload
                        NodeEntity(name: "p0.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "p1.jpg", handle: 11, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequence: Self.sectionStream(Self.sections(day1: 3, day2: 1))))
            await sut.loadPhotos()
            sut.photoLibraryContentViewModel.library = sut.photoLibraryContentViewModel.library
                .replacingPhotos(from: 0, with: [
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
                    dateSectionsResult: .success(Self.makeSections()),
                    mediaWindowResult: .success([
                        NodeEntity(name: "a.jpg", handle: 10, hasThumbnail: true),
                        NodeEntity(name: "b.jpg", handle: 11, hasThumbnail: true)
                    ]),
                    monitorDateSectionsSequence: Self.sectionStream(Self.makeSections()))) // identical shape
            await sut.loadPhotos()
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
                    dateSectionsResult: .success(Self.makeSections()),
                    monitorDateSectionsSequence: Self.sectionStream([])))
            await sut.loadPhotos()
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
                    dateSectionsResult: .success(Self.sections(day1: 2, day2: 1))))
            await sut.loadPhotos()
            sut.photoLibraryContentViewModel.library = sut.photoLibraryContentViewModel.library
                .replacingPhotos(from: 0, with: [NodeEntity(name: "n.jpg", handle: 10, hasThumbnail: false)])

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
                    dateSectionsResult: .success(Self.sections(day1: 2, day2: 1))))
            await sut.loadPhotos()
            let hydrated = NodeEntity(name: "n.jpg", handle: 10, hasThumbnail: false)
            sut.photoLibraryContentViewModel.library = sut.photoLibraryContentViewModel.library
                .replacingPhotos(from: 0, with: [hydrated])

            await sut.monitorNodeMetadataUpdates()

            #expect(sut.photoLibraryContentViewModel.library.allPhotos[0].hasThumbnail == false) // unchanged
        }

        @Test("A sensitivity-only node update is NOT patched in place (left to the authoritative shape reconcile)")
        func nodeMetadataUpdateForSensitivityOnlyChangeIsNotPatched() async {
            // isMarkedSensitive under exclude-sensitive is a membership change: the section monitor
            // must reproject the node out, not this patch (which would briefly keep a should-be-
            // hidden node on screen). So a sensitivity-only update must leave the library untouched.
            let sut = makeSUT(
                nodeUseCase: MockNodeUseCase(
                    nodeUpdates: SingleItemAsyncSequence(
                        item: [NodeEntity(name: "n.jpg", handle: 10, hasThumbnail: true, isMarkedSensitive: true)])
                        .eraseToAnyAsyncSequence()),
                mediaTimelineUseCase: MockMediaTimelineUseCase(
                    dateSectionsResult: .success(Self.sections(day1: 2, day2: 1))))
            await sut.loadPhotos()
            sut.photoLibraryContentViewModel.library = sut.photoLibraryContentViewModel.library
                .replacingPhotos(from: 0, with: [
                    NodeEntity(name: "n.jpg", handle: 10, hasThumbnail: true, isMarkedSensitive: false)])

            await sut.monitorNodeMetadataUpdates()

            // Same render fields (hasThumbnail true both sides) → no patch; sensitivity flip ignored here.
            #expect(sut.photoLibraryContentViewModel.library.allPhotos[0].isMarkedSensitive == false)
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
        mediaTimelineUseCase: (any MediaTimelineUseCaseProtocol)? = nil,
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
            mediaTimelineUseCase: mediaTimelineUseCase,
            tracker: tracker
        )
    }
}
