import Foundation
import MEGADomain
import MEGADomainMock
import Testing

/// Covers what the use case itself does: turn the transfers a screen asked for into the batch the
/// repository takes, hand it over, and report its transfer events as the state of the batch.
///
/// The reading of those events is `CancellableTransferStateMapper`'s, covered stage by stage in
/// `CancellableTransferStateMapperTests`; what is checked here is that a download batch is read
/// through it at all.
@Suite("CancellableDownloadTransferUseCase Tests")
struct CancellableDownloadTransferUseCaseTests {

    // MARK: - Helpers

    private static let documentsDirectory = MockFileSystemRepository().documentsDirectory()

    private func makeSUT(_ repository: MockDownloadFileRepository) -> CancellableDownloadTransferUseCase {
        CancellableDownloadTransferUseCase(
            downloadFileRepository: repository,
            fileSystemRepository: MockFileSystemRepository()
        )
    }

    /// A repository whose batch reports nothing and ends, so that a test about the batch itself is
    /// not also a test about the states read off it.
    private func makeQuietRepository() -> MockDownloadFileRepository {
        MockDownloadFileRepository(downloadBatchResult: .success([]))
    }

    private func states(
        from repository: MockDownloadFileRepository,
        transfers: [CancellableTransferEntity] = []
    ) async -> [CancellableTransferStateEntity] {
        var collected = [CancellableTransferStateEntity]()
        for await state in makeSUT(repository).start(transfers: transfers) {
            collected.append(state)
        }
        return collected
    }

    /// A source spelled out, so that a failed expectation says which one was built.
    private func describe(_ source: DownloadBatchItemEntity.Source) -> String {
        switch source {
        case .node(let handle):
            "node(\(handle))"
        case .chatNode(let handle, let messageId, let chatId):
            "chatNode(handle: \(handle), messageId: \(messageId), chatId: \(chatId))"
        case .fileLink(let fileLink):
            "fileLink(\(fileLink.linkURL.absoluteString))"
        }
    }

    // MARK: - Building the batch

    @Test("A node download is handed over as the node it downloads")
    func aNodeDownloadCarriesItsHandle() async throws {
        let repository = makeQuietRepository()

        _ = await states(from: repository, transfers: [.init(handle: 5, type: .download)])

        let item = try #require(repository.startedDownloadBatches.first?.first)
        #expect(describe(item.source) == "node(5)")
    }

    @Test("A chat attachment download is handed over with the message it came from")
    func aChatDownloadCarriesItsMessage() async throws {
        let repository = makeQuietRepository()

        _ = await states(from: repository, transfers: [
            .init(handle: 5, messageId: 6, chatId: 7, type: .downloadChat)
        ])

        let item = try #require(repository.startedDownloadBatches.first?.first)
        #expect(describe(item.source) == "chatNode(handle: 5, messageId: 6, chatId: 7)")
    }

    @Test("A file link download is handed over as the link it points at")
    func aFileLinkDownloadCarriesItsLink() async throws {
        let repository = makeQuietRepository()
        let link = try #require(URL(string: "https://mega.nz/file/abc#key"))

        _ = await states(from: repository, transfers: [
            .init(fileLinkURL: link, type: .downloadFileLink)
        ])

        let item = try #require(repository.startedDownloadBatches.first?.first)
        #expect(describe(item.source) == "fileLink(https://mega.nz/file/abc#key)")
    }

    @Test("Every item of the batch is stored in the offline documents folder")
    func everyItemIsStoredInTheDocumentsDirectory() async throws {
        let repository = makeQuietRepository()

        _ = await states(from: repository, transfers: [
            .init(handle: 5, type: .download),
            .init(handle: 6, type: .download)
        ])

        let batch = try #require(repository.startedDownloadBatches.first)
        #expect(batch.map(\.destinationFolder) == [Self.documentsDirectory, Self.documentsDirectory])
    }

