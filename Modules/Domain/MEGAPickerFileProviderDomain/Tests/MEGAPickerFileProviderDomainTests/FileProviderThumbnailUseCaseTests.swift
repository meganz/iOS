import FileProvider
import Foundation
import MEGADomain
import MEGADomainMock
import MEGAPickerFileProviderDomain
import Testing

struct FileProviderThumbnailUseCaseTests {
    @Test
    func loadThumbnails_ofAFileWithAThumbnail_reportsItsData() async throws {
        let thumbnailURL = try makeThumbnailFile(contents: Data([1, 2, 3]))
        defer { try? FileManager.default.removeItem(at: thumbnailURL) }
        let file = Self.makeItem(handle: 1)
        let sut = makeSUT(items: [file], thumbnailResults: [1: .success(ThumbnailEntity(url: thumbnailURL, type: .thumbnail))])

        let loaded = await loadThumbnails(for: [file.identifier], using: sut)

        #expect(try loaded[file.identifier]?.get() == Data([1, 2, 3]))
    }

    @Test(arguments: [
        makeItem(handle: 1, hasThumbnail: false),
        makeItem(handle: 1, isFolder: true)
    ])
    func loadThumbnails_ofAnItemWithoutAThumbnail_reportsNone(item: FileProviderItemEntity) async throws {
        let sut = makeSUT(items: [item])

        let loaded = await loadThumbnails(for: [item.identifier], using: sut)

        #expect(try #require(loaded[item.identifier]).get() == nil)
    }

    @Test
    func loadThumbnails_ofAMissingItem_reportsNone() async throws {
        let identifier = NSFileProviderItemIdentifier("missing")

        let loaded = await loadThumbnails(for: [identifier], using: makeSUT(items: []))

        #expect(try #require(loaded[identifier]).get() == nil)
    }

    @Test
    func loadThumbnails_whenTheNodeHasNoThumbnailToDownload_reportsNone() async throws {
        let file = Self.makeItem(handle: 1)
        let sut = makeSUT(items: [file], thumbnailResults: [1: .failure(ThumbnailErrorEntity.noThumbnail(.thumbnail))])

        let loaded = await loadThumbnails(for: [file.identifier], using: sut)

        #expect(try #require(loaded[file.identifier]).get() == nil)
    }

    @Test
    func loadThumbnails_whenTheDownloadFails_reportsTheError() async throws {
        let file = Self.makeItem(handle: 1)
        let sut = makeSUT(items: [file], thumbnailResults: [1: .failure(GenericErrorEntity())])

        let loaded = await loadThumbnails(for: [file.identifier], using: sut)

        #expect(throws: GenericErrorEntity.self) { try loaded[file.identifier]?.get() }
    }

    @Test
    func loadThumbnails_ofMoreItemsThanAreLoadedAtATime_reportsEachOnce() async {
        let items = (1...7).map { Self.makeItem(handle: HandleEntity($0), hasThumbnail: false) }
        let sut = makeSUT(items: items)
        var reported: [NSFileProviderItemIdentifier] = []

        await sut.loadThumbnails(for: items.map(\.identifier)) { identifier, _ in reported.append(identifier) }

        #expect(Set(reported) == Set(items.map(\.identifier)))
        #expect(reported.count == items.count)
    }

    @Test
    func loadThumbnails_whenTheTaskIsCancelled_reportsNothing() async {
        let file = Self.makeItem(handle: 1, hasThumbnail: false)
        let sut = makeSUT(items: [file])

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await loadThumbnails(for: [file.identifier], using: sut)
        }

        #expect(await task.value.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(
        items: [FileProviderItemEntity],
        thumbnailResults: [HandleEntity: Result<ThumbnailEntity, any Error>] = [:]
    ) -> FileProviderThumbnailUseCase {
        FileProviderThumbnailUseCase(
            itemUseCase: MockFileProviderItemUseCase(presentableItems: items),
            thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResults: thumbnailResults)
        )
    }

    private static func makeItem(handle: HandleEntity, isFolder: Bool = false, hasThumbnail: Bool = true) -> FileProviderItemEntity {
        FileProviderItemEntity(
            identifier: NSFileProviderItemIdentifier("\(handle)"),
            parentIdentifier: .rootContainer,
            node: NodeEntity(handle: handle, base64Handle: "\(handle)", isFile: !isFolder, isFolder: isFolder, hasThumbnail: hasThumbnail)
        )
    }

    private func makeThumbnailFile(contents: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        try contents.write(to: url)
        return url
    }

    private func loadThumbnails(
        for identifiers: [NSFileProviderItemIdentifier],
        using sut: FileProviderThumbnailUseCase
    ) async -> [NSFileProviderItemIdentifier: Result<Data?, any Error>] {
        var loaded: [NSFileProviderItemIdentifier: Result<Data?, any Error>] = [:]
        await sut.loadThumbnails(for: identifiers) { loaded[$0] = $1 }
        return loaded
    }
}
