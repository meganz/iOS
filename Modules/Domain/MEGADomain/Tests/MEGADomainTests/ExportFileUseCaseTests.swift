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
            folderDownloadResult: .success(Self.wholeFolder)
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
            folderDownloadResult: .success(Self.wholeFolder)
        )

        _ = try await sut.export(node: folderNode)

        #expect(fileSystem.removeFileURLs.contains(Self.stagingFolderURL))
    }

    /// Otherwise the next attempt downloads alongside the leftovers under a deduplicated name, and moves the
    /// older tree into place instead of the one it just fetched.
    @Test("a folder whose download fails leaves no staged copy behind")
    func exportFolder_downloadFails_clearsStagedCopy() async {
        let fileSystem = MockFileSystemRepository()
        let sut = makeSUT(fileSystemRepository: fileSystem, folderDownloadResult: .failure(.download))

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
            folderDownloadResult: .success(Self.wholeFolder)
        )

        let url = try await sut.export(node: folderNode)

        #expect(url == Self.stagingURL)
        #expect(
            !fileSystem.removeFileURLs.contains(Self.stagingFolderURL),
            "The staging directory has to survive, since what is handed over is inside it."
        )
    }

    @Test("a folder that arrived whole reports every file as downloaded")
    func exportFolder_complete_reportsFullCounts() async throws {
        let sut = makeSUT(
            fileSystemRepository: MockFileSystemRepository(movedNode: true),
            folderDownloadResult: .success(Self.wholeFolder)
        )

        let exported = try await sut.exportFolder(folderNode)

        #expect(exported == ExportedNodeEntity(url: Self.destinationURL, fileCount: 4, downloadedFileCount: 4))
    }

    /// Worth handing over, but it must not be moved into place: the final directory is what tells a later
    /// export that a folder is already cached and whole.
    @Test("a folder missing some of its files is handed over from staging, with both counts")
    func exportFolder_partial_handsOverStagingWithCounts() async throws {
        let fileSystem = MockFileSystemRepository(movedNode: true)
        let sut = makeSUT(
            fileSystemRepository: fileSystem,
            folderDownloadResult: .success(
                FolderDownloadResultEntity(isSuccess: false, fileCount: 5, downloadedFileCount: 3)
            ),
            handsOverIncompleteFolders: true
        )

        let exported = try await sut.exportFolder(folderNode)

        #expect(exported == ExportedNodeEntity(url: Self.stagingURL, fileCount: 5, downloadedFileCount: 3))
        #expect(fileSystem.movedFiles.isEmpty, "A folder that is short of files must stay out of the cache.")
        #expect(
            !fileSystem.removeFileURLs.contains(Self.stagingFolderURL),
            "The staging directory has to survive, since what is handed over is inside it."
        )
    }

    /// A partial copy nobody announces is indistinguishable from a whole one, so a caller that cannot say
    /// what is missing gets nothing rather than something it would pass off as complete.
    @Test("a caller that cannot report a shortfall gets the incomplete folder discarded")
    func exportFolder_partialWithNoWayToReport_discardsIt() async throws {
        let fileSystem = MockFileSystemRepository(movedNode: true)
        let sut = makeSUT(
            fileSystemRepository: fileSystem,
            folderDownloadResult: .success(
                FolderDownloadResultEntity(isSuccess: false, fileCount: 5, downloadedFileCount: 3)
            )
        )

        let exported = try await sut.exportFolder(folderNode)

        #expect(exported.url == nil)
        #expect(exported.downloadedFileCount == 0, "Nothing was delivered once the partial tree was deleted.")
        #expect(exported.fileCount == 5, "How much was expected is still worth reporting.")
        #expect(fileSystem.removeFileURLs.contains(Self.stagingFolderURL))
    }

    /// The single-node path throws rather than handing back a URL, which is what it did before the counts
    /// existed.
    @Test("exporting a lone incomplete folder throws when the shortfall cannot be reported")
    func export_partialFolderWithNoWayToReport_throws() async {
        let sut = makeSUT(
            folderDownloadResult: .success(
                FolderDownloadResultEntity(isSuccess: false, fileCount: 5, downloadedFileCount: 3)
            )
        )

        await #expect(throws: ExportFileErrorEntity.self) {
            try await sut.export(node: folderNode)
        }
    }

    /// The counts still say how much was expected, which is what makes this different from a folder that
    /// never got as far as being scanned.
    @Test("a folder none of whose files arrived reports the shortfall and nothing to hand over")
    func exportFolder_nothingArrived_reportsCountsWithoutURL() async throws {
        let fileSystem = MockFileSystemRepository()
        let sut = makeSUT(
            fileSystemRepository: fileSystem,
            folderDownloadResult: .success(
                FolderDownloadResultEntity(isSuccess: false, fileCount: 5, downloadedFileCount: 0)
            )
        )

        let exported = try await sut.exportFolder(folderNode)

        #expect(exported == ExportedNodeEntity(url: nil, fileCount: 5, downloadedFileCount: 0))
        #expect(fileSystem.removeFileURLs.contains(Self.stagingFolderURL))
    }

    /// Reported as zero of zero rather than guessed at, leaving the caller to speak about the folder itself.
    @Test("a folder whose transfer never ran reports no counts at all")
    func exportFolder_transferNeverRan_reportsNoCounts() async throws {
        let sut = makeSUT(folderDownloadResult: .failure(.couldNotFindNodeByHandle))

        let exported = try await sut.exportFolder(folderNode)

        #expect(exported == ExportedNodeEntity(url: nil, fileCount: 0, downloadedFileCount: 0))
    }

    /// A user who stopped it themselves has nothing to be told, so this stays an error rather than becoming
    /// a shortfall reported back at them.
    @Test("a cancelled folder download throws instead of reporting a shortfall")
    func exportFolder_cancelled_throws() async {
        let fileSystem = MockFileSystemRepository()
        let sut = makeSUT(fileSystemRepository: fileSystem, folderDownloadResult: .failure(.cancelled))

        await #expect(throws: ExportFileErrorEntity.self) {
            try await sut.exportFolder(folderNode)
        }
        #expect(fileSystem.removeFileURLs.contains(Self.stagingFolderURL))
    }

    /// A cached copy is only ever a finished one, so its files are all present. Counting them is what keeps
    /// a folder that skipped its download from taking its files out of a selection's totals.
    @Test("a cached folder is counted by the files in it, none of them missing")
    func exportFolder_cachedCopy_countsItsFiles() async throws {
        let sut = makeSUT(
            fileCacheRepository: MockFileCacheRepository(
                base64Handle: Self.base64Handle,
                name: Self.folderName,
                tempFolder: Self.tempFolder
            ),
            fileSystemRepository: MockFileSystemRepository(fileCount: 10)
        )

        let exported = try await sut.exportFolder(folderNode)

        #expect(exported == ExportedNodeEntity(url: Self.destinationURL, fileCount: 10, downloadedFileCount: 10))
        #expect(exported.requestedFileCount == exported.downloadedFileCount, "Nothing is missing from a cache hit.")
    }

    /// The warning speaks in files, so a cached folder that said nothing about its own would have the batch
    /// report that nothing was downloaded while ten of its files are being handed over.
    @Test("a cached folder still counts towards what a batch downloaded when another node fails")
    func exportNodes_cachedFolderAndFailedFile_countsTheCachedFiles() async throws {
        let sut = makeSUT(
            fileCacheRepository: MockFileCacheRepository(
                base64Handle: Self.base64Handle,
                name: Self.folderName,
                cachedNodeNames: [Self.folderName],
                tempFolder: Self.tempFolder
            ),
            fileSystemRepository: MockFileSystemRepository(fileCount: 10),
            downloadResult: .failure(.download)
        )

        let selection = try await sut.export(nodes: [folderNode, fileNode])

        #expect(selection.downloadedFileCount == 10, "The cached folder's ten files did arrive.")
        #expect(selection.requestedFileCount == 11, "Those ten, plus the file that failed.")
    }

    /// The point of counting a selection in files: the folder contributes what it holds, not the one node it
    /// was picked as.
    @Test("a selection counts a folder by its files and a file by itself")
    func exportNodes_countsFolderByItsFiles() async throws {
        let sut = makeSUT(
            fileSystemRepository: MockFileSystemRepository(movedNode: true),
            downloadResult: .success(TransferEntity(path: Self.fileURL.path)),
            folderDownloadResult: .success(
                FolderDownloadResultEntity(isSuccess: false, fileCount: 5, downloadedFileCount: 3)
            ),
            handsOverIncompleteFolders: true
        )

        let selection = try await sut.export(nodes: [fileNode, folderNode])

        #expect(selection.requestedFileCount == 6, "One file plus the folder's five.")
        #expect(selection.downloadedFileCount == 4, "The file, plus three of the folder's five.")
        #expect(
            Set(selection.urls) == Set([Self.fileURL, Self.stagingURL]),
            "Both the file and the incomplete folder are worth handing over. Completion order is not fixed."
        )
    }

    /// Counts that disagree must not be able to invent spare deliveries: a selection adds both fields up,
    /// so a node reporting more arrived than asked for would cover up a sibling's shortfall.
    @Test("a node never counts as having asked for less than what arrived")
    func requestedFileCount_isNeverBelowWhatArrived() {
        let node = ExportedNodeEntity(url: Self.fileURL, fileCount: 0, downloadedFileCount: 7)

        #expect(node.requestedFileCount == 7)

        let selection = ExportedSelectionEntity.nothing
            .adding(node)
            .adding(ExportedNodeEntity(url: nil, fileCount: 3, downloadedFileCount: 0))

        #expect(
            selection.downloadedFileCount < selection.requestedFileCount,
            "The sibling's three missing files must still read as a shortfall."
        )
    }

    /// Otherwise one unreachable node would take the whole selection down with it.
    @Test("a node of a selection that produced nothing counts as one file missing, and the rest survives")
    func exportNodes_failedNode_countsAsOneMissing() async throws {
        let sut = makeSUT(downloadResult: .failure(.download))

        let selection = try await sut.export(nodes: [fileNode])

        #expect(selection == ExportedSelectionEntity(urls: [], requestedFileCount: 1, downloadedFileCount: 0))
    }

    @Test("a selection that arrived whole reports no shortfall")
    func exportNodes_complete_reportsNoShortfall() async throws {
        let sut = makeSUT(downloadResult: .success(TransferEntity(path: Self.fileURL.path)))

        let selection = try await sut.export(nodes: [fileNode, fileNode])

        #expect(selection.requestedFileCount == 2)
        #expect(selection.downloadedFileCount == 2)
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
            folderDownloadResult: .failure(.download)
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
            folderDownloadResult: .success(Self.wholeFolder)
        )

        let url = try await sut.export(node: folderNode)

        #expect(url == Self.destinationURL, "The stale record must not short circuit the download.")
    }

    private static let fileURL = tempFolder.appendingPathComponent("MyFile")

    private var folderNode: NodeEntity {
        NodeEntity(name: Self.folderName, base64Handle: Self.base64Handle, isFolder: true)
    }

    private var fileNode: NodeEntity {
        NodeEntity(name: "MyFile", base64Handle: Self.base64Handle, isFile: true)
    }

    private static let wholeFolder = FolderDownloadResultEntity(
        isSuccess: true,
        fileCount: 4,
        downloadedFileCount: 4
    )

    private func makeSUT(
        fileCacheRepository: MockFileCacheRepository = MockFileCacheRepository(
            base64Handle: base64Handle,
            name: folderName,
            hasExistingTempFile: false,
            tempFolder: tempFolder
        ),
        fileSystemRepository: MockFileSystemRepository = MockFileSystemRepository(),
        offlineFileFetcherRepository: MockOfflineFileFetcherRepository = MockOfflineFileFetcherRepository(),
        downloadResult: Result<TransferEntity, TransferErrorEntity> = .failure(.download),
        folderDownloadResult: Result<FolderDownloadResultEntity, TransferErrorEntity> = .failure(.download),
        handsOverIncompleteFolders: Bool = false
    ) -> some ExportFileUseCaseProtocol {
        ExportFileUseCase(
            downloadFileRepository: MockDownloadFileRepository(
                completionResult: downloadResult,
                folderDownloadResult: folderDownloadResult
            ),
            offlineFilesRepository: MockOfflineFilesRepository(),
            fileCacheRepository: fileCacheRepository,
            thumbnailRepository: MockThumbnailRepository(),
            fileSystemRepository: fileSystemRepository,
            exportChatMessagesRepository: MockExportChatMessagesRepository(),
            importNodeRepository: MockImportNodeRepository(),
            megaHandleRepository: MockMEGAHandleRepository(),
            mediaUseCase: MockMediaUseCase(),
            offlineFileFetcherRepository: offlineFileFetcherRepository,
            userStoreRepository: MockUserStoreRepository(),
            handsOverIncompleteFolders: handsOverIncompleteFolders
        )
    }
}
