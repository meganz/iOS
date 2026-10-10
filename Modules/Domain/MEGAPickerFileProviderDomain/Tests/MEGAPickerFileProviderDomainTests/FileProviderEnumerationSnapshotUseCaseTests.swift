import FileProvider
import MEGAPickerFileProviderDomain
import Testing

struct FileProviderEnumerationSnapshotUseCaseTests {
    private let folder = NSFileProviderItemIdentifier("folder")

    @Test
    func didEnumerate_withoutSnapshot_createsItWithTheVersionHashes() async throws {
        let snapshotRepo = MockFileProviderSnapshotRepository()
        let sut = FileProviderEnumerationSnapshotUseCase(snapshotRepo: snapshotRepo)
        let items = [FileProviderItemEntity.make("a", in: folder), .make("b", in: folder)]

        try await sut.didEnumerate(items, in: folder)

        #expect(snapshotRepo.snapshots[folder] == Self.snapshot(of: items))
    }

    @Test
    func didEnumerate_emptyFolder_createsAnEmptySnapshot() async throws {
        let snapshotRepo = MockFileProviderSnapshotRepository()
        let sut = FileProviderEnumerationSnapshotUseCase(snapshotRepo: snapshotRepo)

        try await sut.didEnumerate([], in: folder)

        #expect(snapshotRepo.snapshots[folder] == FileProviderSnapshotEntity())
    }

    @Test
    func didEnumerate_keepsChildrenThePageDoesNotList() async throws {
        let kept = FileProviderItemEntity.make("kept", in: folder)
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [folder: Self.snapshot(of: [kept])])
        let sut = FileProviderEnumerationSnapshotUseCase(snapshotRepo: snapshotRepo)
        let firstPage = [FileProviderItemEntity.make("a", in: folder)]
        let lastPage = [FileProviderItemEntity.make("b", in: folder)]

        try await sut.didEnumerate(firstPage, in: folder)
        try await sut.didEnumerate(lastPage, in: folder)

        #expect(snapshotRepo.snapshots[folder] == Self.snapshot(of: [kept] + firstPage + lastPage))
    }

    @Test
    func didEnumerate_changedChild_replacesItsVersionHash() async throws {
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [folder: Self.snapshot(of: [.make("a", in: folder, name: "old")])])
        let sut = FileProviderEnumerationSnapshotUseCase(snapshotRepo: snapshotRepo)
        let renamed = FileProviderItemEntity.make("a", in: folder, name: "new")

        try await sut.didEnumerate([renamed], in: folder)

        #expect(snapshotRepo.snapshots[folder] == Self.snapshot(of: [renamed]))
    }

    @Test
    func didEnumerate_leavesOtherContainersAlone() async throws {
        let other = NSFileProviderItemIdentifier("other")
        let otherSnapshot = Self.snapshot(of: [.make("x", in: other)])
        let snapshotRepo = MockFileProviderSnapshotRepository(snapshots: [other: otherSnapshot])
        let sut = FileProviderEnumerationSnapshotUseCase(snapshotRepo: snapshotRepo)

        try await sut.didEnumerate([.make("a", in: folder)], in: folder)

        #expect(snapshotRepo.snapshots[other] == otherSnapshot)
    }

    @Test
    func didEnumerate_whenTheRepositoryFails_throws() async throws {
        let snapshotRepo = MockFileProviderSnapshotRepository(error: NSFileProviderError(.cannotSynchronize))
        let sut = FileProviderEnumerationSnapshotUseCase(snapshotRepo: snapshotRepo)

        await #expect(throws: NSFileProviderError(.cannotSynchronize)) {
            try await sut.didEnumerate([.make("a", in: folder)], in: folder)
        }
    }

    static func snapshot(of items: [FileProviderItemEntity]) -> FileProviderSnapshotEntity {
        FileProviderSnapshotEntity(versionHashes: Dictionary(uniqueKeysWithValues: items.map { ($0.identifier, $0.versionHash) }))
    }
}
