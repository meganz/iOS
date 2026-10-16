import FileProvider
import MEGADomain
import MEGADomainMock
import MEGAPickerFileProviderDomain
import MEGASwift
import Testing

struct FileProviderUploadUseCaseTests {
    private let folder = FileProviderItemEntity.make("folder", isFolder: true)
    private let url = URL(fileURLWithPath: "/contents/1")
    private let modificationDate = Date(timeIntervalSince1970: 100)

    // MARK: - createFile

    @Test
    func createFile_inAFolder_uploadsItAndRecordsItInTheSnapshot() async throws {
        let uploaded = FileProviderItemEntity.make("new", in: folder.identifier)
        let uploadRepo = MockFileProviderUploadRepository(uploadedFile: uploaded.node)
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [folder.identifier: FileProviderSnapshotEntity()])
        let sut = makeSUT(items: [folder, uploaded], uploadRepo: uploadRepo, snapshotRepo: snapshotRepo)

        let item = try await sut.createFile(named: "a.pdf", in: folder.identifier, contentsAt: url, modificationDate: modificationDate)

        #expect(item == uploaded)
        #expect(await uploadRepo.uploads == [.init(url: url, name: "a.pdf", parent: "folder", modificationDate: modificationDate)])
        #expect(snapshotRepo.snapshots[folder.identifier] == snapshot(of: [uploaded]))
    }

    @Test
    func createFile_reportsTheBytesSent() async throws {
        let uploaded = FileProviderItemEntity.make("new", in: folder.identifier)
        let sentBytes = Atomic<[Int]>(wrappedValue: [])
        let sut = makeSUT(items: [folder, uploaded], uploadRepo: MockFileProviderUploadRepository(uploadedFile: uploaded.node, sentBytes: [1, 5]))

        _ = try await sut.createFile(
            named: "a.pdf",
            in: folder.identifier,
            contentsAt: url,
            modificationDate: nil
        ) { bytes in
            sentBytes.mutate { $0.append(bytes) }
        }

        #expect(sentBytes.wrappedValue == [1, 5])
    }

    @Test(arguments: [
        (["a.pdf"], "a (1).pdf"),
        (["a.pdf", "a (1).pdf"], "a (2).pdf"),
        (["notes"], "notes (1)")
    ])
    func createFile_whenAFileOfOtherContentsHasTheName_uploadsItUnderAFreeName(takenNames: [String], expectedName: String) async throws {
        let name = try #require(takenNames.first)
        let uploaded = FileProviderItemEntity.make("new", in: folder.identifier)
        let uploadRepo = MockFileProviderUploadRepository(uploadedFile: uploaded.node, fileFingerprint: "new")
        let takenFiles = takenNames.map { ($0, NodeEntity(name: $0, fingerprint: "other", isFile: true)) }
        let nodeRepo = MockNodeRepository(childNodes: Dictionary(uniqueKeysWithValues: takenFiles))
        let sut = makeSUT(items: [folder, uploaded], nodeRepo: nodeRepo, uploadRepo: uploadRepo)

        _ = try await sut.createFile(named: name, in: folder.identifier, contentsAt: url)

        #expect(await uploadRepo.uploads.map(\.name) == [expectedName])
    }

    @Test
    func createFile_whenAFileOfTheSameContentsHasTheName_uploadsItUnderThatName() async throws {
        let uploaded = FileProviderItemEntity.make("new", in: folder.identifier)
        let uploadRepo = MockFileProviderUploadRepository(uploadedFile: uploaded.node, fileFingerprint: "same")
        let nodeRepo = MockNodeRepository(childNodes: ["a.pdf": NodeEntity(name: "a.pdf", fingerprint: "same", isFile: true)])
        let sut = makeSUT(items: [folder, uploaded], nodeRepo: nodeRepo, uploadRepo: uploadRepo)

        _ = try await sut.createFile(named: "a.pdf", in: folder.identifier, contentsAt: url)

        #expect(await uploadRepo.uploads.map(\.name) == ["a.pdf"])
    }

    @Test
    func createFile_inAFile_throwsNoSuchItemWithoutUploading() async {
        let file = FileProviderItemEntity.make("file")
        let uploadRepo = MockFileProviderUploadRepository()
        let sut = makeSUT(items: [file], uploadRepo: uploadRepo)

        await #expect(throws: NSFileProviderError(.noSuchItem)) {
            try await sut.createFile(named: "a.pdf", in: file.identifier, contentsAt: url)
        }
        #expect(await uploadRepo.uploads.isEmpty)
    }

    @Test
    func createFile_whenTheUploadFails_throwsItsError() async {
        let sut = makeSUT(items: [folder], uploadRepo: MockFileProviderUploadRepository(error: TransferErrorEntity.overquota))

        await #expect(throws: TransferErrorEntity.overquota) {
            try await sut.createFile(named: "a.pdf", in: folder.identifier, contentsAt: url)
        }
    }

    @Test
    func createFile_withoutContents_returnsTheFileOfThatNameWithoutUploading() async throws {
        let existing = FileProviderItemEntity.make("existing", in: folder.identifier)
        let uploadRepo = MockFileProviderUploadRepository()
        let sut = makeSUT(items: [folder, existing], nodeRepo: MockNodeRepository(childNode: existing.node), uploadRepo: uploadRepo)

        let item = try await sut.createFile(named: "existing", in: folder.identifier, contentsAt: nil)

        #expect(item == existing)
        #expect(await uploadRepo.uploads.isEmpty)
    }

    @Test
    func createFile_withoutContentsWhenOnlyAFolderHasTheName_returnsNil() async throws {
        let existingFolder = FileProviderItemEntity.make("existing", in: folder.identifier, isFolder: true)
        let sut = makeSUT(items: [folder, existingFolder], nodeRepo: MockNodeRepository(childNode: existingFolder.node))

        let item = try await sut.createFile(named: "existing", in: folder.identifier, contentsAt: nil)

        #expect(item == nil)
    }

    // MARK: - uploadContents

    @Test
    func uploadContents_appliesTheNameAndParentFirst() async throws {
        let file = FileProviderItemEntity.make("a", in: folder.identifier)
        let uploaded = FileProviderItemEntity.make("b", in: folder.identifier)
        let itemActionUseCase = MockFileProviderItemActionUseCase(modifiedItem: file)
        let sut = makeSUT(
            items: [folder, uploaded],
            itemActionUseCase: itemActionUseCase,
            uploadRepo: MockFileProviderUploadRepository(uploadedFile: uploaded.node)
        )

        _ = try await sut.uploadContents(of: file.identifier, at: url, name: "b", parentIdentifier: folder.identifier, modificationDate: nil) { _ in }

        #expect(await itemActionUseCase.modifications == [.init(identifier: file.identifier, name: "b", parentIdentifier: folder.identifier)])
    }

    @Test
    func uploadContents_uploadsUnderTheNameAndInTheFolderTheFileHas() async throws {
        let file = FileProviderItemEntity.make("a", in: folder.identifier, name: "current.pdf")
        let uploaded = FileProviderItemEntity.make("b", in: folder.identifier, name: "current.pdf")
        let uploadRepo = MockFileProviderUploadRepository(uploadedFile: uploaded.node)
        let sut = makeSUT(
            items: [folder, uploaded],
            itemActionUseCase: MockFileProviderItemActionUseCase(modifiedItem: file),
            uploadRepo: uploadRepo
        )

        let item = try await sut.uploadContents(
            of: file.identifier,
            at: url,
            name: nil,
            parentIdentifier: nil,
            modificationDate: modificationDate
        ) { _ in }

        #expect(item == uploaded)
        #expect(await uploadRepo.uploads == [.init(url: url, name: "current.pdf", parent: "folder", modificationDate: modificationDate)])
    }

    @Test
    func uploadContents_replacesTheFormerVersionInTheSnapshot() async throws {
        let file = FileProviderItemEntity.make("a", in: folder.identifier)
        let uploaded = FileProviderItemEntity.make("b", in: folder.identifier)
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [folder.identifier: snapshot(of: [file])])
        let sut = makeSUT(
            items: [folder, uploaded],
            itemActionUseCase: MockFileProviderItemActionUseCase(modifiedItem: file),
            uploadRepo: MockFileProviderUploadRepository(uploadedFile: uploaded.node),
            snapshotRepo: snapshotRepo
        )

        _ = try await sut.uploadContents(of: file.identifier, at: url, name: nil, parentIdentifier: nil, modificationDate: nil) { _ in }

        #expect(snapshotRepo.snapshots[folder.identifier] == snapshot(of: [uploaded]))
    }

    @Test
    func uploadContents_whenTheFileIsUnchanged_keepsItInTheSnapshot() async throws {
        let file = FileProviderItemEntity.make("a", in: folder.identifier)
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [folder.identifier: snapshot(of: [file])])
        let sut = makeSUT(
            items: [folder, file],
            itemActionUseCase: MockFileProviderItemActionUseCase(modifiedItem: file),
            uploadRepo: MockFileProviderUploadRepository(uploadedFile: file.node),
            snapshotRepo: snapshotRepo
        )

        let item = try await sut.uploadContents(of: file.identifier, at: url, name: nil, parentIdentifier: nil, modificationDate: nil) { _ in }

        #expect(item == file)
        #expect(snapshotRepo.snapshots[folder.identifier] == snapshot(of: [file]))
    }

    @Test
    func uploadContents_givesTheNewVersionTheCoordinatesOfTheFormerOne() async throws {
        let file = FileProviderItemEntity(
            identifier: NSFileProviderItemIdentifier("a"),
            parentIdentifier: folder.identifier,
            node: NodeEntity(name: "a.jpg", base64Handle: "a", isFile: true, latitude: 1.5, longitude: -2.5)
        )
        let uploaded = FileProviderItemEntity.make("b", in: folder.identifier)
        let nodeCoordinatesRepo = MockFileProviderNodeCoordinatesRepository()
        let sut = makeSUT(
            items: [folder, uploaded],
            itemActionUseCase: MockFileProviderItemActionUseCase(modifiedItem: file),
            uploadRepo: MockFileProviderUploadRepository(uploadedFile: uploaded.node),
            nodeCoordinatesRepo: nodeCoordinatesRepo
        )

        _ = try await sut.uploadContents(of: file.identifier, at: url, name: nil, parentIdentifier: nil, modificationDate: nil) { _ in }

        #expect(await nodeCoordinatesRepo.coordinates == [.init(node: "b", latitude: 1.5, longitude: -2.5)])
    }

    @Test
    func uploadContents_withoutCoordinates_setsNone() async throws {
        let file = FileProviderItemEntity.make("a", in: folder.identifier)
        let uploaded = FileProviderItemEntity.make("b", in: folder.identifier)
        let nodeCoordinatesRepo = MockFileProviderNodeCoordinatesRepository()
        let sut = makeSUT(
            items: [folder, uploaded],
            itemActionUseCase: MockFileProviderItemActionUseCase(modifiedItem: file),
            uploadRepo: MockFileProviderUploadRepository(uploadedFile: uploaded.node),
            nodeCoordinatesRepo: nodeCoordinatesRepo
        )

        _ = try await sut.uploadContents(of: file.identifier, at: url, name: nil, parentIdentifier: nil, modificationDate: nil) { _ in }

        #expect(await nodeCoordinatesRepo.coordinates.isEmpty)
    }

    @Test
    func uploadContents_ofAFolder_throwsFeatureUnsupportedWithoutUploading() async {
        let subfolder = FileProviderItemEntity.make("sub", in: folder.identifier, isFolder: true)
        let uploadRepo = MockFileProviderUploadRepository()
        let sut = makeSUT(
            items: [folder],
            itemActionUseCase: MockFileProviderItemActionUseCase(modifiedItem: subfolder),
            uploadRepo: uploadRepo
        )

        await #expect(throws: CocoaError(.featureUnsupported)) {
            try await sut.uploadContents(of: subfolder.identifier, at: url, name: nil, parentIdentifier: nil, modificationDate: nil) { _ in }
        }
        #expect(await uploadRepo.uploads.isEmpty)
    }

    @Test
    func uploadContents_ofAMissingFile_throwsNoSuchItemWithoutUploading() async {
        let uploadRepo = MockFileProviderUploadRepository()
        let sut = makeSUT(
            items: [folder],
            itemActionUseCase: MockFileProviderItemActionUseCase(error: NSFileProviderError(.noSuchItem)),
            uploadRepo: uploadRepo
        )

        let identifier = NSFileProviderItemIdentifier("a")

        await #expect(throws: NSFileProviderError(.noSuchItem)) {
            try await sut.uploadContents(of: identifier, at: url, name: nil, parentIdentifier: nil, modificationDate: nil) { _ in }
        }
        #expect(await uploadRepo.uploads.isEmpty)
    }

    // MARK: - Helpers

    private func snapshot(of items: [FileProviderItemEntity]) -> FileProviderSnapshotEntity {
        FileProviderEnumerationSnapshotUseCaseTests.snapshot(of: items)
    }

    private func makeSUT(
        items: [FileProviderItemEntity],
        itemActionUseCase: MockFileProviderItemActionUseCase = MockFileProviderItemActionUseCase(),
        nodeRepo: MockNodeRepository = MockNodeRepository(),
        uploadRepo: MockFileProviderUploadRepository = MockFileProviderUploadRepository(),
        nodeCoordinatesRepo: MockFileProviderNodeCoordinatesRepository = MockFileProviderNodeCoordinatesRepository(),
        snapshotRepo: MockFileProviderSnapshotRepository = MockFileProviderSnapshotRepository()
    ) -> some FileProviderUploadUseCaseProtocol {
        FileProviderUploadUseCase(
            itemUseCase: MockSequencedFileProviderItemUseCase(items),
            itemActionUseCase: itemActionUseCase,
            nodeRepo: nodeRepo,
            uploadRepo: uploadRepo,
            nodeCoordinatesRepo: nodeCoordinatesRepo,
            snapshotRepo: snapshotRepo
        )
    }
}

private extension FileProviderUploadUseCaseProtocol {
    /// `createFile` for the tests that don't follow the progress.
    func createFile(
        named name: String,
        in parentIdentifier: NSFileProviderItemIdentifier,
        contentsAt url: URL?,
        modificationDate: Date? = nil
    ) async throws -> FileProviderItemEntity? {
        try await createFile(
            named: name,
            in: parentIdentifier,
            contentsAt: url,
            modificationDate: modificationDate
        ) { _ in }
    }
}
