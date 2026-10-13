import FileProvider
import MEGAPickerFileProviderDomain
import Testing

struct FileProviderWorkingSetItemsUseCaseTests {
    private let folderA = NSFileProviderItemIdentifier("a")
    private let folderB = NSFileProviderItemIdentifier("b")

    @Test
    func items_withoutSnapshots_isEmpty() async throws {
        let sut = makeSUT()

        let page = try await sut.items(startingAt: initialPage, pageSize: 2)

        #expect(page == FileProviderWorkingSetPageEntity(items: [], nextPage: nil))
    }

    @Test
    func items_walksEveryEnumeratedContainerPageByPage() async throws {
        let childrenOfA = [FileProviderItemEntity.make("a1", in: folderA), .make("a2", in: folderA), .make("a3", in: folderA)]
        let childrenOfB = [FileProviderItemEntity.make("b1", in: folderB)]
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(childrenByContainer: [folderA: childrenOfA, folderB: childrenOfB]),
            snapshotRepo: MockFileProviderSnapshotRepository(snapshots: [folderB: snapshot(of: []), folderA: snapshot(of: [])])
        )

        let items = try await allItems(of: sut, pageSize: 2)

        #expect(items == childrenOfA + childrenOfB)
    }

    @Test
    func items_recordsTheDeliveredChildrenAndKeepsTheOthers() async throws {
        let children = [FileProviderItemEntity.make("a1", in: folderA), .make("a2", in: folderA), .make("a3", in: folderA)]
        let gone = FileProviderItemEntity.make("gone", in: folderA)
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [folderA: snapshot(of: [gone])])
        let sut = makeSUT(itemUseCase: MockFileProviderItemUseCase(childrenByContainer: [folderA: children]), snapshotRepo: snapshotRepo)

        _ = try await allItems(of: sut, pageSize: 2)

        #expect(snapshotRepo.snapshots == [folderA: snapshot(of: children + [gone])])
    }

    @Test
    func items_skipsAndForgetsAFolderThatIsGone() async throws {
        let childrenOfB = [FileProviderItemEntity.make("b1", in: folderB)]
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [folderA: snapshot(of: []), folderB: snapshot(of: childrenOfB)])
        let sut = makeSUT(itemUseCase: MockFileProviderItemUseCase(childrenByContainer: [folderB: childrenOfB]), snapshotRepo: snapshotRepo)

        let items = try await allItems(of: sut, pageSize: 2)

        #expect(items == childrenOfB)
        #expect(snapshotRepo.snapshots[folderA] == nil)
    }

    @Test
    func items_whenTheNodeTreeIsNotLoaded_throwsAndKeepsTheSnapshots() async throws {
        let snapshots = [folderA: snapshot(of: [.make("a1", in: folderA)])]
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: snapshots)
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItemError: NSFileProviderError(.cannotSynchronize)),
            snapshotRepo: snapshotRepo
        )

        await #expect(throws: NSFileProviderError(.cannotSynchronize)) {
            try await sut.items(startingAt: initialPage, pageSize: 2)
        }
        #expect(snapshotRepo.snapshots == snapshots)
    }

    @Test
    func items_whenTheRootIsMissing_throws() async throws {
        let sut = makeSUT(snapshotRepo: MockFileProviderSnapshotRepository(snapshots: [.rootContainer: snapshot(of: [])]))

        await #expect(throws: NSFileProviderError(.noSuchItem)) {
            try await sut.items(startingAt: initialPage, pageSize: 2)
        }
    }

    @Test
    func items_fromAPageOfAContainerWhoseSnapshotWasRemoved_continuesWithTheNextContainer() async throws {
        let childrenOfB = [FileProviderItemEntity.make("b1", in: folderB)]
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [folderA: snapshot(of: [])])
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(childrenByContainer: [
                folderA: [.make("a1", in: folderA), .make("a2", in: folderA)],
                folderB: childrenOfB
            ]),
            snapshotRepo: snapshotRepo
        )
        let firstPage = try await sut.items(startingAt: initialPage, pageSize: 1)
        try snapshotRepo.removeSnapshot(of: folderA)
        try snapshotRepo.updateSnapshot(of: folderB) { $0 = FileProviderSnapshotEntity() }

        let nextPage = try await sut.items(startingAt: try #require(firstPage.nextPage), pageSize: 1)

        #expect(nextPage.items == childrenOfB)
    }

    // MARK: - Helpers

    private var initialPage: NSFileProviderPage {
        NSFileProviderPage(NSFileProviderPage.initialPageSortedByName as Data)
    }

    private func allItems(of sut: some FileProviderWorkingSetItemsUseCaseProtocol, pageSize: Int) async throws -> [FileProviderItemEntity] {
        var items: [FileProviderItemEntity] = []
        var page: NSFileProviderPage? = initialPage
        while let current = page {
            let result = try await sut.items(startingAt: current, pageSize: pageSize)
            items += result.items
            page = result.nextPage
        }
        return items
    }

    private func snapshot(of items: [FileProviderItemEntity]) -> FileProviderSnapshotEntity {
        FileProviderEnumerationSnapshotUseCaseTests.snapshot(of: items)
    }

    private func makeSUT(
        itemUseCase: MockFileProviderItemUseCase = MockFileProviderItemUseCase(),
        snapshotRepo: MockFileProviderSnapshotRepository = MockFileProviderSnapshotRepository()
    ) -> some FileProviderWorkingSetItemsUseCaseProtocol {
        FileProviderWorkingSetItemsUseCase(
            itemUseCase: itemUseCase,
            snapshotRepo: snapshotRepo,
            enumerationSnapshotUseCase: FileProviderEnumerationSnapshotUseCase(snapshotRepo: snapshotRepo)
        )
    }
}
