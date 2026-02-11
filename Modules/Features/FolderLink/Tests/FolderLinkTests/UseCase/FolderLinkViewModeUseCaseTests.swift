import FolderLink
import MEGADomain
import Testing

struct FolderLinkViewModeUseCaseTests {
    @Suite("viewModeForOpeningFolder Tests")
    struct ViewModeForOpeningFolderTests {
        @Test("returns .list when there are no children")
        func viewMode_noChildren_returnsList() {
            let handle: HandleEntity = 1
            let repo = MockFolderLinkRepository(childrenByHandle: [handle: []])
            let sut = FolderLinkViewModeUseCase(folderLinkRepository: repo)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .list)
        }

        @Test("returns .list when counts are equal")
        func viewMode_equalCounts_returnsList() {
            let handle: HandleEntity = 2
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 101, hasThumbnail: true),
                NodeEntity(handle: 102, hasThumbnail: false)
            ]
            let repo = MockFolderLinkRepository(childrenByHandle: [handle: nodes])
            let sut = FolderLinkViewModeUseCase(folderLinkRepository: repo)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .list)
        }

        @Test("returns .grid when thumbnails are majority")
        func viewMode_thumbnailsMajority_returnsGrid() {
            let handle: HandleEntity = 3
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 201, hasThumbnail: true),
                NodeEntity(handle: 202, hasThumbnail: true),
                NodeEntity(handle: 203, hasThumbnail: false)
            ]
            let repo = MockFolderLinkRepository(childrenByHandle: [handle: nodes])
            let sut = FolderLinkViewModeUseCase(folderLinkRepository: repo)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .grid)
        }

        @Test("returns .list when non-thumbnails are majority")
        func viewMode_nonThumbnailsMajority_returnsList() {
            let handle: HandleEntity = 4
            let nodes: [NodeEntity] = [
                NodeEntity(handle: 301, hasThumbnail: true),
                NodeEntity(handle: 302, hasThumbnail: false),
                NodeEntity(handle: 303, hasThumbnail: false),
                NodeEntity(handle: 304, hasThumbnail: false)
            ]
            let repo = MockFolderLinkRepository(childrenByHandle: [handle: nodes])
            let sut = FolderLinkViewModeUseCase(folderLinkRepository: repo)

            let mode = sut.viewModeForOpeningFolder(handle)
            #expect(mode == .list)
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

