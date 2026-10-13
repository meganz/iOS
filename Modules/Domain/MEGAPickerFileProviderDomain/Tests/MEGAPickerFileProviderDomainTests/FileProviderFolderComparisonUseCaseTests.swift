import FileProvider
import MEGAPickerFileProviderDomain
import Testing

struct FileProviderFolderComparisonUseCaseTests {
    private let folder = NSFileProviderItemIdentifier("folder")

    @Test
    func compareChildren_ofAContainerWithoutSnapshot_queuesNothing() async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let signalRepo = MockFileProviderWorkingSetSignalRepository()
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(childrenByContainer: [folder: [.make("a", in: folder)]]),
            changeQueueRepo: changeQueueRepo,
            signalRepo: signalRepo
        )

        let found = try await sut.compareChildren(of: folder, reportsRemovals: true)

        #expect(found == false)
        #expect(await changeQueueRepo.changes.isEmpty)
        #expect(await signalRepo.signalCount == 0)
    }

    @Test
    func compareChildren_whenNothingChanged_queuesNothing() async throws {
        let children = [FileProviderItemEntity.make("a", in: folder), .make("b", in: folder)]
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let signalRepo = MockFileProviderWorkingSetSignalRepository()
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(childrenByContainer: [folder: children]),
            snapshotRepo: MockFileProviderSnapshotRepository(snapshots: [folder: snapshot(of: children)]),
            changeQueueRepo: changeQueueRepo,
            signalRepo: signalRepo
        )

        let found = try await sut.compareChildren(of: folder, reportsRemovals: true)

        #expect(found == false)
        #expect(await changeQueueRepo.changes.isEmpty)
        #expect(await signalRepo.signalCount == 0)
    }

    @Test
    func compareChildren_queuesAddedChangedAndRemovedChildrenAndSignals() async throws {
        let unchanged = FileProviderItemEntity.make("unchanged", in: folder)
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let signalRepo = MockFileProviderWorkingSetSignalRepository()
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(childrenByContainer: [
                folder: [unchanged, .make("renamed", in: folder, name: "new"), .make("added", in: folder)]
            ]),
            snapshotRepo: MockFileProviderSnapshotRepository(snapshots: [
                folder: snapshot(of: [unchanged, .make("renamed", in: folder, name: "old"), .make("removed", in: folder)])
            ]),
            changeQueueRepo: changeQueueRepo,
            signalRepo: signalRepo
        )

        let found = try await sut.compareChildren(of: folder, reportsRemovals: true)

        #expect(found)
        #expect(Set(await changeQueueRepo.changes) == Set(["renamed", "added", "removed"].map { change($0) }))
        #expect(await signalRepo.signalCount == 1)
    }

    @Test
    func compareChildren_withoutRemovals_leavesRemovedChildrenOut() async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(childrenByContainer: [folder: [.make("added", in: folder)]]),
            snapshotRepo: MockFileProviderSnapshotRepository(snapshots: [folder: snapshot(of: [.make("removed", in: folder)])]),
            changeQueueRepo: changeQueueRepo
        )

        try await sut.compareChildren(of: folder, reportsRemovals: false)

        #expect(await changeQueueRepo.changes == [change("added")])
    }

    @Test
    func compareChildren_withoutRemovals_whenOnlyChildrenWereRemoved_queuesNothing() async throws {
        let signalRepo = MockFileProviderWorkingSetSignalRepository()
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(childrenByContainer: [folder: []]),
            snapshotRepo: MockFileProviderSnapshotRepository(snapshots: [folder: snapshot(of: [.make("removed", in: folder)])]),
            signalRepo: signalRepo
        )

        let found = try await sut.compareChildren(of: folder, reportsRemovals: false)

        #expect(found == false)
        #expect(await signalRepo.signalCount == 0)
    }

    @Test
    func compareChildren_comparesEveryPage() async throws {
        let children = (0..<450).map { FileProviderItemEntity.make("child\($0)", in: folder) }
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let sut = makeSUT(
            itemUseCase: MockFileProviderItemUseCase(childrenByContainer: [folder: children]),
            snapshotRepo: MockFileProviderSnapshotRepository(snapshots: [folder: snapshot(of: Array(children.dropLast()))]),
            changeQueueRepo: changeQueueRepo
        )

        try await sut.compareChildren(of: folder, reportsRemovals: true)

        #expect(await changeQueueRepo.changes == [change("child449")])
    }

    @Test
    func compareChildren_ofAFolderThatIsGone_queuesTheFolder() async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let signalRepo = MockFileProviderWorkingSetSignalRepository()
        let sut = makeSUT(
            snapshotRepo: MockFileProviderSnapshotRepository(snapshots: [folder: snapshot(of: [.make("a", in: folder)])]),
            changeQueueRepo: changeQueueRepo,
            signalRepo: signalRepo
        )

        try await sut.compareChildren(of: folder, reportsRemovals: true)

        #expect(await changeQueueRepo.changes == [change("folder")])
        #expect(await signalRepo.signalCount == 1)
    }

    @Test
    func compareChildren_ofAFolderThatIsGone_withoutRemovals_throws() async throws {
        let sut = makeSUT(snapshotRepo: MockFileProviderSnapshotRepository(snapshots: [folder: snapshot(of: [])]))

        await #expect(throws: NSFileProviderError(.noSuchItem)) {
            try await sut.compareChildren(of: folder, reportsRemovals: false)
        }
    }

    @Test(arguments: [NSFileProviderItemIdentifier.rootContainer, .trashContainer])
    func compareChildren_ofAMissingContainer_throws(containerIdentifier: NSFileProviderItemIdentifier) async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let sut = makeSUT(
            snapshotRepo: MockFileProviderSnapshotRepository(snapshots: [containerIdentifier: snapshot(of: [])]),
            changeQueueRepo: changeQueueRepo
        )

        await #expect(throws: NSFileProviderError(.noSuchItem)) {
            try await sut.compareChildren(of: containerIdentifier, reportsRemovals: true)
        }
        #expect(await changeQueueRepo.changes.isEmpty)
    }

    // MARK: - Helpers

    private func change(_ identifier: String) -> FileProviderChangeEntity {
        FileProviderChangeEntity(identifier: NSFileProviderItemIdentifier(identifier), folderIdentifier: folder)
    }

    private func snapshot(of items: [FileProviderItemEntity]) -> FileProviderSnapshotEntity {
        FileProviderEnumerationSnapshotUseCaseTests.snapshot(of: items)
    }

    private func makeSUT(
        itemUseCase: MockFileProviderItemUseCase = MockFileProviderItemUseCase(),
        snapshotRepo: MockFileProviderSnapshotRepository = MockFileProviderSnapshotRepository(),
        changeQueueRepo: MockFileProviderChangeQueueRepository = MockFileProviderChangeQueueRepository(),
        signalRepo: MockFileProviderWorkingSetSignalRepository = MockFileProviderWorkingSetSignalRepository()
    ) -> some FileProviderFolderComparisonUseCaseProtocol {
        FileProviderFolderComparisonUseCase(
            itemUseCase: itemUseCase,
            snapshotRepo: snapshotRepo,
            changeQueueRepo: changeQueueRepo,
            workingSetSignalRepo: signalRepo
        )
    }
}
