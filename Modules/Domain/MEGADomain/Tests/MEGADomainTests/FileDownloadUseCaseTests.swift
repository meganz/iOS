import MEGADomain
import MEGADomainMock
import XCTest

final class FileDownloadUseCaseTests: XCTestCase {
    private let cachedURL = URL(fileURLWithPath: "originalV3/123")

    override func setUpWithError() throws {
        try super.setUpWithError()
        // The batch switch is process wide state, so every test says which path it is exercising.
        BatchDownloadFeatureFlag.isEnabled = false
    }

    override func tearDownWithError() throws {
        BatchDownloadFeatureFlag.isEnabled = false
        try super.tearDownWithError()
    }

    func testCachedOriginalPath_returnsNodeFileURL() {
        let sut = makeSUT(repository: MockDownloadFileRepository())
        XCTAssertEqual(sut.cachedOriginalPath(NodeEntity(base64Handle: "123")), cachedURL)
    }

    func testDownloadNode_whenAlreadyCached_returnsCachedURLWithoutDownloading() async throws {
        let repository = MockDownloadFileRepository()
        let sut = makeSUT(repository: repository, hasExistingOriginalImage: true)

        let url = try await sut.downloadNode(NodeEntity(handle: 1, base64Handle: "123"))

        XCTAssertEqual(url, cachedURL)
        XCTAssertTrue(repository.startedDownloadBatches.isEmpty)
    }

    func testDownloadNode_whenBatchDisabled_downloadsWithLegacyCallAndReturnsTransferPath() async throws {
        let repository = MockDownloadFileRepository(completionResult: .success(TransferEntity(path: "originalV3/123")))
        let sut = makeSUT(repository: repository, hasExistingOriginalImage: false)

        let url = try await sut.downloadNode(NodeEntity(handle: 1, base64Handle: "123"))

        XCTAssertEqual(url, cachedURL)
        XCTAssertTrue(repository.startedDownloadBatches.isEmpty)
    }

    func testDownloadNode_whenBatchDisabledAndTransferHasNoPath_throwsDownload() async {
        let repository = MockDownloadFileRepository(completionResult: .success(TransferEntity(path: nil)))
        let sut = makeSUT(repository: repository, hasExistingOriginalImage: false)

        await assertDownloadThrowsDownloadError(sut)
    }

    func testDownloadNode_whenBatchEnabled_downloadsNodeAsOneBatchItemToTheCachedFile() async throws {
        BatchDownloadFeatureFlag.isEnabled = true
        let repository = MockDownloadFileRepository(completionResult: .success(TransferEntity(path: "ignored")))
        let sut = makeSUT(repository: repository, hasExistingOriginalImage: false)

        let url = try await sut.downloadNode(NodeEntity(handle: 1, base64Handle: "123"))

        XCTAssertEqual(url, cachedURL)
        XCTAssertEqual(repository.startedDownloadBatches.count, 1)
        let item = try XCTUnwrap(repository.startedDownloadBatches.first?.first)
        XCTAssertEqual(item.source.nodeHandle, 1)
        XCTAssertEqual(item.destination, .file(cachedURL))
        XCTAssertTrue(item.startFirst)
        XCTAssertNil(item.appData)
    }

    func testDownloadNode_whenBatchEnabledAndBatchFails_throwsTheBatchError() async {
        BatchDownloadFeatureFlag.isEnabled = true
        let repository = MockDownloadFileRepository(downloadBatchResult: .failure(TransferErrorEntity.download))
        let sut = makeSUT(repository: repository, hasExistingOriginalImage: false)

        await assertDownloadThrowsDownloadError(sut)
    }

    // MARK: - Helpers
    private func assertDownloadThrowsDownloadError(
        _ sut: some FileDownloadUseCaseProtocol,
        line: UInt = #line
    ) async {
        do {
            _ = try await sut.downloadNode(NodeEntity(handle: 1, base64Handle: "123"))
            XCTFail("Expected the download to throw", line: line)
        } catch {
            XCTAssertEqual(error as? TransferErrorEntity, .download, line: line)
        }
    }

    private func makeSUT(
        repository: MockDownloadFileRepository,
        hasExistingOriginalImage: Bool = true
    ) -> some FileDownloadUseCaseProtocol {
        FileDownloadUseCase(
            fileCacheRepository: MockFileCacheRepository(
                base64Handle: "123",
                hasExistingOriginalImage: hasExistingOriginalImage
            ),
            fileSystemRepository: MockFileSystemRepository(),
            downloadFileRepository: repository
        )
    }
}

private extension DownloadBatchItemEntity.Source {
    var nodeHandle: HandleEntity? {
        if case let .node(handle) = self { handle } else { nil }
    }
}
