import FileProvider
import MEGADomain
import MEGADomainMock
import MEGAPickerFileProviderDomain
import MEGASwift
import Testing

struct FileProviderNodeUpdatesUseCaseTests {
    private let rootNode = NodeEntity(handle: 1, base64Handle: "root", isFolder: true)
    private let rubbishNode = NodeEntity(handle: 2, base64Handle: "rubbish", isFolder: true)
    /// Has a snapshot.
    private let shownFolder = NodeEntity(handle: 3, base64Handle: "shown", isFolder: true)
    /// Has no snapshot.
    private let unseenFolder = NodeEntity(handle: 4, base64Handle: "unseen", isFolder: true)
    private let newerVersion = NodeEntity(handle: 5, base64Handle: "newer", isFile: true)

    @Test(arguments: [ChangeTypeEntity.new, .name, .attributes, .fileAttributes, .timestamp, .sensitive, .removed])
    func queueNodeUpdates_inAFolderWithSnapshot_queuesTheNodeWithItsParentAndSignals(changeTypes: ChangeTypeEntity) async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let signalRepo = MockFileProviderWorkingSetSignalRepository()
        let sut = makeSUT(updates: [[node("a", changeTypes, in: shownFolder)]], changeQueueRepo: changeQueueRepo, signalRepo: signalRepo)

        try await sut.queueNodeUpdates()

