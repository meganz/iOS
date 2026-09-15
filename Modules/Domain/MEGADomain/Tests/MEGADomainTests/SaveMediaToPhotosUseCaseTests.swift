import MEGADomain
import MEGADomainMock
import XCTest

final class SaveMediaToPhotosUseCaseTests: XCTestCase {
    private let nodeEntity = NodeEntity(name: "nodeName")
    private let nodeEntity2 = NodeEntity(name: "node2")
    private let mockTransferEntity = TransferEntity(path: "originalV3/" + "123")
    private var mockNodeRepo: MockNodeRepository!
    private var mockDownloadFileRepo: MockDownloadFileRepository!

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockNodeRepo = MockNodeRepository(node: nodeEntity)
        // The batch switch is process wide state, so every test says which path it is exercising
        // rather than inheriting whatever the one before it left behind.
        BatchDownloadFeatureFlag.isEnabled = false
    }

    override func tearDownWithError() throws {
        BatchDownloadFeatureFlag.isEnabled = false

        try super.tearDownWithError()
    }

    func testSaveToPhotos_single_succeeded() async throws {
        mockDownloadFileRepo = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))

        let sut = SaveMediaToPhotosUseCase(downloadFileRepository: mockDownloadFileRepo,
                                           fileCacheRepository: MockFileCacheRepository.newRepo,
                                           nodeRepository: mockNodeRepo,
                                           chatNodeRepository: MockChatNodeRepository(),
                                           downloadChatRepository: MockDownloadChatRepository())
        try await sut.saveToPhotos(nodes: [nodeEntity])
    }

    func testSaveToPhotos_single_failed() async throws {
        mockDownloadFileRepo = MockDownloadFileRepository(completionResult: .failure(.download))

        let sut = SaveMediaToPhotosUseCase(downloadFileRepository: mockDownloadFileRepo,
                                           fileCacheRepository: MockFileCacheRepository.newRepo,
                                           nodeRepository: mockNodeRepo,
                                           chatNodeRepository: MockChatNodeRepository(),
                                           downloadChatRepository: MockDownloadChatRepository())
        do {
            try await sut.saveToPhotos(nodes: [nodeEntity])
        } catch let errorEntity as SaveMediaToPhotosErrorEntity {
            XCTAssertTrue(errorEntity == .fileDownloadInProgress)
        }
    }

    func testSaveToPhotos_multiple_succeeded() async throws {
        mockDownloadFileRepo = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))

        let sut = SaveMediaToPhotosUseCase(downloadFileRepository: mockDownloadFileRepo,
                                           fileCacheRepository: MockFileCacheRepository.newRepo,
                                           nodeRepository: mockNodeRepo,
                                           chatNodeRepository: MockChatNodeRepository(),
                                           downloadChatRepository: MockDownloadChatRepository())
        try await sut.saveToPhotos(nodes: [nodeEntity, nodeEntity2])
    }

    func testSaveToPhotos_multiple_failed() async throws {
        mockDownloadFileRepo = MockDownloadFileRepository(completionResult: .failure(.download))

        let sut = SaveMediaToPhotosUseCase(downloadFileRepository: mockDownloadFileRepo,
                                           fileCacheRepository: MockFileCacheRepository.newRepo,
                                           nodeRepository: mockNodeRepo,
                                           chatNodeRepository: MockChatNodeRepository(),
                                           downloadChatRepository: MockDownloadChatRepository())
        do {
            try await sut.saveToPhotos(nodes: [nodeEntity, nodeEntity2])
        } catch let errorEntity as SaveMediaToPhotosErrorEntity {
            XCTAssertTrue(errorEntity == .fileDownloadInProgress)
        }
    }

    // MARK: - Batch download

    func testSaveToPhotosNodes_whenBatchDisabled_startsNoBatch() async throws {
        BatchDownloadFeatureFlag.isEnabled = false
        let downloadFileRepository = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))
        let sut = makeSUT(downloadFileRepository: downloadFileRepository)

        try await sut.saveToPhotos(nodes: [nodeEntity, nodeEntity2])

        XCTAssertTrue(downloadFileRepository.startedDownloadBatches.isEmpty)
    }

    func testSaveToPhotosNodes_whenBatchEnabled_startsOneBatchHoldingEveryNode() async throws {
        BatchDownloadFeatureFlag.isEnabled = true
        let fileCacheRepository = MockFileCacheRepository(name: "nodeName", tempFolder: URL(fileURLWithPath: "/temp"))
        let downloadFileRepository = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))
        let sut = makeSUT(
            downloadFileRepository: downloadFileRepository,
            fileCacheRepository: fileCacheRepository
        )

        try await sut.saveToPhotos(nodes: [nodeEntity, nodeEntity2])

        XCTAssertEqual(downloadFileRepository.startedDownloadBatches.count, 1)
        let batch = try XCTUnwrap(downloadFileRepository.startedDownloadBatches.first)
        XCTAssertEqual(batch.count, 2)
        XCTAssertEqual(
            batch.map(\.source).map(handle(of:)),
            [nodeEntity.handle, nodeEntity2.handle]
        )
        // The folder, not the file: the item is stored in it under the node's own name.
        XCTAssertEqual(
            batch.map(\.destination),
            [
                .folder(fileCacheRepository.base64HandleTempFolder(for: nodeEntity.base64Handle)),
                .folder(fileCacheRepository.base64HandleTempFolder(for: nodeEntity2.base64Handle))
            ]
        )
        XCTAssertEqual(batch.map(\.appData), Array(repeating: ">SaveInPhotosApp", count: 2))
        // Save to photos jumped the download queue before the batch API, and still has to.
        XCTAssertEqual(batch.map(\.startFirst), Array(repeating: true, count: 2))
    }

    func testSaveToPhotosNodes_whenBatchEnabledAndBatchFails_throwsDownloadFailed() async {
        await assertSaveToPhotosNodesThrows(
            batchError: TransferErrorEntity.download,
            expected: .downloadFailed
        )
    }

    func testSaveToPhotosNodes_whenBatchEnabledAndBatchCancelled_throwsCancelled() async {
        await assertSaveToPhotosNodesThrows(
            batchError: TransferErrorEntity.cancelled,
            expected: .cancelled
        )
    }

    func testSaveToPhotosChatNode_whenBatchEnabled_startsBatchHoldingTheChatNode() async throws {
        BatchDownloadFeatureFlag.isEnabled = true
        let chatNode = NodeEntity(name: "chatNode", handle: 5)
        let fileCacheRepository = MockFileCacheRepository(name: "chatNode", tempFolder: URL(fileURLWithPath: "/temp"))
        let downloadFileRepository = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))
        let sut = makeSUT(
            downloadFileRepository: downloadFileRepository,
            fileCacheRepository: fileCacheRepository,
            chatNodeRepository: MockChatNodeRepository(node: chatNode)
        )

        try await sut.saveToPhotosChatNode(handle: 5, messageId: 6, chatId: 7)

        let batch = try XCTUnwrap(downloadFileRepository.startedDownloadBatches.first)
        XCTAssertEqual(downloadFileRepository.startedDownloadBatches.count, 1)
        XCTAssertEqual(batch.count, 1)
        guard case let .chatNode(handle, messageId, chatId) = try XCTUnwrap(batch.first).source else {
            return XCTFail("Expected a chat node source")
        }
        XCTAssertEqual([handle, messageId, chatId], [5, 6, 7])
        XCTAssertEqual(
            try XCTUnwrap(batch.first).destination,
            .folder(fileCacheRepository.base64HandleTempFolder(for: chatNode.base64Handle))
        )
        XCTAssertEqual(try XCTUnwrap(batch.first).appData, ">SaveInPhotosApp")
        XCTAssertTrue(try XCTUnwrap(batch.first).startFirst)
    }

    func testSaveToPhotosChatNode_whenBatchEnabledAndChatNodeMissing_throwsNodeNotFound() async {
        BatchDownloadFeatureFlag.isEnabled = true
        let downloadFileRepository = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))
        let sut = makeSUT(
            downloadFileRepository: downloadFileRepository,
            chatNodeRepository: MockChatNodeRepository(node: nil)
        )

        do {
            try await sut.saveToPhotosChatNode(handle: 5, messageId: 6, chatId: 7)
            XCTFail("Expected a missing chat node to be reported")
        } catch {
            XCTAssertEqual(error as? SaveMediaToPhotosErrorEntity, .nodeNotFound)
        }
        XCTAssertTrue(downloadFileRepository.startedDownloadBatches.isEmpty)
    }

    func testSaveToPhotosChatNode_whenBatchEnabledAndBatchCancelled_throwsCancelled() async {
        await assertSaveToPhotosChatNodeThrows(
            batchError: TransferErrorEntity.cancelled,
            expected: .cancelled
        )
    }

    func testSaveToPhotosChatNode_whenBatchEnabledAndBatchFails_throwsDownloadFailed() async {
        await assertSaveToPhotosChatNodeThrows(
            batchError: TransferErrorEntity.download,
            expected: .downloadFailed
        )
    }

    func testSaveToPhotosFileLink_whenBatchEnabled_startsBatchHoldingTheFileLink() async throws {
        BatchDownloadFeatureFlag.isEnabled = true
        let linkURL = URL(string: "https://mega.nz/file/link")!
        let linkNode = NodeEntity(name: "linkNode", handle: 9, base64Handle: "base64Handle")
        let fileCacheRepository = MockFileCacheRepository(base64Handle: "base64Handle", tempFolder: URL(fileURLWithPath: "/temp"))
        let downloadFileRepository = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))
        let sut = makeSUT(
            downloadFileRepository: downloadFileRepository,
            fileCacheRepository: fileCacheRepository,
            nodeRepository: MockNodeRepository(fileLinkNode: linkNode)
        )

        try await sut.saveToPhotos(fileLink: FileLinkEntity(linkURL: linkURL))

        XCTAssertEqual(downloadFileRepository.startedDownloadBatches.count, 1)
        let item = try XCTUnwrap(downloadFileRepository.startedDownloadBatches.first?.first)
        guard case let .fileLink(fileLink) = item.source else {
            return XCTFail("Expected a file link source")
        }
        XCTAssertEqual(fileLink.linkURL, linkURL)
        XCTAssertEqual(
            item.destination,
            .folder(fileCacheRepository.base64HandleTempFolder(for: linkNode.base64Handle)),
            "The link's node is stored in its own temp folder, under the name the node carries."
        )
        XCTAssertEqual(item.appData, ">SaveInPhotosApp")
        XCTAssertTrue(item.startFirst)
    }

    func testSaveToPhotosFileLink_whenBatchEnabledAndNodeCannotBeResolved_throws() async {
        BatchDownloadFeatureFlag.isEnabled = true
        let downloadFileRepository = MockDownloadFileRepository(completionResult: .success(mockTransferEntity))
        let sut = makeSUT(
            downloadFileRepository: downloadFileRepository,
            nodeRepository: MockNodeRepository(fileLinkNode: nil)
        )

        do {
            try await sut.saveToPhotos(fileLink: FileLinkEntity(linkURL: URL(string: "https://mega.nz/file/link")!))
            XCTFail("Expected the unresolved link to be reported")
        } catch {
            XCTAssertEqual(error as? SaveMediaToPhotosErrorEntity, .nodeNotFound)
        }
        XCTAssertTrue(downloadFileRepository.startedDownloadBatches.isEmpty)
    }

    func testSaveToPhotosFileLink_whenBatchEnabledAndBatchCancelled_throwsCancelled() async {
        await assertSaveToPhotosFileLinkThrows(
            batchError: TransferErrorEntity.cancelled,
            expected: .cancelled
        )
    }

    func testSaveToPhotosFileLink_whenBatchEnabledAndBatchFails_throwsDownloadFailed() async {
        await assertSaveToPhotosFileLinkThrows(
            batchError: TransferErrorEntity.download,
            expected: .downloadFailed
        )
    }

    // MARK: - Helpers

    private func makeSUT(
        downloadFileRepository: MockDownloadFileRepository,
        fileCacheRepository: MockFileCacheRepository = MockFileCacheRepository.newRepo,
        nodeRepository: MockNodeRepository? = nil,
        chatNodeRepository: MockChatNodeRepository = MockChatNodeRepository(),
        downloadChatRepository: MockDownloadChatRepository = MockDownloadChatRepository()
    ) -> some SaveMediaToPhotosUseCaseProtocol {
        SaveMediaToPhotosUseCase(
            downloadFileRepository: downloadFileRepository,
            fileCacheRepository: fileCacheRepository,
            nodeRepository: nodeRepository ?? mockNodeRepo,
            chatNodeRepository: chatNodeRepository,
            downloadChatRepository: downloadChatRepository
        )
    }

    private func handle(of source: DownloadBatchItemEntity.Source) -> HandleEntity? {
        guard case let .node(handle) = source else { return nil }
        return handle
    }

    private func assertSaveToPhotosNodesThrows(
        batchError: any Error,
        expected: SaveMediaToPhotosErrorEntity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        BatchDownloadFeatureFlag.isEnabled = true
        let sut = makeSUT(
            downloadFileRepository: MockDownloadFileRepository(downloadBatchResult: .failure(batchError))
        )

        do {
            try await sut.saveToPhotos(nodes: [nodeEntity])
            XCTFail("Expected \(expected) to be thrown", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? SaveMediaToPhotosErrorEntity, expected, file: file, line: line)
        }
    }

    private func assertSaveToPhotosChatNodeThrows(
        batchError: any Error,
        expected: SaveMediaToPhotosErrorEntity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        BatchDownloadFeatureFlag.isEnabled = true
        let sut = makeSUT(
            downloadFileRepository: MockDownloadFileRepository(downloadBatchResult: .failure(batchError)),
            chatNodeRepository: MockChatNodeRepository(node: NodeEntity(name: "chatNode", handle: 5))
        )

        do {
            try await sut.saveToPhotosChatNode(handle: 5, messageId: 6, chatId: 7)
            XCTFail("Expected \(expected) to be thrown", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? SaveMediaToPhotosErrorEntity, expected, file: file, line: line)
        }
    }

    private func assertSaveToPhotosFileLinkThrows(
        batchError: any Error,
        expected: SaveMediaToPhotosErrorEntity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        BatchDownloadFeatureFlag.isEnabled = true
        let sut = makeSUT(
            downloadFileRepository: MockDownloadFileRepository(downloadBatchResult: .failure(batchError)),
            nodeRepository: MockNodeRepository(fileLinkNode: NodeEntity(name: "linkNode", handle: 9, base64Handle: "base64Handle"))
        )

        do {
            try await sut.saveToPhotos(fileLink: FileLinkEntity(linkURL: URL(string: "https://mega.nz/file/link")!))
            XCTFail("Expected \(expected) to be thrown", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? SaveMediaToPhotosErrorEntity, expected, file: file, line: line)
        }
    }
}
