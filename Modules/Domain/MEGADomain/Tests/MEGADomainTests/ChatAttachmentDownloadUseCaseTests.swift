import MEGADomain
import MEGADomainMock
import XCTest

final class ChatAttachmentDownloadUseCaseTests: XCTestCase {
    private let fileURL = URL(fileURLWithPath: "/voiceCaches/handle/clip.m4a")

    override func setUpWithError() throws {
        try super.setUpWithError()
        // The batch switch is process wide state, so every test says which path it is exercising.
        BatchDownloadFeatureFlag.isEnabled = false
    }

    override func tearDownWithError() throws {
        BatchDownloadFeatureFlag.isEnabled = false
        try super.tearDownWithError()
    }

    func testDownload_whenBatchDisabled_startsTheChatDownloadUnderTheFileName() async throws {
        let chatRepository = MockDownloadChatRepository()
        let fileRepository = MockDownloadFileRepository()
        let sut = ChatAttachmentDownloadUseCase(downloadFileRepository: fileRepository, downloadChatRepository: chatRepository)

        try await sut.download(nodeHandle: 1, messageId: 2, chatId: 3, to: fileURL, appData: "appData")

        XCTAssertTrue(fileRepository.startedDownloadBatches.isEmpty)
        XCTAssertEqual(
            chatRepository.downloadChatFileCalls,
            [
                .init(
                    handle: 1,
                    messageId: 2,
                    chatId: 3,
                    url: fileURL.deletingLastPathComponent(),
                    filename: fileURL.lastPathComponent,
                    appdata: "appData",
                    startFirst: true
                )
            ]
        )
    }

    func testDownload_whenBatchDisabledAndChatDownloadFails_throwsTheError() async {
        let chatRepository = MockDownloadChatRepository(downloadChatFileError: TransferErrorEntity.couldNotFindNodeByHandle)
        let sut = ChatAttachmentDownloadUseCase(
            downloadFileRepository: MockDownloadFileRepository(),
            downloadChatRepository: chatRepository
        )

        await assertDownloadThrows(sut, expected: .couldNotFindNodeByHandle)
    }

    func testDownload_whenBatchEnabled_downloadsTheChatNodeAsOneBatchItemToTheFile() async throws {
        BatchDownloadFeatureFlag.isEnabled = true
        let chatRepository = MockDownloadChatRepository()
        let fileRepository = MockDownloadFileRepository(completionResult: .success(TransferEntity(path: "ignored")))
        let sut = ChatAttachmentDownloadUseCase(downloadFileRepository: fileRepository, downloadChatRepository: chatRepository)

        try await sut.download(nodeHandle: 1, messageId: 2, chatId: 3, to: fileURL, appData: "appData")

        XCTAssertTrue(chatRepository.downloadChatFileCalls.isEmpty)
        XCTAssertEqual(fileRepository.startedDownloadBatches.count, 1)
        let item = try XCTUnwrap(fileRepository.startedDownloadBatches.first?.first)
        XCTAssertEqual(item.source.chatNode?.handle, 1)
        XCTAssertEqual(item.source.chatNode?.messageId, 2)
        XCTAssertEqual(item.source.chatNode?.chatId, 3)
        XCTAssertEqual(item.destination, .file(fileURL))
        XCTAssertEqual(item.appData, "appData")
        XCTAssertTrue(item.startFirst)
    }

    func testDownload_whenBatchEnabledAndBatchFails_throwsTheError() async {
        BatchDownloadFeatureFlag.isEnabled = true
        let sut = ChatAttachmentDownloadUseCase(
            downloadFileRepository: MockDownloadFileRepository(downloadBatchResult: .failure(TransferErrorEntity.download)),
            downloadChatRepository: MockDownloadChatRepository()
        )

        await assertDownloadThrows(sut, expected: .download)
    }

    func testDownload_whenBatchDisabledAndEnabled_downloadsToTheSameFilePath() async throws {
        let chatRepository = MockDownloadChatRepository()
        let legacySUT = ChatAttachmentDownloadUseCase(
            downloadFileRepository: MockDownloadFileRepository(),
            downloadChatRepository: chatRepository
        )
        try await legacySUT.download(nodeHandle: 1, messageId: 2, chatId: 3, to: fileURL, appData: "appData")

        BatchDownloadFeatureFlag.isEnabled = true
        let fileRepository = MockDownloadFileRepository(completionResult: .success(TransferEntity(path: "ignored")))
        let batchSUT = ChatAttachmentDownloadUseCase(
            downloadFileRepository: fileRepository,
            downloadChatRepository: MockDownloadChatRepository()
        )
        try await batchSUT.download(nodeHandle: 1, messageId: 2, chatId: 3, to: fileURL, appData: "appData")

        let legacyCall = try XCTUnwrap(chatRepository.downloadChatFileCalls.first)
        let legacyPath = legacyCall.url.appendingPathComponent(try XCTUnwrap(legacyCall.filename)).path
        let destination = try XCTUnwrap(fileRepository.startedDownloadBatches.first?.first?.destination)
        let batchPath = destination.folder.appendingPathComponent(try XCTUnwrap(destination.name)).path

        XCTAssertEqual(legacyPath, fileURL.path)
        XCTAssertEqual(batchPath, fileURL.path)
    }

    // MARK: - Helpers
    private func assertDownloadThrows(
        _ sut: some ChatAttachmentDownloadUseCaseProtocol,
        expected: TransferErrorEntity,
        line: UInt = #line
    ) async {
        do {
            try await sut.download(nodeHandle: 1, messageId: 2, chatId: 3, to: fileURL, appData: nil)
            XCTFail("Expected the download to throw", line: line)
        } catch {
            XCTAssertEqual(error as? TransferErrorEntity, expected, line: line)
        }
    }
}

private extension DownloadBatchItemEntity.Source {
    var chatNode: (handle: HandleEntity, messageId: HandleEntity, chatId: HandleEntity)? {
        if case let .chatNode(handle, messageId, chatId) = self {
            (handle, messageId, chatId)
        } else {
            nil
        }
    }
}
