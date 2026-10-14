import FileProvider
import MEGADomain
import MEGADomainMock
import MEGAPickerFileProviderDomain
import Testing

struct FileProviderItemActionUseCaseTests {
    private let folder = FileProviderItemEntity.make("folder", isFolder: true)
    private let otherFolder = FileProviderItemEntity.make("other", isFolder: true)

    // MARK: - createFolder

    @Test
    func createFolder_inAFolder_createsItAndRecordsItInTheSnapshots() async throws {
        let created = FileProviderItemEntity.make("new", in: folder.identifier, isFolder: true)
        let nodeActionRepo = MockFileProviderNodeActionRepository(createdFolder: created.node)
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [folder.identifier: FileProviderSnapshotEntity()])
        let sut = makeSUT(items: [folder, created], nodeActionRepo: nodeActionRepo, snapshotRepo: snapshotRepo)

        let item = try await sut.createFolder(named: "New", in: folder.identifier, reusesExistingFolder: false)

        #expect(item == created)
        #expect(await nodeActionRepo.actions == [.createFolder(name: "New", parent: "folder")])
        #expect(snapshotRepo.snapshots[folder.identifier] == snapshot(of: [created]))
        #expect(snapshotRepo.snapshots[created.identifier] == FileProviderSnapshotEntity())
    }

    @Test
    func createFolder_reusingAFolderWithASnapshot_keepsTheSnapshot() async throws {
        let existing = FileProviderItemEntity.make("existing", in: folder.identifier, isFolder: true)
        let existingSnapshot = snapshot(of: [.make("child", in: existing.identifier)])
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [existing.identifier: existingSnapshot])
        let sut = makeSUT(items: [folder, existing], nodeRepo: MockNodeRepository(childNode: existing.node), snapshotRepo: snapshotRepo)

        _ = try await sut.createFolder(named: "existing", in: folder.identifier, reusesExistingFolder: true)

        #expect(snapshotRepo.snapshots[existing.identifier] == existingSnapshot)
    }

    @Test
    func createFolder_reusingAnExistingFolder_returnsItWithoutCreatingAnother() async throws {
        let existing = FileProviderItemEntity.make("existing", in: folder.identifier, isFolder: true)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(items: [folder, existing], nodeRepo: MockNodeRepository(childNode: existing.node), nodeActionRepo: nodeActionRepo)

        let item = try await sut.createFolder(named: "existing", in: folder.identifier, reusesExistingFolder: true)

        #expect(item == existing)
        #expect(await nodeActionRepo.actions.isEmpty)
    }

    @Test
    func createFolder_reusingWhenOnlyAFileHasTheName_createsTheFolder() async throws {
        let file = FileProviderItemEntity.make("file", in: folder.identifier)
        let created = FileProviderItemEntity.make("new", in: folder.identifier, isFolder: true)
        let nodeActionRepo = MockFileProviderNodeActionRepository(createdFolder: created.node)
        let sut = makeSUT(items: [folder, created], nodeRepo: MockNodeRepository(childNode: file.node), nodeActionRepo: nodeActionRepo)

        let item = try await sut.createFolder(named: "file", in: folder.identifier, reusesExistingFolder: true)

        #expect(item == created)
        #expect(await nodeActionRepo.actions == [.createFolder(name: "file", parent: "folder")])
    }

    @Test
    func createFolder_inAFile_throwsNoSuchItem() async {
        let file = FileProviderItemEntity.make("file")
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(items: [file], nodeActionRepo: nodeActionRepo)

        await #expect(throws: NSFileProviderError(.noSuchItem)) {
            try await sut.createFolder(named: "New", in: file.identifier, reusesExistingFolder: false)
        }
        #expect(await nodeActionRepo.actions.isEmpty)
    }

    @Test
    func createFolder_whenTheBusinessAccountIsExpired_throwsCannotSynchronize() async {
        let sut = makeSUT(items: [folder], nodeActionRepo: MockFileProviderNodeActionRepository(error: CreateFolderErrorEntity.businessExpired))

        await #expect(throws: NSFileProviderError(.cannotSynchronize)) {
            try await sut.createFolder(named: "New", in: folder.identifier, reusesExistingFolder: false)
        }
    }

    // MARK: - modifyItem

    @Test
    func modifyItem_withANewName_renamesTheNodeAndReturnsTheRenamedItem() async throws {
        let before = FileProviderItemEntity.make("a", in: folder.identifier, name: "old")
        let after = FileProviderItemEntity.make("a", in: folder.identifier, name: "new")
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [folder.identifier: snapshot(of: [before])])
        let sut = makeSUT(items: [before, after], nodeActionRepo: nodeActionRepo, snapshotRepo: snapshotRepo)

        let item = try await sut.modifyItem(before.identifier, name: "new", parentIdentifier: nil)

        #expect(item == after)
        #expect(await nodeActionRepo.actions == [.rename("a", name: "new")])
        #expect(snapshotRepo.snapshots[folder.identifier] == snapshot(of: [after]))
    }

    @Test
    func modifyItem_withTheSameNameAndParent_changesNothing() async throws {
        let item = FileProviderItemEntity.make("a", in: folder.identifier)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(items: [item], nodeActionRepo: nodeActionRepo)

        let modifiedItem = try await sut.modifyItem(item.identifier, name: "a", parentIdentifier: folder.identifier)

        #expect(modifiedItem == item)
        #expect(await nodeActionRepo.actions.isEmpty)
    }

    @Test
    func modifyItem_toAnotherFolder_movesTheNodeAndMovesItBetweenTheSnapshots() async throws {
        let before = FileProviderItemEntity.make("a", in: folder.identifier)
        let after = FileProviderItemEntity.make("a", in: otherFolder.identifier)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [
            folder.identifier: snapshot(of: [before]),
            otherFolder.identifier: FileProviderSnapshotEntity()
        ])
        let sut = makeSUT(items: [before, after, otherFolder], nodeActionRepo: nodeActionRepo, snapshotRepo: snapshotRepo)

        let item = try await sut.modifyItem(before.identifier, name: nil, parentIdentifier: otherFolder.identifier)

        #expect(item == after)
        #expect(await nodeActionRepo.actions == [.move("a", parent: "other")])
        #expect(snapshotRepo.snapshots[folder.identifier] == FileProviderSnapshotEntity())
        #expect(snapshotRepo.snapshots[otherFolder.identifier] == snapshot(of: [after]))
    }

    @Test
    func modifyItem_toAFolderWithoutSnapshot_createsNoSnapshot() async throws {
        let before = FileProviderItemEntity.make("a", in: folder.identifier)
        let after = FileProviderItemEntity.make("a", in: otherFolder.identifier)
        let snapshotRepo = MockFileProviderSnapshotRepository()
        let sut = makeSUT(items: [before, after, otherFolder], snapshotRepo: snapshotRepo)

        _ = try await sut.modifyItem(before.identifier, name: nil, parentIdentifier: otherFolder.identifier)

        #expect(snapshotRepo.snapshots.isEmpty)
    }

    @Test
    func modifyItem_withANewNameAndParent_movesAndRenamesTheNode() async throws {
        let before = FileProviderItemEntity.make("a", in: folder.identifier)
        let after = FileProviderItemEntity.make("a", in: otherFolder.identifier, name: "b")
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(items: [before, after, otherFolder], nodeActionRepo: nodeActionRepo)

        let item = try await sut.modifyItem(before.identifier, name: "b", parentIdentifier: otherFolder.identifier)

        #expect(item == after)
        #expect(await nodeActionRepo.actions == [.move("a", parent: "other"), .rename("a", name: "b")])
    }

    @Test
    func modifyItem_toTheTrash_movesTheNodeToTheRubbishBin() async throws {
        let before = FileProviderItemEntity.make("a", in: folder.identifier)
        let after = FileProviderItemEntity.make("a", in: .trashContainer)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(items: [before, after], nodeActionRepo: nodeActionRepo)

        let item = try await sut.modifyItem(before.identifier, name: nil, parentIdentifier: .trashContainer)

        #expect(item == after)
        #expect(await nodeActionRepo.actions == [.trash("a")])
    }

    @Test
    func modifyItem_toTheTrashWithANewName_movesTheNodeWithoutRenamingIt() async throws {
        let before = FileProviderItemEntity.make("a", in: folder.identifier)
        let after = FileProviderItemEntity.make("a", in: .trashContainer)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(items: [before, after], nodeActionRepo: nodeActionRepo)

        let item = try await sut.modifyItem(before.identifier, name: "a 2", parentIdentifier: .trashContainer)

        #expect(item == after)
        #expect(await nodeActionRepo.actions == [.trash("a")])
    }

    @Test
    func modifyItem_inTheTrashWithANewName_doesNotRenameTheNode() async throws {
        let item = FileProviderItemEntity.make("a", in: .trashContainer)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(items: [item], nodeActionRepo: nodeActionRepo)

        _ = try await sut.modifyItem(item.identifier, name: "a 2", parentIdentifier: nil)

        #expect(await nodeActionRepo.actions.isEmpty)
    }

    @Test
    func modifyItem_outOfTheTrashWithANewName_renamesTheNode() async throws {
        let before = trashedItem(restoreParentHandle: 30)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(items: [before, otherFolder], nodeActionRepo: nodeActionRepo)

        _ = try await sut.modifyItem(before.identifier, name: "b", parentIdentifier: otherFolder.identifier)

        #expect(await nodeActionRepo.actions == [.move("a", parent: "other"), .rename("a", name: "b")])
    }

    @Test
    func modifyItem_outOfTheTrash_restoresTheNodeToWhereItWasTrashedFrom() async throws {
        let restoreFolder = NodeEntity(handle: 30, base64Handle: "restore", isFolder: true)
        let before = trashedItem(restoreParentHandle: restoreFolder.handle)
        let after = FileProviderItemEntity.make("a", in: NSFileProviderItemIdentifier("restore"))
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(
            items: [before, after, otherFolder],
            nodeRepo: MockNodeRepository(nodesForHandle: [restoreFolder.handle: restoreFolder]),
            nodeActionRepo: nodeActionRepo
        )

        let item = try await sut.modifyItem(before.identifier, name: nil, parentIdentifier: otherFolder.identifier)

        #expect(item == after)
        #expect(await nodeActionRepo.actions == [.untrash("a")])
    }

    @Test
    func modifyItem_outOfTheTrashWhenItsFormerFolderIsGone_movesTheNodeToTheNewParent() async throws {
        let before = trashedItem(restoreParentHandle: 30)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(items: [before, otherFolder], nodeActionRepo: nodeActionRepo)

        _ = try await sut.modifyItem(before.identifier, name: nil, parentIdentifier: otherFolder.identifier)

        #expect(await nodeActionRepo.actions == [.move("a", parent: "other")])
    }

    @Test
    func modifyItem_outOfTheTrashWhenItsFormerFolderIsInTheRubbishBin_movesTheNodeToTheNewParent() async throws {
        let restoreFolder = NodeEntity(handle: 30, base64Handle: "restore", isFolder: true)
        let before = trashedItem(restoreParentHandle: restoreFolder.handle)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(
            items: [before, otherFolder],
            nodeRepo: MockNodeRepository(nodesForHandle: [restoreFolder.handle: restoreFolder], isInRubbishBinNodes: [restoreFolder]),
            nodeActionRepo: nodeActionRepo
        )

        _ = try await sut.modifyItem(before.identifier, name: nil, parentIdentifier: otherFolder.identifier)

        #expect(await nodeActionRepo.actions == [.move("a", parent: "other")])
    }

    @Test
    func modifyItem_fromTheTrashIntoAFolderInTheRubbishBin_movesTheNodeThere() async throws {
        let restoreFolder = NodeEntity(handle: 30, base64Handle: "restore", isFolder: true)
        let before = trashedItem(restoreParentHandle: restoreFolder.handle)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(
            items: [before, otherFolder],
            nodeRepo: MockNodeRepository(nodesForHandle: [restoreFolder.handle: restoreFolder], isInRubbishBinNodes: [otherFolder.node]),
            nodeActionRepo: nodeActionRepo
        )

        _ = try await sut.modifyItem(before.identifier, name: nil, parentIdentifier: otherFolder.identifier)

        #expect(await nodeActionRepo.actions == [.move("a", parent: "other")])
    }

    @Test
    func modifyItem_ofAMissingItem_throwsNoSuchItem() async {
        let sut = makeSUT(items: [folder])

        await #expect(throws: NSFileProviderError(.noSuchItem)) {
            try await sut.modifyItem(NSFileProviderItemIdentifier("missing"), name: "b", parentIdentifier: nil)
        }
    }

    @Test
    func modifyItem_toAMissingParent_throwsNoSuchItem() async {
        let item = FileProviderItemEntity.make("a", in: folder.identifier)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(items: [item], nodeActionRepo: nodeActionRepo)

        await #expect(throws: NSFileProviderError(.noSuchItem)) {
            try await sut.modifyItem(item.identifier, name: nil, parentIdentifier: NSFileProviderItemIdentifier("missing"))
        }
        #expect(await nodeActionRepo.actions.isEmpty)
    }

    @Test(arguments: [RenameNodeErrorEntity.businessExpired as any Error, MoveNodeErrorEntity.businessExpired])
    func modifyItem_whenTheBusinessAccountIsExpired_throwsCannotSynchronize(error: any Error) async {
        let item = FileProviderItemEntity.make("a", in: folder.identifier)
        let sut = makeSUT(items: [item, otherFolder], nodeActionRepo: MockFileProviderNodeActionRepository(error: error))

        await #expect(throws: NSFileProviderError(.cannotSynchronize)) {
            try await sut.modifyItem(item.identifier, name: "b", parentIdentifier: otherFolder.identifier)
        }
    }

    // MARK: - deleteItem

    @Test
    func deleteItem_inTheRubbishBin_deletesTheNodeAndItsSnapshots() async throws {
        let trashedFolder = FileProviderItemEntity.make("a", in: .trashContainer, isFolder: true)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [
            .trashContainer: snapshot(of: [trashedFolder]),
            trashedFolder.identifier: FileProviderSnapshotEntity()
        ])
        let sut = makeSUT(
            items: [trashedFolder],
            nodeRepo: MockNodeRepository(isInRubbishBinNodes: [trashedFolder.node]),
            nodeActionRepo: nodeActionRepo,
            snapshotRepo: snapshotRepo
        )

        try await sut.deleteItem(trashedFolder.identifier, recursive: false)

        #expect(await nodeActionRepo.actions == [.delete("a")])
        #expect(snapshotRepo.snapshots == [.trashContainer: FileProviderSnapshotEntity()])
    }

    @Test(arguments: [false, true])
    func deleteItem_outsideTheRubbishBin_throwsDeletionRejectedAndKeepsTheSnapshot(recursive: Bool) async {
        let item = FileProviderItemEntity.make("a", in: folder.identifier)
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [folder.identifier: snapshot(of: [item])])
        let sut = makeSUT(items: [item], nodeActionRepo: nodeActionRepo, snapshotRepo: snapshotRepo)

        await #expect(throws: NSFileProviderError(.deletionRejected)) {
            try await sut.deleteItem(item.identifier, recursive: recursive)
        }
        #expect(await nodeActionRepo.actions.isEmpty)
        #expect(snapshotRepo.snapshots == [folder.identifier: snapshot(of: [item])])
    }

    @Test
    func deleteItem_ofAMissingItem_succeedsWithoutDeleting() async throws {
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(items: [], nodeActionRepo: nodeActionRepo)

        try await sut.deleteItem(NSFileProviderItemIdentifier("missing"), recursive: false)

        #expect(await nodeActionRepo.actions.isEmpty)
    }

    @Test
    func deleteItem_ofAFolderWithChildren_throwsDirectoryNotEmptyUnlessRecursive() async throws {
        let folderWithChildren = FileProviderItemEntity(
            identifier: NSFileProviderItemIdentifier("a"),
            parentIdentifier: .trashContainer,
            node: NodeEntity(base64Handle: "a", isFolder: true),
            childCount: 1
        )
        let nodeActionRepo = MockFileProviderNodeActionRepository()
        let sut = makeSUT(
            items: [folderWithChildren],
            nodeRepo: MockNodeRepository(isInRubbishBinNodes: [folderWithChildren.node]),
            nodeActionRepo: nodeActionRepo
        )

        await #expect(throws: NSFileProviderError(.directoryNotEmpty)) {
            try await sut.deleteItem(folderWithChildren.identifier, recursive: false)
        }
        #expect(await nodeActionRepo.actions.isEmpty)

        try await sut.deleteItem(folderWithChildren.identifier, recursive: true)

        #expect(await nodeActionRepo.actions == [.delete("a")])
    }

    @Test
    func deleteItem_onlyTheAdministratorCanDelete_throwsDeletionRejected() async {
        let item = FileProviderItemEntity.make("a", in: .trashContainer)
        let sut = makeSUT(
            items: [item],
            nodeRepo: MockNodeRepository(isInRubbishBinNodes: [item.node]),
            nodeActionRepo: MockFileProviderNodeActionRepository(error: RemoveNodeErrorEntity.masterOnly)
        )

        await #expect(throws: NSFileProviderError(.deletionRejected)) {
            try await sut.deleteItem(item.identifier, recursive: false)
        }
    }

    // MARK: - Helpers

    /// A file directly in the trash, moved there from the folder with `restoreParentHandle`.
    private func trashedItem(restoreParentHandle: HandleEntity) -> FileProviderItemEntity {
        FileProviderItemEntity(
            identifier: NSFileProviderItemIdentifier("a"),
            parentIdentifier: .trashContainer,
            node: NodeEntity(name: "a", base64Handle: "a", restoreParentHandle: restoreParentHandle, isFile: true)
        )
    }

    private func snapshot(of items: [FileProviderItemEntity]) -> FileProviderSnapshotEntity {
        FileProviderEnumerationSnapshotUseCaseTests.snapshot(of: items)
    }

    /// - Parameter items: Each identifier's items in turn, as `MockSequencedFileProviderItemUseCase` returns them.
    private func makeSUT(
        items: [FileProviderItemEntity],
        nodeRepo: MockNodeRepository = MockNodeRepository(),
        nodeActionRepo: MockFileProviderNodeActionRepository = MockFileProviderNodeActionRepository(),
        snapshotRepo: MockFileProviderSnapshotRepository = MockFileProviderSnapshotRepository()
    ) -> some FileProviderItemActionUseCaseProtocol {
        FileProviderItemActionUseCase(
            itemUseCase: MockSequencedFileProviderItemUseCase(items),
            nodeRepo: nodeRepo,
            nodeActionRepo: nodeActionRepo,
            snapshotRepo: snapshotRepo
        )
    }
}
