import Foundation
import MEGADomain
import MEGADomainMock
import Testing

/// Covers how a node reaches the caller as a URL — which copy is reused and which is downloaded — since a
/// URL handed over before its content is whole is indistinguishable from a finished one to everything
/// downstream.
@Suite("ExportFileUseCase Tests")
struct ExportFileUseCaseTests {
    private static let tempFolder = URL(fileURLWithPath: "/temp")
    private static let base64Handle = "handle"
    private static let folderName = "MyFolder"
    private static let destinationURL = tempFolder.appendingPathComponent(folderName)
    private static let stagingFolderURL = tempFolder.appendingPathComponent(base64Handle + ".incomplete")
    private static let stagingURL = stagingFolderURL.appendingPathComponent(folderName)

    @Test("a folder is downloaded into staging and moved into place before being handed over")
    func exportFolder_movesStagedDownloadIntoPlace() async throws {
        let fileSystem = MockFileSystemRepository(movedNode: true)
        let sut = makeSUT(
            fileSystemRepository: fileSystem,
            downloadResult: .success(TransferEntity(path: Self.stagingURL.path))
        )

        let url = try await sut.export(node: folderNode)

        #expect(url == Self.destinationURL, "The caller must get the final path, never the staging one.")
        #expect(fileSystem.movedFiles.count == 1)
        #expect(fileSystem.movedFiles.first?.source == Self.stagingURL)
        #expect(fileSystem.movedFiles.first?.destination == Self.destinationURL)
    }

    /// The move takes the folder out of the staging directory but leaves the directory itself, so clearing
    /// the copy alone would leave one empty directory behind for every folder ever exported.
    @Test("a folder moved into place leaves no staging directory behind")
    func exportFolder_complete_clearsStagingDirectory() async throws {
        let fileSystem = MockFileSystemRepository(movedNode: true)
        let sut = makeSUT(
            fileSystemRepository: fileSystem,
            downloadResult: .success(TransferEntity(path: Self.stagingURL.path))
        )

        _ = try await sut.export(node: folderNode)

        #expect(fileSystem.removeFileURLs.contains(Self.stagingFolderURL))
    }

    /// Otherwise the next attempt downloads alongside the leftovers under a deduplicated name, and moves the
    /// older tree into place instead of the one it just fetched.
    @Test("a folder whose download fails leaves no staged copy behind")
    func exportFolder_downloadFails_clearsStagedCopy() async {
        let fileSystem = MockFileSystemRepository()
        let sut = makeSUT(fileSystemRepository: fileSystem, downloadResult: .failure(.download))

        await #expect(throws: ExportFileErrorEntity.self) {
            try await sut.export(node: folderNode)
        }
        #expect(fileSystem.removeFileURLs.contains(Self.stagingFolderURL))
    }

    /// The tree is whole and merely in the wrong place, so it is still worth handing over — at the cost of
    /// the next export downloading it again rather than finding it in the cache.
    @Test("a folder that could not be moved into place is handed over from staging")
    func exportFolder_moveFails_handsOverStagedCopy() async throws {
        let fileSystem = MockFileSystemRepository(movedNode: false)
        let sut = makeSUT(
            fileSystemRepository: fileSystem,
            downloadResult: .success(TransferEntity(path: Self.stagingURL.path))
        )

        let url = try await sut.export(node: folderNode)

        #expect(url == Self.stagingURL)
        #expect(
            !fileSystem.removeFileURLs.contains(Self.stagingFolderURL),
            "The staging directory has to survive, since what is handed over is inside it."
        )
    }

    /// The SDK writes a file under a temporary leaf name and takes the real one only on completion, so a
    /// file needs no staging of our own and must keep going straight to its destination.
    @Test("a file is downloaded straight to its final place")
    func exportFile_downloadsWithoutStaging() async throws {
        let fileSystem = MockFileSystemRepository()
        let sut = makeSUT(
            fileSystemRepository: fileSystem,
            downloadResult: .success(TransferEntity(path: Self.destinationURL.path))
        )

        let url = try await sut.export(node: NodeEntity(name: "elcapitan.jpeg", isFile: true))

        #expect(url == Self.destinationURL)
        #expect(fileSystem.movedFiles.isEmpty, "A file is already whole when it takes its final name.")
    }

    @Test("a cached copy is handed over instead of being downloaded again")
    func export_cachedCopy_isReused() async throws {
        let sut = makeSUT(
            fileCacheRepository: MockFileCacheRepository(
                base64Handle: Self.base64Handle,
                name: Self.folderName,
                tempFolder: Self.tempFolder
            ),
            downloadResult: .failure(.download)
        )

        let url = try await sut.export(node: folderNode)

        #expect(url == Self.destinationURL, "Downloading would have failed, so this can only be the cache.")
    }

    /// The record and the copy it points at live in different containers, so the record can outlive the file.
    @Test("an offline record with nothing under it is not mistaken for a copy")
    func export_staleOfflineRecord_fallsThroughToDownload() async throws {
        let sut = makeSUT(
            fileSystemRepository: MockFileSystemRepository(fileExists: false, movedNode: true),
            offlineFileFetcherRepository: MockOfflineFileFetcherRepository(
                offlineFileEntity: OfflineFileEntity(
                    base64Handle: Self.base64Handle,
                    localPath: Self.folderName,
                    parentBase64Handle: nil,
                    fingerprint: nil,
                    timestamp: nil
                )
            ),
            downloadResult: .success(TransferEntity(path: Self.stagingURL.path))
        )

        let url = try await sut.export(node: folderNode)

        #expect(url == Self.destinationURL, "The stale record must not short circuit the download.")
    }

    private var folderNode: NodeEntity {
        NodeEntity(name: Self.folderName, base64Handle: Self.base64Handle, isFolder: true)
    }

    private func makeSUT(
        fileCacheRepository: MockFileCacheRepository = MockFileCacheRepository(
            base64Handle: base64Handle,
            name: folderName,
            hasExistingTempFile: false,
            tempFolder: tempFolder
        ),
        fileSystemRepository: MockFileSystemRepository = MockFileSystemRepository(),
        offlineFileFetcherRepository: MockOfflineFileFetcherRepository = MockOfflineFileFetcherRepository(),
        downloadResult: Result<TransferEntity, TransferErrorEntity>
    ) -> some ExportFileUseCaseProtocol {
        ExportFileUseCase(
            downloadFileRepository: MockDownloadFileRepository(completionResult: downloadResult),
            offlineFilesRepository: MockOfflineFilesRepository(),
            fileCacheRepository: fileCacheRepository,
            thumbnailRepository: MockThumbnailRepository(),
            fileSystemRepository: fileSystemRepository,
            exportChatMessagesRepository: MockExportChatMessagesRepository(),
            importNodeRepository: MockImportNodeRepository(),
            megaHandleRepository: MockMEGAHandleRepository(),
            mediaUseCase: MockMediaUseCase(),
            offlineFileFetcherRepository: offlineFileFetcherRepository,
            userStoreRepository: MockUserStoreRepository()
        )
    }
}
