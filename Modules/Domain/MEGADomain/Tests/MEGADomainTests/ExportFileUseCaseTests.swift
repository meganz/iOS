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

        let exported = try await sut.export(node: folderNode)

        #expect(exported.urls == [Self.destinationURL], "The caller must get the final path, never the staging one.")
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

        let exported = try await sut.export(node: folderNode)

        #expect(exported.urls == [Self.stagingURL])
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

        #expect(exported == ExportedSelectionEntity(urls: [Self.destinationURL], requestedFileCount: 4, downloadedFileCount: 4))
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

        #expect(exported == ExportedSelectionEntity(urls: [Self.stagingURL], requestedFileCount: 5, downloadedFileCount: 3))
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

        #expect(exported.urls.isEmpty)
        #expect(exported.downloadedFileCount == 0, "Nothing was delivered once the partial tree was deleted.")
        #expect(exported.requestedFileCount == 5, "How much was expected is still worth reporting.")
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

        #expect(exported == ExportedSelectionEntity(urls: [], requestedFileCount: 5, downloadedFileCount: 0))
        #expect(fileSystem.removeFileURLs.contains(Self.stagingFolderURL))
    }

    /// Reported as zero of zero rather than guessed at, leaving the caller to speak about the folder itself.
    @Test("a folder whose transfer never ran reports no counts at all")
    func exportFolder_transferNeverRan_reportsNoCounts() async throws {
        let sut = makeSUT(folderDownloadResult: .failure(.couldNotFindNodeByHandle))

        let exported = try await sut.exportFolder(folderNode)

        // No file count came back, so the folder speaks for itself: one thing asked for, none delivered.
        #expect(exported == ExportedSelectionEntity(urls: [], requestedFileCount: 1, downloadedFileCount: 0))
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

        #expect(exported == ExportedSelectionEntity(urls: [Self.destinationURL], requestedFileCount: 10, downloadedFileCount: 10))
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

        let exported = try await sut.export(node: NodeEntity(name: "elcapitan.jpeg", isFile: true))

        #expect(exported.urls == [Self.destinationURL])
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

        let exported = try await sut.export(node: folderNode)

        #expect(exported.urls == [Self.destinationURL], "Downloading would have failed, so this can only be the cache.")
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

        let exported = try await sut.export(node: folderNode)

        #expect(exported.urls == [Self.destinationURL], "The stale record must not short circuit the download.")
    }

    // MARK: - Batch download path

    /// The whole point of the batch: the selection is one transfer, so the transfer quota is checked once
    /// and the user is asked about it once.
    @Test("a selection goes down as a single batch, one item per node")
    func batch_selection_isOneBatchWithOneItemPerNode() async throws {
        let repository = MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 5))
        let sut = makeBatchSUT(repository: repository)

        _ = try await sut.export(nodes: [folderNode, fileNode])

        #expect(repository.startedDownloadBatches.count == 1, "Two batches would mean two quota checks.")
        #expect(repository.startedDownloadBatches.first?.count == 2)
    }

    /// One directory for the whole selection, and the SDK names each item after its own node. Naming them
    /// here instead would take the deduplication of two nodes sharing a name away from it.
    @Test("every node of a batch is downloaded into this export's own directory")
    func batch_itemsGoIntoTheExportFolder() async throws {
        let repository = MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 2))
        let sut = makeBatchSUT(repository: repository)

        _ = try await sut.export(nodes: [folderNode, fileNode])

        let batch = try #require(repository.startedDownloadBatches.first)
        #expect(batch.allSatisfy { $0.destination == .folder(Self.tempExportFolder) })
    }

    /// The share sheet only opens once the download is over, so a second export can be started over the
    /// top of one that is still running. Clearing anything shared would delete the files the first one is
    /// still fetching, and leave it handing over the second one's.
    @Test("an export clears nothing another export could be filling")
    func batch_clearsNothingShared() async throws {
        let fileSystem = MockFileSystemRepository(directoryContents: [Self.exportedFileURL])
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 1)),
            fileSystemRepository: fileSystem
        )

        let selection = try await sut.export(nodes: [fileNode])

        #expect(fileSystem.removeFolderContents_calledTimes == 0)
        #expect(fileSystem.removeFileURLs.isEmpty, "Nothing recent enough to still be in use may be removed.")
        #expect(
            selection.temporaryFolder == Self.tempExportFolder,
            "Clearing it is the caller's to do, once the user is done with what was handed over."
        )
    }

    /// Its own folder and nothing else: the name is unique to the export, so no other export is reading it.
    @Test("an export that produced nothing clears its own folder")
    func batch_nothingProduced_clearsOwnFolder() async throws {
        let fileSystem = MockFileSystemRepository()
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .failed),
            fileSystemRepository: fileSystem
        )

        let selection = try await sut.export(nodes: [fileNode])

        #expect(fileSystem.removeFileURLs == [Self.tempExportFolder])
        #expect(selection.temporaryFolder == nil, "There is nothing left for the caller to clear.")
    }

    /// One URL per node, whatever is inside it: a folder is one thing to hand over, so the directory is
    /// read one level deep and no further.
    @Test("what is handed over is the top level of the export directory")
    func batch_handsOverTheTopLevelOfTheExportFolder() async throws {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 6)),
            fileSystemRepository: MockFileSystemRepository(
                directoryContents: [Self.exportedFolderURL, Self.exportedFileURL]
            )
        )

        let selection = try await sut.export(nodes: [folderNode, fileNode])

        #expect(selection.urls == [Self.exportedFolderURL, Self.exportedFileURL])
    }

    /// Both counts come from the transfer, so a folder is counted by the files inside it and a file by
    /// itself, without the use case having to know which item a file transfer belonged to.
    @Test("a batch is counted by the file transfers it ran")
    func batch_countsTheFileTransfers() async throws {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .partiallyFailed(downloadedFileCount: 4, failedFileCount: 2)),
            fileSystemRepository: MockFileSystemRepository(directoryContents: [Self.exportedFolderURL])
        )

        let selection = try await sut.export(nodes: [fileNode, folderNode])

        #expect(selection.requestedFileCount == 6, "One file plus the folder's five.")
        #expect(selection.downloadedFileCount == 4)
    }

    /// An empty folder downloads no files at all, which is not the same as failing to download any. The
    /// SDK still creates its directory, so it is there to be handed over and nothing is missing.
    @Test("an empty folder is handed over rather than reported as failed")
    func batch_emptyFolder_isHandedOver() async throws {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 0)),
            fileSystemRepository: MockFileSystemRepository(directoryContents: [Self.exportedFolderURL])
        )

        let exported = try await sut.exportFolder(folderNode)

        #expect(
            exported == ExportedSelectionEntity(
                urls: [Self.exportedFolderURL],
                requestedFileCount: 0,
                downloadedFileCount: 0,
                temporaryFolder: Self.tempExportFolder
            )
        )
        #expect(exported.requestedFileCount == 0, "An empty folder asks for nothing, so nothing is missing.")
    }

    /// The batch never reached it, so it ran no transfer to count and left nothing on disk to hand over.
    /// The node is then left to speak for itself: one thing asked for, and not delivered.
    @Test("a node the batch never reached counts as one file missing")
    func batch_nodeNeverReached_countsAsOneMissing() async throws {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .failed)
        )

        let exported = try await sut.exportFolder(folderNode)

        #expect(exported.urls.isEmpty)
        #expect(exported.requestedFileCount == 1)
        #expect(exported.downloadedFileCount == 0)
    }

    /// Nothing is reused: a cached folder can be one an earlier export left half downloaded, and nothing
    /// on disk tells that apart from a finished one.
    @Test("a cached node is downloaded again rather than reused")
    func batch_cachedNode_isDownloadedAgain() async throws {
        let repository = MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 1))
        let sut = makeBatchSUT(
            repository: repository,
            fileCacheRepository: MockFileCacheRepository(
                base64Handle: Self.base64Handle,
                name: Self.folderName,
                cachedNodeNames: [Self.folderName],
                tempFolder: Self.tempFolder
            ),
            fileSystemRepository: MockFileSystemRepository(
                fileExists: true,
                fileCount: 10,
                directoryContents: [Self.exportedFolderURL]
            )
        )

        let selection = try await sut.export(nodes: [folderNode])

        #expect(repository.startedDownloadBatches.first?.count == 1, "The cached copy must not short circuit the download.")
        #expect(selection.urls == [Self.exportedFolderURL], "The cached copy must not be handed over.")
    }

    /// Every item carries it, so the transfer shows up under the export's own entry in the transfer manager.
    @Test("every item of the batch is tagged as an export")
    func batch_itemsAreTaggedAsExport() async throws {
        let repository = MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 2))
        let sut = makeBatchSUT(repository: repository)

        _ = try await sut.export(nodes: [fileNode, fileNode])

        let batch = try #require(repository.startedDownloadBatches.first)
        #expect(batch.allSatisfy { $0.appData == TransferMetaDataEntity.exportFile.rawValue })
    }

    /// Nothing to download, so nothing to start.
    @Test("an empty selection starts no batch")
    func batch_emptySelection_startsNoBatch() async throws {
        let repository = MockDownloadFileRepository()
        let sut = makeBatchSUT(repository: repository)

        let selection = try await sut.export(nodes: [])

        #expect(repository.startedDownloadBatches.isEmpty)
        #expect(selection == .nothing)
    }

    /// A single node that produced nothing has no URL to hand back, and this entry point deals in URLs.
    @Test("exporting a lone node that produced nothing throws")
    func batch_singleNodeWithNothingToHandOver_throws() async {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .partiallyFailed(downloadedFileCount: 0, failedFileCount: 1))
        )

        await #expect(throws: ExportFileErrorEntity.downloadFailed) {
            _ = try await sut.export(node: fileNode)
        }
    }

    /// A user who stopped it themselves has nothing to be told, so this stays an error rather than becoming
    /// a shortfall reported back at them.
    @Test("a cancelled batch throws instead of reporting a shortfall")
    func batch_cancelled_throws() async {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(downloadBatchEventsError: TransferErrorEntity.cancelled)
        )

        await #expect(throws: TransferErrorEntity.cancelled) {
            _ = try await sut.export(nodes: [fileNode])
        }
    }

    /// The SDK builds a folder's directory tree before downloading anything into it, so a folder none of
    /// whose files arrived still leaves a directory behind. Handing that over offers the user an empty
    /// folder, which is worse than offering nothing.
    @Test("a folder that arrived empty is not handed over, even to a caller that can report the shortfall")
    func batch_incompleteFolderWithNothingDownloaded_isNotHandedOver() async throws {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .partiallyFailed(downloadedFileCount: 0, failedFileCount: 5)),
            fileSystemRepository: MockFileSystemRepository(directoryContents: [Self.exportedFolderURL]),
            handsOverIncompleteFolders: true
        )

        let exported = try await sut.exportFolder(folderNode)

        #expect(exported.urls.isEmpty, "Nothing arrived, so there is nothing to hand over.")
        #expect(exported.requestedFileCount == 5)
        #expect(exported.downloadedFileCount == 0)
    }

    /// A cached file is no more trusted than a cached folder: it goes into the batch like anything else, so
    /// what is handed over is always a copy this export fetched itself.
    @Test("a cached file is downloaded again rather than reused")
    func batch_cachedFile_isDownloadedAgain() async throws {
        let repository = MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 1))
        let sut = makeBatchSUT(
            repository: repository,
            fileCacheRepository: MockFileCacheRepository(
                base64Handle: Self.base64Handle,
                name: Self.fileName,
                cachedNodeNames: [Self.fileName],
                tempFolder: Self.tempFolder
            ),
            fileSystemRepository: MockFileSystemRepository(directoryContents: [Self.exportedFileURL])
        )

        let selection = try await sut.export(nodes: [fileNode])

        #expect(repository.startedDownloadBatches.first?.count == 1, "The cached copy must not short circuit the download.")
        #expect(selection.urls == [Self.exportedFileURL], "The cached copy must not be handed over.")
        #expect(selection.requestedFileCount == 1)
        #expect(selection.downloadedFileCount == 1)
    }

    /// Whether a node has a cached copy or not makes no difference to what the batch is asked for, so the
    /// whole selection goes down as one transfer and is counted by it alone.
    @Test("every node of a selection goes into the batch, cached copy or not")
    func batch_cachedAndUncachedFiles_bothGoIntoTheBatch() async throws {
        let repository = MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 2))
        let sut = makeBatchSUT(
            repository: repository,
            fileCacheRepository: MockFileCacheRepository(
                base64Handle: Self.base64Handle,
                name: Self.fileName,
                cachedNodeNames: [Self.fileName],
                tempFolder: Self.tempFolder
            ),
            fileSystemRepository: MockFileSystemRepository(directoryContents: [Self.exportedFileURL])
        )

        let selection = try await sut.export(nodes: [fileNode, uncachedFileNode])

        #expect(repository.startedDownloadBatches.first?.count == 2, "Both nodes go into the batch.")
        #expect(selection.urls == [Self.exportedFileURL])
        #expect(selection.requestedFileCount == 2)
        #expect(selection.downloadedFileCount == 2)
    }

    /// A batch that never got going leaves nothing on disk, and nothing was held back from it either, so
    /// every node of the selection is one thing asked for and not delivered.
    @Test("a failed batch counts every node of the selection as missing")
    func batch_failedBatch_countsEveryNodeAsMissing() async throws {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .failed),
            fileCacheRepository: MockFileCacheRepository(
                base64Handle: Self.base64Handle,
                name: Self.fileName,
                cachedNodeNames: [Self.fileName],
                tempFolder: Self.tempFolder
            )
        )

        let selection = try await sut.export(nodes: [fileNode, uncachedFileNode])

        #expect(selection.urls.isEmpty, "The cached copy is not a substitute for what the batch did not fetch.")
        #expect(selection.requestedFileCount == 2)
        #expect(selection.downloadedFileCount == 0)
    }

    // MARK: - Clean up

    @Test("cleaning up removes the folder the export downloaded into")
    func cleanUp_removesTheTemporaryFolder() async {
        let fileSystem = MockFileSystemRepository()
        let sut = makeBatchSUT(repository: MockDownloadFileRepository(), fileSystemRepository: fileSystem)

        await sut.cleanUp(for: Self.selectionWithFolder)

        #expect(fileSystem.removeFileURLs == [Self.tempExportFolder])
    }

    /// The legacy path downloads into the shared cache, which later exports read, so a selection from it
    /// carries no folder and nothing here may be removed.
    @Test("a selection with no folder of its own has nothing removed")
    func cleanUp_withoutTemporaryFolder_removesNothing() async {
        let fileSystem = MockFileSystemRepository()
        let sut = makeBatchSUT(repository: MockDownloadFileRepository(), fileSystemRepository: fileSystem)

        await sut.cleanUp(
            for: ExportedSelectionEntity(urls: [Self.exportedFileURL], requestedFileCount: 1, downloadedFileCount: 1)
        )

        #expect(fileSystem.removeFileURLs.isEmpty)
    }

    /// Nobody is waiting on the removal by the time it runs — the files have already been handed over — so
    /// a failure is logged rather than raised at a caller that can do nothing about it.
    @Test("a removal that fails is attempted and then let go")
    func cleanUp_whenRemovalFails_isAttemptedAndLetGo() async {
        let fileSystem = MockFileSystemRepository(removeItemError: TransferErrorEntity.generic)
        let sut = makeBatchSUT(repository: MockDownloadFileRepository(), fileSystemRepository: fileSystem)

        await sut.cleanUp(for: Self.selectionWithFolder)

        #expect(fileSystem.removeFileURLs == [Self.tempExportFolder], "The removal still has to be asked for.")
    }

    /// The view model cleans up on a path where the task has just been cancelled, so this must not be the
    /// kind of work that gives up on cancellation. That the removal itself survives cancellation is covered
    /// by `FileSystemRepositoryTests.removeItem_whenCallingTaskIsCancelled_stillRemovesTheItem`.
    @Test("cleaning up still asks for the removal from a cancelled task")
    func cleanUp_fromACancelledTask_stillAsksForTheRemoval() async {
        let fileSystem = MockFileSystemRepository()
        let sut = makeBatchSUT(repository: MockDownloadFileRepository(), fileSystemRepository: fileSystem)

        let task = Task {
            // Held until the cancellation has landed, so the call below is made from a cancelled task
            // rather than from one that merely will be.
            while !Task.isCancelled {
                await Task.yield()
            }
            await sut.cleanUp(for: Self.selectionWithFolder)
        }
        task.cancel()
        await task.value

        #expect(fileSystem.removeFileURLs == [Self.tempExportFolder])
    }

    // MARK: - Chat messages, batch path

    /// The point of the batch for a chat selection too: every attachment goes down as one transfer, so the
    /// transfer quota is checked once however many files were picked.
    @Test("every chat attachment goes down as one batch of chat nodes")
    func batchChat_attachments_goDownAsOneBatchOfChatNodes() async throws {
        let repository = MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 2))
        let sut = makeBatchSUT(repository: repository)

        _ = await sut.export(messages: [Self.attachmentMessage, Self.voiceClipMessage], chatId: Self.chatId)

        #expect(repository.startedDownloadBatches.count == 1, "Two batches would mean two quota checks.")
        let batch = try #require(repository.startedDownloadBatches.first)
        #expect(batch.count == 2)
        #expect(
            batch.compactMap(Self.chatNodeSource) == [
                ChatNodeSource(handle: Self.attachmentHandle, messageId: Self.messageId, chatId: Self.chatId),
                ChatNodeSource(handle: Self.voiceClipHandle, messageId: Self.voiceClipMessageId, chatId: Self.chatId)
            ],
            "A chat attachment is only reachable through the message it was attached to."
        )
        #expect(batch.allSatisfy { $0.destination == .folder(Self.tempExportFolder) })
        #expect(batch.allSatisfy { $0.appData == TransferMetaDataEntity.exportFile.rawValue })
    }

    /// A chat selection can mix files with messages that are not files at all. Those are written out here
    /// rather than downloaded, so they cannot go into the batch and are gathered alongside it.
    @Test("messages that are not attachments are exported alongside the batch")
    func batchChat_nonAttachments_areExportedAlongsideTheBatch() async {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 1)),
            fileSystemRepository: MockFileSystemRepository(directoryContents: [Self.exportedFileURL]),
            exportChatMessagesRepository: MockExportChatMessagesRepository(textURL: Self.exportedTextURL)
        )

        let selection = await sut.export(
            messages: [Self.attachmentMessage, Self.textMessage],
            chatId: Self.chatId
        )

        #expect(
            selection.urls == [Self.exportedFileURL, Self.exportedTextURL],
            "The batch's files come first, then whatever was written out."
        )
    }

    /// The batch and the other messages fail independently, so one taking the whole selection down with it
    /// would lose text the app had already written out.
    @Test("a batch that failed still lets the other messages through")
    func batchChat_failedBatch_stillExportsTheOtherMessages() async {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(downloadBatchEventsError: TransferErrorEntity.generic),
            exportChatMessagesRepository: MockExportChatMessagesRepository(textURL: Self.exportedTextURL)
        )

        let selection = await sut.export(
            messages: [Self.attachmentMessage, Self.textMessage],
            chatId: Self.chatId
        )

        #expect(selection.urls == [Self.exportedTextURL])
        #expect(selection.temporaryFolder == nil, "A batch that threw handed no folder back to clear.")
    }

    /// Counted in messages rather than in the files the batch ran, because a chat selection is picked as
    /// messages and a message that produced nothing is the shortfall worth reporting.
    @Test("a chat selection is counted in messages asked for against what was handed over")
    func batchChat_countsMessagesAgainstWhatWasHandedOver() async {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 1)),
            fileSystemRepository: MockFileSystemRepository(directoryContents: [Self.exportedFileURL])
        )

        // The text message produces nothing: no URL was set up for it.
        let selection = await sut.export(
            messages: [Self.attachmentMessage, Self.textMessage],
            chatId: Self.chatId
        )

        #expect(selection.requestedFileCount == 2)
        #expect(selection.downloadedFileCount == 1)
        #expect(selection.urls == [Self.exportedFileURL])
    }

    @Test("the folder to clear comes from the batch the attachments went down as")
    func batchChat_temporaryFolder_comesFromTheBatch() async {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 1)),
            fileSystemRepository: MockFileSystemRepository(directoryContents: [Self.exportedFileURL])
        )

        let selection = await sut.export(messages: [Self.attachmentMessage], chatId: Self.chatId)

        #expect(selection.temporaryFolder == Self.tempExportFolder)
    }

    /// Nothing to download, so nothing to start — and no folder handed back for a caller to clear.
    @Test("a chat selection holding no attachment starts no batch")
    func batchChat_noAttachments_startsNoBatch() async {
        let repository = MockDownloadFileRepository()
        let sut = makeBatchSUT(
            repository: repository,
            exportChatMessagesRepository: MockExportChatMessagesRepository(textURL: Self.exportedTextURL)
        )

        let selection = await sut.export(messages: [Self.textMessage], chatId: Self.chatId)

        #expect(repository.startedDownloadBatches.isEmpty)
        #expect(selection.urls == [Self.exportedTextURL])
        #expect(selection.temporaryFolder == nil)
    }

    @Test("one message's node goes down as a batch of that one chat node")
    func batchChat_singleNode_goesDownAsAChatNodeBatch() async throws {
        let repository = MockDownloadFileRepository(batchDownloadResult: .completed(fileCount: 1))
        let sut = makeBatchSUT(
            repository: repository,
            fileSystemRepository: MockFileSystemRepository(directoryContents: [Self.exportedFileURL])
        )

        let selection = try await sut.exportNode(
            Self.attachmentNode,
            messageId: Self.messageId,
            chatId: Self.chatId
        )

        let item = try #require(repository.startedDownloadBatches.first?.first)
        #expect(
            Self.chatNodeSource(item)
                == ChatNodeSource(handle: Self.attachmentHandle, messageId: Self.messageId, chatId: Self.chatId)
        )
        #expect(selection.urls == [Self.exportedFileURL])
        #expect(selection.temporaryFolder == Self.tempExportFolder)
    }

    /// This entry point deals in one file, so a batch that produced nothing has no URL to hand back and
    /// saying so is all it can do.
    @Test("one message's node producing nothing throws")
    func batchChat_singleNode_withNothingToHandOver_throws() async {
        let sut = makeBatchSUT(repository: MockDownloadFileRepository(batchDownloadResult: .failed))

        await #expect(throws: ExportFileErrorEntity.downloadFailed) {
            _ = try await sut.exportNode(Self.attachmentNode, messageId: Self.messageId, chatId: Self.chatId)
        }
    }

    /// With the flag off the old path has to stay exactly as it was: the node is imported into the
    /// account's chat files folder first, and downloaded from there.
    @Test("with the batch off, a message's node still goes through the import")
    func legacyChat_singleNode_stillGoesThroughTheImport() async throws {
        let sut = makeSUT(
            importNodeRepository: MockImportNodeRepository(result: .success(Self.attachmentNode)),
            downloadResult: .success(TransferEntity(path: Self.exportedFileURL.path))
        )

        let selection = try await sut.exportNode(
            Self.attachmentNode,
            messageId: Self.messageId,
            chatId: Self.chatId
        )

        #expect(selection.urls == [Self.exportedFileURL])
    }

    /// Said by making the import the only thing that fails: the download would have succeeded, so a throw
    /// can only mean the legacy path still asks the import first.
    @Test("with the batch off, a message's node that cannot be imported is not downloaded")
    func legacyChat_singleNode_failedImport_throws() async {
        let sut = makeSUT(
            importNodeRepository: MockImportNodeRepository(result: .failure(TransferErrorEntity.couldNotFindNodeByHandle)),
            downloadResult: .success(TransferEntity(path: Self.exportedFileURL.path))
        )

        await #expect(throws: (any Error).self) {
            _ = try await sut.exportNode(Self.attachmentNode, messageId: Self.messageId, chatId: Self.chatId)
        }
    }

    // MARK: - Cancellation, batch path

    /// A user who stopped it themselves has nothing to be told, so the cancellation travels rather than
    /// becoming a shortfall reported back at them.
    @Test("a chat selection whose batch was cancelled reports no shortfall of its own")
    func batchChat_cancelledBatch_handsOverOnlyWhatWasWrittenOut() async {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(downloadBatchEventsError: CancellationError()),
            exportChatMessagesRepository: MockExportChatMessagesRepository(textURL: Self.exportedTextURL)
        )

        let selection = await sut.export(
            messages: [Self.attachmentMessage, Self.textMessage],
            chatId: Self.chatId
        )

        #expect(selection.urls == [Self.exportedTextURL])
        #expect(selection.temporaryFolder == nil)
    }

    @Test("a cancelled batch of nodes throws rather than reporting what is missing")
    func batch_cancelledNodes_throws() async {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(downloadBatchEventsError: CancellationError())
        )

        await #expect(throws: CancellationError.self) {
            _ = try await sut.export(nodes: [fileNode])
        }
    }

    @Test("a cancelled batch behind one message's node throws")
    func batchChat_singleNode_cancelled_throws() async {
        let sut = makeBatchSUT(
            repository: MockDownloadFileRepository(downloadBatchEventsError: CancellationError())
        )

        await #expect(throws: CancellationError.self) {
            _ = try await sut.exportNode(Self.attachmentNode, messageId: Self.messageId, chatId: Self.chatId)
        }
    }

    /// The calling task going away leaves the SDK's transfers running: only the repository's cancel token
    /// stops them, and the export is the only thing that knows its batch is the one to stop.
    @Test("a cancelled batch stops the transfers it started")
    func batch_cancelledNodes_cancelsTheDownloadTransfers() async {
        let repository = MockDownloadFileRepository(downloadBatchEventsError: CancellationError())
        let sut = makeBatchSUT(repository: repository)

        await #expect(throws: CancellationError.self) {
            _ = try await sut.export(nodes: [fileNode])
        }

        #expect(repository.cancelDownloadTransfers_calledTimes == 1)
    }

    /// A batch that failed on its own is already over, so stopping the transfers would only cancel whatever
    /// the token is shared with next.
    @Test("a batch that failed for another reason leaves the transfers alone")
    func batch_failedNodes_doesNotCancelTheDownloadTransfers() async {
        let repository = MockDownloadFileRepository(downloadBatchEventsError: TransferErrorEntity.download)
        let sut = makeBatchSUT(repository: repository)

        await #expect(throws: TransferErrorEntity.download) {
            _ = try await sut.export(nodes: [fileNode])
        }

        #expect(repository.cancelDownloadTransfers_calledTimes == 0)
    }

    // MARK: - Chat fixtures

    private static let chatId: HandleEntity = 55
    private static let messageId: HandleEntity = 77
    private static let attachmentHandle: HandleEntity = 99
    private static let voiceClipMessageId: HandleEntity = 78
    private static let voiceClipHandle: HandleEntity = 100
    private static let exportedTextURL = tempFolder.appendingPathComponent("message.txt")
    private static let selectionWithFolder = ExportedSelectionEntity(
        urls: [exportedFileURL],
        requestedFileCount: 1,
        downloadedFileCount: 1,
        temporaryFolder: tempExportFolder
    )

    private static let attachmentNode = NodeEntity(
        name: fileName,
        handle: attachmentHandle,
        base64Handle: base64Handle,
        isFile: true
    )

    private static let attachmentMessage = ChatMessageEntity(
        messageId: messageId,
        type: .attachment,
        nodes: [attachmentNode]
    )

    private static let voiceClipMessage = ChatMessageEntity(
        messageId: voiceClipMessageId,
        type: .voiceClip,
        nodes: [NodeEntity(name: "clip.m4a", handle: voiceClipHandle, base64Handle: base64Handle, isFile: true)]
    )

    private static let textMessage = ChatMessageEntity(messageId: 79, type: .normal)

    /// What the item names, for a source that has no `Equatable` of its own to compare against.
    private struct ChatNodeSource: Equatable {
        let handle: HandleEntity
        let messageId: HandleEntity
        let chatId: HandleEntity
    }

    private static func chatNodeSource(_ item: DownloadBatchItemEntity) -> ChatNodeSource? {
        guard case let .chatNode(handle, messageId, chatId) = item.source else { return nil }
        return ChatNodeSource(handle: handle, messageId: messageId, chatId: chatId)
    }

    private static let exportFolder = tempFolder.appendingPathComponent("ExportFile")
    /// What `MockFileCacheRepository` hands out as one export's own directory.
    private static let tempExportFolder = exportFolder.appendingPathComponent("run")
    private static let exportedFileURL = exportFolder.appendingPathComponent("MyFile")
    private static let exportedFolderURL = exportFolder.appendingPathComponent(folderName)

    private func makeBatchSUT(
        repository: MockDownloadFileRepository,
        fileCacheRepository: MockFileCacheRepository = MockFileCacheRepository(
            base64Handle: base64Handle,
            name: folderName,
            hasExistingTempFile: false,
            tempFolder: tempFolder
        ),
        fileSystemRepository: MockFileSystemRepository = MockFileSystemRepository(),
        exportChatMessagesRepository: MockExportChatMessagesRepository = MockExportChatMessagesRepository(),
        handsOverIncompleteFolders: Bool = false
    ) -> some ExportFileUseCaseProtocol {
        ExportFileUseCase(
            downloadFileRepository: repository,
            offlineFilesRepository: MockOfflineFilesRepository(),
            fileCacheRepository: fileCacheRepository,
            thumbnailRepository: MockThumbnailRepository(),
            fileSystemRepository: fileSystemRepository,
            exportChatMessagesRepository: exportChatMessagesRepository,
            importNodeRepository: MockImportNodeRepository(),
            megaHandleRepository: MockMEGAHandleRepository(),
            mediaUseCase: MockMediaUseCase(),
            offlineFileFetcherRepository: MockOfflineFileFetcherRepository(),
            userStoreRepository: MockUserStoreRepository(),
            handsOverIncompleteFolders: handsOverIncompleteFolders,
            isBatchDownloadEnabled: true
        )
    }

    private static let fileName = "MyFile"
    private static let fileURL = tempFolder.appendingPathComponent(fileName)

    private var folderNode: NodeEntity {
        NodeEntity(name: Self.folderName, base64Handle: Self.base64Handle, isFolder: true)
    }

    private var fileNode: NodeEntity {
        NodeEntity(name: Self.fileName, base64Handle: Self.base64Handle, isFile: true)
    }

    /// A second file, named so that a cache set up for `fileNode` does not answer for it too.
    private var uncachedFileNode: NodeEntity {
        NodeEntity(name: "OtherFile", base64Handle: Self.base64Handle, isFile: true)
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
        importNodeRepository: MockImportNodeRepository = MockImportNodeRepository(),
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
            importNodeRepository: importNodeRepository,
            megaHandleRepository: MockMEGAHandleRepository(),
            mediaUseCase: MockMediaUseCase(),
            offlineFileFetcherRepository: offlineFileFetcherRepository,
            userStoreRepository: MockUserStoreRepository(),
            handsOverIncompleteFolders: handsOverIncompleteFolders,
            // Said rather than inherited: `BatchDownloadFeatureFlag.isEnabled` is process wide state that
            // another suite in this target turns on, and these tests cover the path taken when it is off.
            isBatchDownloadEnabled: false
        )
    }
}
