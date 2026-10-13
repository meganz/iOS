import FileProvider
import MEGAPickerFileProviderDomain
import Testing

struct FileProviderChangesUseCaseTests {
    private let folder = NSFileProviderItemIdentifier("folder")
    private let otherFolder = NSFileProviderItemIdentifier("other")

    @Test
    func currentAnchor_isTheQueuesCurrentAnchor() async throws {
        let sut = makeSUT(changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [change("a", in: folder)]))

        let anchor = try await sut.currentAnchor()

        #expect(anchor.changeAnchor == MockFileProviderChangeQueueRepository.anchor(at: 1))
    }

    @Test
    func changes_fromAnAnchorThisExtensionDidNotHandOut_throwsSyncAnchorExpired() async throws {
        let sut = makeSUT()

        await #expect(throws: NSFileProviderError(.syncAnchorExpired)) {
            try await sut.changes(from: NSFileProviderSyncAnchor(Data("0".utf8)), limit: 10)
        }
    }

    @Test
    func changes_whenTheQueueNoLongerHasThem_throwsSyncAnchorExpired() async throws {
        let sut = makeSUT(changeQueueRepo: MockFileProviderChangeQueueRepository(isExpired: true))

        await #expect(throws: NSFileProviderError(.syncAnchorExpired)) {
            try await sut.changes(from: try anchor(at: 0), limit: 10)
        }
    }

    @Test
    func changes_reportsPresentableItemsAsUpdatedWithTheirFolder() async throws {
        let item = FileProviderItemEntity.make("a", in: folder)
        let folderItem = FileProviderItemEntity.make("folder", isFolder: true)
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItems: [item, folderItem]),
            changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [change("a", in: folder)])
        )

        let changeSet = try await sut.changes(from: try anchor(at: 0), limit: 10)

        #expect(changeSet.updatedItems == [folderItem, item])
        #expect(changeSet.deletedIdentifiers.isEmpty)
        #expect(changeSet.anchor.changeAnchor == MockFileProviderChangeQueueRepository.anchor(at: 1))
        #expect(changeSet.moreComing == false)
    }

    @Test
    func changes_reportsEachItemOnce() async throws {
        let item = FileProviderItemEntity.make("a", in: folder)
        let folderItem = FileProviderItemEntity.make("folder", isFolder: true)
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItems: [item, folderItem]),
            changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [change("a", in: folder), change("a", in: folder)])
        )

        let changeSet = try await sut.changes(from: try anchor(at: 0), limit: 10)

        #expect(changeSet.updatedItems == [folderItem, item])
    }

    @Test
    func changes_reportsItemsThatAreNotPresentableAsDeleted() async throws {
        let folderItem = FileProviderItemEntity.make("folder", isFolder: true)
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItems: [folderItem]),
            changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [change("gone", in: folder)])
        )

        let changeSet = try await sut.changes(from: try anchor(at: 0), limit: 10)

        #expect(changeSet.updatedItems == [folderItem])
        #expect(changeSet.deletedIdentifiers == [NSFileProviderItemIdentifier("gone")])
    }

    @Test
    func changes_reportsAMovedItemsNewParentToo() async throws {
        let moved = FileProviderItemEntity.make("a", in: otherFolder)
        let folderItem = FileProviderItemEntity.make("folder", isFolder: true)
        let otherFolderItem = FileProviderItemEntity.make("other", isFolder: true)
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItems: [moved, folderItem, otherFolderItem]),
            changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [change("a", in: folder)])
        )

        let changeSet = try await sut.changes(from: try anchor(at: 0), limit: 10)

        #expect(Set(changeSet.updatedItems.map(\.identifier)) == [moved.identifier, folder, otherFolder])
    }

    @Test
    func changes_reportsParentsBeforeTheirChildren() async throws {
        let child = FileProviderItemEntity.make("child", in: NSFileProviderItemIdentifier("parent"))
        let parent = FileProviderItemEntity.make("parent", in: folder, isFolder: true)
        let folderItem = FileProviderItemEntity.make("folder", isFolder: true)
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItems: [child, parent, folderItem]),
            changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [
                change("child", in: NSFileProviderItemIdentifier("parent")),
                change("parent", in: folder)
            ])
        )

        let changeSet = try await sut.changes(from: try anchor(at: 0), limit: 10)

        #expect(changeSet.updatedItems.map(\.identifier.rawValue) == ["folder", "parent", "child"])
    }

    @Test
    func changes_readsAtMostTheLimitAndSaysMoreAreComing() async throws {
        let first = FileProviderItemEntity.make("a", in: folder)
        let folderItem = FileProviderItemEntity.make("folder", isFolder: true)
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItems: [first, folderItem]),
            changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [change("a", in: folder), change("b", in: folder)])
        )

        let changeSet = try await sut.changes(from: try anchor(at: 0), limit: 1)

        #expect(changeSet.updatedItems == [folderItem, first])
        #expect(changeSet.anchor.changeAnchor == MockFileProviderChangeQueueRepository.anchor(at: 1))
        #expect(changeSet.moreComing)
    }

    @Test
    func changes_updatesTheSnapshots() async throws {
        let updated = FileProviderItemEntity.make("updated", in: folder, name: "new")
        let moved = FileProviderItemEntity.make("moved", in: otherFolder)
        let kept = FileProviderItemEntity.make("kept", in: folder)
        let folderItem = FileProviderItemEntity.make("folder", isFolder: true)
        let otherFolderItem = FileProviderItemEntity.make("other", isFolder: true)
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [
            .rootContainer: snapshot(of: [.make("folder", name: "stale", isFolder: true), .make("other", name: "stale", isFolder: true)]),
            folder: snapshot(of: [.make("updated", in: folder, name: "old"), .make("moved", in: folder), .make("gone", in: folder), kept]),
            otherFolder: snapshot(of: []),
            NSFileProviderItemIdentifier("gone"): snapshot(of: [.make("inside")])
        ])
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItems: [updated, moved, kept, folderItem, otherFolderItem]),
            snapshotRepo: snapshotRepo,
            changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [
                change("updated", in: folder),
                change("moved", in: folder),
                change("gone", in: folder)
            ])
        )

        _ = try await sut.changes(from: try anchor(at: 0), limit: 10)

        #expect(snapshotRepo.snapshots == [
            .rootContainer: snapshot(of: [folderItem, otherFolderItem]),
            folder: snapshot(of: [updated, kept]),
            otherFolder: snapshot(of: [moved])
        ])
    }

    @Test
    func changes_inTheRootAndTheTrash_recordsOnlyTheirChildren() async throws {
        let file = FileProviderItemEntity.make("a")
        let trashedFile = FileProviderItemEntity.make("t", in: .trashContainer)
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [.rootContainer: snapshot(of: []), .trashContainer: snapshot(of: [])])
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItems: [
                file,
                trashedFile,
                .make(NSFileProviderItemIdentifier.rootContainer.rawValue, isFolder: true),
                .make(NSFileProviderItemIdentifier.trashContainer.rawValue, isFolder: true)
            ]),
            snapshotRepo: snapshotRepo,
            changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [change("a", in: .rootContainer), change("t", in: .trashContainer)])
        )

        _ = try await sut.changes(from: try anchor(at: 0), limit: 10)

        #expect(snapshotRepo.snapshots == [.rootContainer: snapshot(of: [file]), .trashContainer: snapshot(of: [trashedFile])])
    }

    @Test
    func changes_doesNotCreateSnapshotsForContainersWithoutOne() async throws {
        let item = FileProviderItemEntity.make("a", in: folder)
        let snapshotRepo = MockFileProviderSnapshotRepository()
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItems: [item, .make("folder", isFolder: true)]),
            snapshotRepo: snapshotRepo,
            changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [change("a", in: folder)])
        )

        _ = try await sut.changes(from: try anchor(at: 0), limit: 10)

        #expect(snapshotRepo.snapshots.isEmpty)
    }

    @Test
    func changes_whenAnItemCannotBeRead_throwsAndLeavesTheSnapshotsAlone() async throws {
        let snapshots = [folder: snapshot(of: [.make("a", in: folder, name: "old")])]
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: snapshots)
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItemError: NSFileProviderError(.cannotSynchronize)),
            snapshotRepo: snapshotRepo,
            changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [change("a", in: folder)])
        )

        await #expect(throws: NSFileProviderError(.cannotSynchronize)) {
            try await sut.changes(from: try anchor(at: 0), limit: 10)
        }
        #expect(snapshotRepo.snapshots == snapshots)
    }

    @Test
    func changes_whenTheSnapshotsCannotBeUpdated_throws() async throws {
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(presentableItems: [.make("a", in: folder), .make("folder", isFolder: true)]),
            snapshotRepo: MockFileProviderSnapshotRepository(error: NSFileProviderError(.serverUnreachable)),
            changeQueueRepo: MockFileProviderChangeQueueRepository(changes: [change("a", in: folder)])
        )

        await #expect(throws: NSFileProviderError(.serverUnreachable)) {
            try await sut.changes(from: try anchor(at: 0), limit: 10)
        }
    }

    // MARK: - Helpers

    private func change(_ identifier: String, in folderIdentifier: NSFileProviderItemIdentifier) -> FileProviderChangeEntity {
        FileProviderChangeEntity(identifier: NSFileProviderItemIdentifier(identifier), folderIdentifier: folderIdentifier)
    }

    private func anchor(at offset: Int) throws -> NSFileProviderSyncAnchor {
        try NSFileProviderSyncAnchor(MockFileProviderChangeQueueRepository.anchor(at: offset))
    }

    private func snapshot(of items: [FileProviderItemEntity]) -> FileProviderSnapshotEntity {
        FileProviderEnumerationSnapshotUseCaseTests.snapshot(of: items)
    }

    private func makeSUT(
        itemUseCase: MockFileProviderItemUseCase = MockFileProviderItemUseCase(),
        snapshotRepo: MockFileProviderSnapshotRepository = MockFileProviderSnapshotRepository(),
        changeQueueRepo: MockFileProviderChangeQueueRepository = MockFileProviderChangeQueueRepository()
    ) -> some FileProviderChangesUseCaseProtocol {
        FileProviderChangesUseCase(itemUseCase: itemUseCase, snapshotRepo: snapshotRepo, changeQueueRepo: changeQueueRepo)
    }
}
