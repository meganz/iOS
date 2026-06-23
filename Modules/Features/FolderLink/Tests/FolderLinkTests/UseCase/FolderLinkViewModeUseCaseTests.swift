import FolderLink
import MEGADomain
import MEGAPreferenceMocks
import Testing

private func makeSUT(
    children: [NodeEntity],
    mediaDiscoveryEnabled: Bool = false,
    globalPreference: ViewModePreferenceEntity = .perFolder
) -> (sut: FolderLinkViewModeUseCase, handle: HandleEntity) {
    let handle: HandleEntity = 1
    let repo = MockFolderLinkRepository(childrenByHandle: [handle: children])
    let preferenceUseCase = MockPreferenceUseCase(dict: [
        PreferenceKeyEntity.shouldDisplayMediaDiscoveryWhenMediaOnly.rawValue: mediaDiscoveryEnabled,
        PreferenceKeyEntity.viewModePreference.rawValue: globalPreference.rawValue
    ])
    let sut = FolderLinkViewModeUseCase(folderLinkRepository: repo, preferenceUseCase: preferenceUseCase)
    return (sut, handle)
}

struct FolderLinkViewModeUseCaseTests {
    @Suite("viewModeForOpeningFolder Tests")
    struct ViewModeForOpeningFolderTests {
        @Test("returns .list when there are no children")
        func viewMode_noChildren_returnsList() {
            let (sut, handle) = makeSUT(children: [])

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .list)
        }

        @Test("returns .list when counts are equal")
        func viewMode_equalCounts_returnsList() {
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 101, hasThumbnail: true),
                NodeEntity(handle: 102, hasThumbnail: false)
            ]
            let (sut, handle) = makeSUT(children: nodes)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .list)
        }

        @Test("returns .grid when thumbnails are majority")
        func viewMode_thumbnailsMajority_returnsGrid() {
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 201, hasThumbnail: true),
                NodeEntity(handle: 202, hasThumbnail: true),
                NodeEntity(handle: 203, hasThumbnail: false)
            ]
            let (sut, handle) = makeSUT(children: nodes)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .grid)
        }

        @Test("returns .list when non-thumbnails are majority")
        func viewMode_nonThumbnailsMajority_returnsList() {
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 301, hasThumbnail: true),
                NodeEntity(handle: 302, hasThumbnail: false),
                NodeEntity(handle: 303, hasThumbnail: false),
                NodeEntity(handle: 304, hasThumbnail: false)
            ]
            let (sut, handle) = makeSUT(children: nodes)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .list)
        }

        @Test("returns .mediaDiscovery when auto-MD on and all children are media")
        func viewMode_autoMDOn_allMedia_returnsMediaDiscovery() {
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 401, hasThumbnail: true, mediaType: .image),
                NodeEntity(handle: 402, hasThumbnail: true, mediaType: .video)
            ]
            let (sut, handle) = makeSUT(children: nodes, mediaDiscoveryEnabled: true)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .mediaDiscovery)
        }

        @Test("does not return .mediaDiscovery when auto-MD on but content is mixed")
        func viewMode_autoMDOn_mixedContent_doesNotReturnMediaDiscovery() {
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 411, hasThumbnail: true, mediaType: .image),
                NodeEntity(handle: 412, mediaType: nil)
            ]
            let (sut, handle) = makeSUT(children: nodes, mediaDiscoveryEnabled: true)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode != .mediaDiscovery)
        }

        @Test("does not return .mediaDiscovery when auto-MD on but folder is empty")
        func viewMode_autoMDOn_emptyFolder_doesNotReturnMediaDiscovery() {
            let (sut, handle) = makeSUT(children: [], mediaDiscoveryEnabled: true)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode != .mediaDiscovery)
        }

        @Test("does not return .mediaDiscovery when auto-MD off even if all children are media")
        func viewMode_autoMDOff_allMedia_doesNotReturnMediaDiscovery() {
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 421, hasThumbnail: true, mediaType: .image),
                NodeEntity(handle: 422, hasThumbnail: true, mediaType: .video)
            ]
            let (sut, handle) = makeSUT(children: nodes, mediaDiscoveryEnabled: false)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode != .mediaDiscovery)
        }

        private static let thumbnailMajorityNodes: [NodeEntity] = [
            NodeEntity(handle: 501, hasThumbnail: true),
            NodeEntity(handle: 502, hasThumbnail: true),
            NodeEntity(handle: 503, hasThumbnail: false)
        ]

        @Test("returns .list when saved global preference is .list")
        func viewMode_globalPreferenceList_returnsList() {
            let (sut, handle) = makeSUT(children: Self.thumbnailMajorityNodes, globalPreference: .list)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .list)
        }

        @Test("returns .grid when saved global preference is .thumbnail")
        func viewMode_globalPreferenceThumbnail_returnsGrid() {
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 511, hasThumbnail: false),
                NodeEntity(handle: 512, hasThumbnail: false)
            ]
            let (sut, handle) = makeSUT(children: nodes, globalPreference: .thumbnail)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .grid)
        }

        @Test("falls back to thumbnail-ratio heuristic when saved global preference is .perFolder")
        func viewMode_globalPreferencePerFolder_usesHeuristic() {
            let (sut, handle) = makeSUT(children: Self.thumbnailMajorityNodes, globalPreference: .perFolder)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .grid)
        }

        @Test("auto Media Discovery wins over a saved .list preference for a media-only folder")
        func viewMode_autoMDOn_mediaOnly_beatsListPreference() {
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 601, hasThumbnail: true, mediaType: .image),
                NodeEntity(handle: 602, hasThumbnail: true, mediaType: .video)
            ]
            let (sut, handle) = makeSUT(children: nodes, mediaDiscoveryEnabled: true, globalPreference: .list)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .mediaDiscovery)
        }
    }

    @Suite("shouldEnableMediaDiscoveryMode Tests")
    struct ShouldEnableMediaDiscoveryModeTests {
        @Test("returns false when there are no children")
        func mediaDiscovery_noChildren_false() {
            let handle: HandleEntity = 5
            let repo = MockFolderLinkRepository(childrenByHandle: [handle: []])
            let sut = FolderLinkViewModeUseCase(folderLinkRepository: repo)

            let enabled = sut.shouldEnableMediaDiscoveryMode(for: handle)
            #expect(enabled == false)
        }

        @Test("returns false when having no children that are media")
        func mediaDiscovery_allNil_false() {
            let handle: HandleEntity = 6
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 401, mediaType: nil),
                NodeEntity(handle: 402, mediaType: nil)
            ]
            let repo = MockFolderLinkRepository(childrenByHandle: [handle: nodes])
            let sut = FolderLinkViewModeUseCase(folderLinkRepository: repo)

            let enabled = sut.shouldEnableMediaDiscoveryMode(for: handle)
            #expect(enabled == false)
        }

        @Test("returns true when having at least one child that is media")
        func mediaDiscovery_anyNonNil_true() {
            let handle: HandleEntity = 7
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 501, mediaType: nil),
                NodeEntity(handle: 502, mediaType: .image)
            ]
            let repo = MockFolderLinkRepository(childrenByHandle: [handle: nodes])
            let sut = FolderLinkViewModeUseCase(folderLinkRepository: repo)

            let enabled = sut.shouldEnableMediaDiscoveryMode(for: handle)
            #expect(enabled == true)
        }
    }
}
