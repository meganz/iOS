import FileProvider
import Foundation
import MEGADomain
import MEGADomainMock
import MEGAPickerFileProviderDomain
import Testing

struct FileProviderContentUseCaseTests {
    private static let directory = URL(fileURLWithPath: "/tmp/FileProviderContentUseCaseTests", isDirectory: true)

    @Test
    func downloadContents_ofFile_downloadsTheNodeIntoTheDirectory() async throws {
        let node = NodeEntity(handle: 1, isFile: true)
        let repository = MockFileProviderDownloadRepository()
        let sut = FileProviderContentUseCase(downloadRepo: repository)

        let url = try await sut.downloadContents(of: makeItem(node: node), into: Self.directory) { _ in }

        #expect(url.deletingLastPathComponent().standardizedFileURL == Self.directory.standardizedFileURL)
        #expect(repository.downloads == [MockFileProviderDownloadRepository.Download(node: node, url: url)])
    }

    @Test
    func downloadContents_ofTheSameFileTwice_downloadsToDifferentFiles() async throws {
        let item = makeItem(node: NodeEntity(handle: 1, isFile: true))
        let sut = FileProviderContentUseCase(downloadRepo: MockFileProviderDownloadRepository())

        let first = try await sut.downloadContents(of: item, into: Self.directory) { _ in }
        let second = try await sut.downloadContents(of: item, into: Self.directory) { _ in }

        #expect(first != second)
    }

    @Test
    func downloadContents_reportsTheDownloadProgress() async throws {
        let repository = MockFileProviderDownloadRepository(progress: [10, 20])
        let sut = FileProviderContentUseCase(downloadRepo: repository)
        let reported = Reported()

        _ = try await sut.downloadContents(of: makeItem(node: NodeEntity(isFile: true)), into: Self.directory) {
            reported.append($0)
        }

        #expect(reported.values == [10, 20])
    }

    @Test
    func downloadContents_ofFolder_throwsWithoutDownloading() async {
        let repository = MockFileProviderDownloadRepository()
        let sut = FileProviderContentUseCase(downloadRepo: repository)

        await #expect(throws: CocoaError(.featureUnsupported)) {
            try await sut.downloadContents(of: makeItem(node: NodeEntity(isFolder: true)), into: Self.directory) { _ in }
        }
        #expect(repository.downloads.isEmpty)
    }

    @Test
    func downloadContents_whenTheDownloadFails_throwsItsError() async {
        let sut = FileProviderContentUseCase(downloadRepo: MockFileProviderDownloadRepository(error: TransferErrorEntity.download))

        await #expect(throws: TransferErrorEntity.download) {
            try await sut.downloadContents(of: makeItem(node: NodeEntity(isFile: true)), into: Self.directory) { _ in }
        }
    }

    private func makeItem(node: NodeEntity) -> FileProviderItemEntity {
        FileProviderItemEntity(identifier: NSFileProviderItemIdentifier("item"), parentIdentifier: .rootContainer, node: node)
    }
}

private final class Reported: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Int] = []

    var values: [Int] {
        lock.withLock { storage }
    }

    func append(_ value: Int) {
        lock.withLock { storage.append(value) }
    }
}

private final class MockFileProviderDownloadRepository: FileProviderDownloadRepositoryProtocol, @unchecked Sendable {
    struct Download: Equatable {
        let node: NodeEntity
        let url: URL
    }

    static var newRepo: MockFileProviderDownloadRepository {
        MockFileProviderDownloadRepository()
    }

    private let progress: [Int]
    private let error: (any Error)?
    private(set) var downloads: [Download] = []

    init(progress: [Int] = [], error: (any Error)? = nil) {
        self.progress = progress
        self.error = error
    }

    func download(node: NodeEntity, to url: URL, progress: @escaping @Sendable (Int) -> Void) async throws {
        downloads.append(Download(node: node, url: url))
        self.progress.forEach(progress)
        if let error { throw error }
    }
}