        #expect(await changeQueueRepo.changes == [change("a", in: "shown")])
        #expect(await signalRepo.signalCount == 1)
    }

    @Test(arguments: [ChangeTypeEntity.new, .name, .attributes, .fileAttributes, .timestamp, .sensitive, .removed])
    func queueNodeUpdates_inAFolderWithoutSnapshot_queuesNothing(changeTypes: ChangeTypeEntity) async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let signalRepo = MockFileProviderWorkingSetSignalRepository()
        let sut = makeSUT(updates: [[node("a", changeTypes, in: unseenFolder)]], changeQueueRepo: changeQueueRepo, signalRepo: signalRepo)

        try await sut.queueNodeUpdates()

        #expect(await changeQueueRepo.changes.isEmpty)
        #expect(await signalRepo.signalCount == 0)
    }

    @Test(arguments: [ChangeTypeEntity.parent, [.parent, .name]])
    func queueNodeUpdates_movedIntoAFolderWithoutSnapshot_queuesTheNode(changeTypes: ChangeTypeEntity) async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let signalRepo = MockFileProviderWorkingSetSignalRepository()
        let sut = makeSUT(updates: [[node("a", changeTypes, in: unseenFolder)]], changeQueueRepo: changeQueueRepo, signalRepo: signalRepo)

        try await sut.queueNodeUpdates()

        #expect(await changeQueueRepo.changes == [change("a", in: "unseen")])
        #expect(await signalRepo.signalCount == 1)
    }

    @Test
    func queueNodeUpdates_movedToTheRubbishBin_queuesTheNodeInTheTrashContainer() async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let sut = makeSUT(updates: [[node("a", .parent, in: rubbishNode)]], changeQueueRepo: changeQueueRepo)

        try await sut.queueNodeUpdates()

        #expect(await changeQueueRepo.changes == [change("a", in: .trashContainer)])
    }

    @Test(arguments: [ChangeTypeEntity.removed, .attributes, .name])
    func queueNodeUpdates_inTheRubbishBinWithoutSnapshot_queuesTheNodeInTheTrashContainer(changeTypes: ChangeTypeEntity) async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let signalRepo = MockFileProviderWorkingSetSignalRepository()
        let sut = makeSUT(updates: [[node("a", changeTypes, in: rubbishNode)]], changeQueueRepo: changeQueueRepo, signalRepo: signalRepo)

        try await sut.queueNodeUpdates()

        #expect(await changeQueueRepo.changes == [change("a", in: .trashContainer)])
        #expect(await signalRepo.signalCount == 1)
    }

    @Test
    func queueNodeUpdates_inTheRootWithSnapshot_queuesTheNodeInTheRootContainer() async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let sut = makeSUT(
            updates: [[node("a", .new, in: rootNode)]],
            snapshotContainers: [.rootContainer],
            changeQueueRepo: changeQueueRepo
        )

        try await sut.queueNodeUpdates()

        #expect(await changeQueueRepo.changes == [change("a", in: .rootContainer)])
    }

    @Test
    func queueNodeUpdates_earlierVersionOfAFile_queuesItUnderTheNewerVersion() async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let sut = makeSUT(
            updates: [[node("newer", .new, in: shownFolder), node("earlier", .parent, in: newerVersion)]],
            changeQueueRepo: changeQueueRepo
        )

        try await sut.queueNodeUpdates()

        #expect(await changeQueueRepo.changes == [change("newer", in: "shown"), change("earlier", in: "newer")])
    }

    @Test
    func queueNodeUpdates_whoseParentIsGone_queuesNothing() async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let signalRepo = MockFileProviderWorkingSetSignalRepository()
        let goneFolder = NodeEntity(handle: 99, base64Handle: "gone", isFolder: true)
        let sut = makeSUT(updates: [[node("a", .parent, in: goneFolder)]], changeQueueRepo: changeQueueRepo, signalRepo: signalRepo)

        try await sut.queueNodeUpdates()

        #expect(await changeQueueRepo.changes.isEmpty)
        #expect(await signalRepo.signalCount == 0)
    }

    @Test
    func queueNodeUpdates_queuesOnlyTheNodesThatPassInABatch() async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let sut = makeSUT(
            updates: [[node("a", .new, in: unseenFolder), node("b", .name, in: shownFolder)]],
            changeQueueRepo: changeQueueRepo
        )

        try await sut.queueNodeUpdates()

        #expect(await changeQueueRepo.changes == [change("b", in: "shown")])
    }

    @Test
    func queueNodeUpdates_batchesWithinTheSignalDelay_signalOnce() async throws {
        let changeQueueRepo = MockFileProviderChangeQueueRepository()
        let signalRepo = MockFileProviderWorkingSetSignalRepository()
        let sut = makeSUT(
            updates: [[node("a", .new, in: shownFolder)], [node("b", .new, in: unseenFolder)], [node("c", .name, in: shownFolder)]],
            changeQueueRepo: changeQueueRepo,
            signalRepo: signalRepo
        )

        try await sut.queueNodeUpdates()

        #expect(await changeQueueRepo.changes == [change("a", in: "shown"), change("c", in: "shown")])
        #expect(await signalRepo.signalCount == 1)
    }

    // MARK: - Helpers

    private func node(_ base64Handle: String, _ changeTypes: ChangeTypeEntity, in parent: NodeEntity) -> NodeEntity {
        NodeEntity(changeTypes: changeTypes, base64Handle: base64Handle, parentHandle: parent.handle, isFile: true)
    }

    private func change(_ identifier: String, in folderIdentifier: String) -> FileProviderChangeEntity {
        change(identifier, in: NSFileProviderItemIdentifier(folderIdentifier))
    }

    private func change(_ identifier: String, in folderIdentifier: NSFileProviderItemIdentifier) -> FileProviderChangeEntity {
        FileProviderChangeEntity(identifier: NSFileProviderItemIdentifier(identifier), folderIdentifier: folderIdentifier)
    }

    /// The updates arrive at once and then end, which emits the pending signal right away; the long delay makes sure
    /// that no pause in between could signal on its own.
    private func makeSUT(
        updates: [[NodeEntity]],
        snapshotContainers: [NSFileProviderItemIdentifier] = [NSFileProviderItemIdentifier("shown")],
        changeQueueRepo: MockFileProviderChangeQueueRepository = MockFileProviderChangeQueueRepository(),
        signalRepo: MockFileProviderWorkingSetSignalRepository = MockFileProviderWorkingSetSignalRepository()
    ) -> some FileProviderNodeUpdatesUseCaseProtocol {
        let (nodeUpdates, continuation) = AsyncStream.makeStream(of: [NodeEntity].self)
        updates.forEach { continuation.yield($0) }
        continuation.finish()
        let nodes = [rootNode, rubbishNode, shownFolder, unseenFolder, newerVersion]
        return FileProviderNodeUpdatesUseCase(
            nodeRepo: MockNodeRepository(
                nodesForHandle: Dictionary(uniqueKeysWithValues: nodes.map { ($0.handle, $0) }),
                rubbishBinNode: rubbishNode,
                nodeRoot: rootNode,
                nodeUpdates: nodeUpdates.eraseToAnyAsyncSequence()
            ),
            snapshotRepo: MockFileProviderSnapshotRepository(
                snapshots: Dictionary(uniqueKeysWithValues: snapshotContainers.map { ($0, FileProviderSnapshotEntity()) })
            ),
            changeQueueRepo: changeQueueRepo,
            workingSetSignalRepo: signalRepo,
            signalDelay: .seconds(60)
        )
    }
}