    @Test("What to store the item as, and how to queue it, is handed over with it")
    func theItemCarriesItsNameAppDataAndPriority() async throws {
        let repository = makeQuietRepository()

        _ = await states(from: repository, transfers: [
            .init(handle: 5, appData: "appData", startFirst: true, type: .download, name: "photo.jpg")
        ])

        let item = try #require(repository.startedDownloadBatches.first?.first)
        #expect(item.name == "photo.jpg")
        #expect(item.appData == "appData")
        #expect(item.startFirst)
    }

    @Test("A file link download with no link to download is left out of the batch")
    func aFileLinkDownloadWithoutALinkIsLeftOut() async throws {
        let repository = makeQuietRepository()

        _ = await states(from: repository, transfers: [
            .init(type: .downloadFileLink),
            .init(handle: 5, type: .download)
        ])

        #expect(repository.startedDownloadBatches.first?.count == 1)
    }

    @Test("An upload is left out of the batch")
    func anUploadIsLeftOut() async throws {
        // Nothing sends one here -- a screen carries transfers of a single type -- but the entity
        // can describe one, and a download batch has no place for it.
        let repository = makeQuietRepository()

        _ = await states(from: repository, transfers: [
            .init(localFileURL: URL(fileURLWithPath: "/tmp/a.jpg"), type: .upload, uploadOptions: UploadOptionsEntity())
        ])

        #expect(repository.startedDownloadBatches.first?.isEmpty == true)
    }

    @Test("The batch is handed over even when its states are never read")
    func handsTheBatchOverWithoutBeingRead() async throws {
        // Asking for the states is what starts the batch, so a screen that drops the sequence has
        // still handed its downloads over -- it has only stopped hearing about them.
        let repository = makeQuietRepository()
        var handOvers = repository.handedOverBatches.makeAsyncIterator()

        _ = makeSUT(repository).start(transfers: [.init(handle: 5, type: .download)])

        let handedOver = try #require(await handOvers.next())
        #expect(handedOver.map { describe($0.source) } == ["node(5)"])
    }

    @Test("The batch is handed over once, however many states it reports")
    func handsTheBatchOverOnce() async {
        let repository = MockDownloadFileRepository(downloadBatchResult: .success([
            .folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 2, fileCount: 3),
            .folderUpdateEvent(stage: .transferringFiles, fileCount: 3)
        ]))

        _ = await states(from: repository, transfers: [.init(handle: 5, type: .download)])

        #expect(repository.startedDownloadBatches.count == 1)
    }

    // MARK: - Reading the batch state from its transfer events

    @Test("The stages the batch goes through are reported as it passes them")
    func theStagesOfTheBatchAreReported() async {
        let repository = MockDownloadFileRepository(downloadBatchResult: .success([
            .folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 2, fileCount: 3),
            .folderUpdateEvent(stage: .createTree, folderCount: 4, createdFolderCount: 1),
            .folderUpdateEvent(stage: .transferringFiles, fileCount: 3)
        ]))

        let states = await states(from: repository)

        #expect(states == [
            .scanning(name: "Docs", folderCount: 2, fileCount: 3),
            .creatingFolders(created: 1, total: 4),
            .transferringFiles
        ])
    }

    @Test("A batch that could not be started reports failed")
    func aBatchThatCannotBeStartedReportsFailed() async {
        let repository = MockDownloadFileRepository(downloadBatchResult: .failure(TransferErrorEntity.download))

        let states = await states(from: repository)

        #expect(states == [.failed])
    }

    @Test("A batch that ends on an error reports failed")
    func aBatchThatFailsReportsFailed() async {
        let repository = MockDownloadFileRepository(
            downloadBatchResult: .success([]),
            downloadBatchEventsError: TransferErrorEntity.download
        )

        let states = await states(from: repository)

        #expect(states == [.failed])
    }

    // MARK: - Cancelling

    @Test("Cancelling forwards to the repository")
    func cancellingForwardsToTheRepository() {
        let repository = makeQuietRepository()

        makeSUT(repository).cancel()

        #expect(repository.cancelDownloadTransfers_calledTimes == 1)
    }
}
