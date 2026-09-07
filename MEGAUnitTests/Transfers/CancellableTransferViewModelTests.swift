@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGATest
import Testing
import XCTest

final class CancellableTransferViewModelTests: XCTestCase {
    
    @MainActor func testAction_onViewReady() {
        let transfer = CancellableTransfer(handle: .invalid, messageId: .invalid, chatId: .invalid, localFileURL: URL(fileURLWithPath: "PathToFile"), name: nil, appData: nil, priority: false, isFile: true, type: .download)
        let router = MockCancellableTransferRouter()
        let viewModel = makeSUT(
            router: router,
            transfers: [transfer],
            transferType: .download)
        
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [])
        XCTAssert(router.prepareTransfersWidget_calledTimes == 1)
    }
    
    @MainActor func testAction_onViewReadyPawalled_overDiskQuotaShouldNotTransfer() {
        let overDiskQuotaChecker = MockOverDiskQuotaChecker(isPaywalled: true)
        
        let transfer = CancellableTransfer(handle: .invalid, messageId: .invalid, chatId: .invalid, localFileURL: URL(fileURLWithPath: "PathToFile"), name: nil, appData: nil, priority: false, isFile: true, type: .download)
        let router = MockCancellableTransferRouter()
        let viewModel = makeSUT(
            router: router,
            overDiskQuotaChecker: overDiskQuotaChecker,
            transfers: [transfer],
            transferType: .download)
        
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [])
        XCTAssert(router.prepareTransfersWidget_calledTimes == 0)
        XCTAssertEqual(router.transferFlowDidFinish_calledTimes, 1)
    }

    @MainActor func testAction_onViewReadyWithNoTransfers_finishesFlowWithoutPreparingWidget() {
        let router = MockCancellableTransferRouter()
        let viewModel = makeSUT(router: router, transferType: .download)

        viewModel.dispatch(.onViewReady)

        XCTAssertEqual(router.prepareTransfersWidget_calledTimes, 0)
        XCTAssertEqual(router.transferFlowDidFinish_calledTimes, 1)
    }

    @MainActor func testAction_onViewReadyWithInvalidUploadURLs_marksTransfersFailedAndFinishesFlow() {
        let file = CancellableTransfer(localFileURL: nil, isFile: true, type: .upload)
        let folder = CancellableTransfer(localFileURL: nil, isFile: false, type: .upload)
        let router = MockCancellableTransferRouter()
        let viewModel = makeSUT(
            router: router,
            transfers: [file, folder],
            transferType: .upload)

        viewModel.dispatch(.onViewReady)

        XCTAssertEqual(file.state, .failed)
        XCTAssertEqual(folder.state, .failed)
        XCTAssertEqual(router.transferFailed_calledTimes, 1)
        XCTAssertEqual(router.transferFlowDidFinish_calledTimes, 1)
    }

    @MainActor func testAction_onViewReadyWithMissingFileLinkURL_marksTransferFailedAndFinishesFlow() {
        let transfer = CancellableTransfer(fileLinkURL: nil, isFile: true, type: .downloadFileLink)
        let router = MockCancellableTransferRouter()
        let viewModel = makeSUT(
            router: router,
            transfers: [transfer],
            transferType: .downloadFileLink)

        viewModel.dispatch(.onViewReady)

        evaluate { router.transferFlowDidFinish_calledTimes == 1 }
        XCTAssertEqual(transfer.state, .failed)
        XCTAssertEqual(router.transferFailed_calledTimes, 1)
    }

    @MainActor func testAction_onViewReadyWithFileDownloadThatDoesNotStart_doesNotFinishFromAlertTimer() async throws {
        let transfer = CancellableTransfer(handle: 1, isFile: true, type: .download)
        let router = MockCancellableTransferRouter()
        let downloadNodeUseCase = PendingDownloadNodeUseCase()
        let alertPresented = expectation(description: "Transfer alert presented")
        router.showTransfersAlertHandler = { alertPresented.fulfill() }
        let viewModel = makeSUT(
            router: router,
            downloadNodeUseCase: downloadNodeUseCase,
            transfers: [transfer],
            transferType: .download,
            alertPresentationDelay: 0.01,
            alertBlockingDelay: 0.05)

        viewModel.dispatch(.onViewReady)
        await fulfillment(of: [alertPresented], timeout: 1)
        // Start from the observed alert presentation so only the blocking delay is wall-clock based.
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(transfer.state, .none)
        XCTAssertEqual(router.transferSuccess_calledTimes, 0)
        XCTAssertEqual(router.transferFlowDidFinish_calledTimes, 0)

        viewModel.dispatch(.didTapCancelButton)
        XCTAssertEqual(router.transferCancelled_calledTimes, 1)
        XCTAssertEqual(router.transferFlowDidFinish_calledTimes, 1)
    }

    @MainActor func testAction_onViewReadyWithDownloadStreamEndingBeforeStart_marksTransferFailedAndFinishesFlow() {
        let transfer = CancellableTransfer(handle: 1, isFile: true, type: .download)
        let router = MockCancellableTransferRouter()
        let viewModel = makeSUT(
            router: router,
            transfers: [transfer],
            transferType: .download)

        viewModel.dispatch(.onViewReady)

        evaluate { router.transferFlowDidFinish_calledTimes == 1 }
        XCTAssertEqual(transfer.state, .failed)
        XCTAssertEqual(router.transferFailed_calledTimes, 1)
    }
    
    @MainActor func testAction_cancelTransfer() {
        let transfer = CancellableTransfer(handle: .invalid, messageId: .invalid, chatId: .invalid, localFileURL: URL(fileURLWithPath: "PathToFile"), name: nil, appData: nil, priority: false, isFile: true, type: .download)
        let router = MockCancellableTransferRouter()
        let viewModel = makeSUT(
            router: router,
            transfers: [transfer],
            transferType: .download)
        
        test(viewModel: viewModel, action: .didTapCancelButton, expectedCommands: [.cancelling])
        XCTAssertEqual(router.transferCancelled_calledTimes, 1)
        XCTAssertEqual(router.transferFlowDidFinish_calledTimes, 1)
    }

    @MainActor func testAction_cancelTransferWhileAlertIsBlocked_finishesAfterBlockEnds() async {
        let transfer = CancellableTransfer(handle: 1, isFile: true, type: .download)
        let router = MockCancellableTransferRouter()
        let downloadNodeUseCase = PendingDownloadNodeUseCase()
        let alertPresented = expectation(description: "Transfer alert presented")
        let flowFinished = expectation(description: "Transfer flow finished")
        router.showTransfersAlertHandler = { alertPresented.fulfill() }
        router.transferFlowDidFinishHandler = { flowFinished.fulfill() }
        let viewModel = makeSUT(
            router: router,
            downloadNodeUseCase: downloadNodeUseCase,
            transfers: [transfer],
            transferType: .download,
            alertPresentationDelay: 0.01,
            alertBlockingDelay: 0.2)

        viewModel.dispatch(.onViewReady)
        await fulfillment(of: [alertPresented], timeout: 1)
        viewModel.dispatch(.didTapCancelButton)

        XCTAssertEqual(router.transferFlowDidFinish_calledTimes, 0)

        await fulfillment(of: [flowFinished], timeout: 1)
        XCTAssertEqual(router.transferCancelled_calledTimes, 1)
    }
    
    @MainActor func testAction_onViewReady_transferCarryingItsNode_shouldDownloadThatNodeRatherThanLookItUp() {
        let photo = NodeEntity(name: "photo.jpg", handle: 5, isFile: true)
        let transfer = CancellableTransfer(handle: photo.handle, nodeEntity: photo, name: photo.name, type: .download)
        // Spelled out because the test entity defaults to `.none`, which the view model reads as a transfer
        // that never started -- the SDK reports a real state the moment it calls back.
        let downloadNodeUseCase = MockDownloadNodeUseCase(
            result: .success(TransferEntity(type: .download, path: "Documents/", state: .active)))
        let viewModel = makeSUT(
            downloadNodeUseCase: downloadNodeUseCase,
            transfers: [transfer],
            transferType: .download)
        
        viewModel.dispatch(.onViewReady)
        
        // The lookup by handle searches the account tree, where an album link's photos are not, so which
        // of the two routes a transfer takes is the whole point of carrying the node.
        evaluate { downloadNodeUseCase.downloadedNodes == [photo] }
    }
    
    @MainActor func testAction_onViewReady_transferWithoutItsNode_shouldLookTheNodeUpByHandle() {
        let transfer = CancellableTransfer(handle: 5, name: "photo.jpg", type: .download)
        // Spelled out because the test entity defaults to `.none`, which the view model reads as a transfer
        // that never started -- the SDK reports a real state the moment it calls back.
        let downloadNodeUseCase = MockDownloadNodeUseCase(
            result: .success(TransferEntity(type: .download, path: "Documents/", state: .active)))
        let router = MockCancellableTransferRouter()
        let viewModel = makeSUT(
            router: router,
            downloadNodeUseCase: downloadNodeUseCase,
            transfers: [transfer],
            transferType: .download)
        
        viewModel.dispatch(.onViewReady)
        
        evaluate { router.transferSuccess_calledTimes == 1 }
        XCTAssertTrue(downloadNodeUseCase.downloadedNodes.isEmpty)
    }
    
    @MainActor func testAction_onViewReady_fileAlreadyInOffline_shouldFinishAsASuccessRatherThanLeaveTheAlertUp() {
        let photo = NodeEntity(name: "photo.jpg", handle: 5, isFile: true)
        let transfer = CancellableTransfer(handle: photo.handle, nodeEntity: photo, name: photo.name, type: .download)
        let downloadNodeUseCase = MockDownloadNodeUseCase(result: .failure(.alreadyDownloaded))
        let router = MockCancellableTransferRouter()
        let viewModel = makeSUT(
            router: router,
            downloadNodeUseCase: downloadNodeUseCase,
            transfers: [transfer],
            transferType: .download)
        
        viewModel.dispatch(.onViewReady)
        
        // Nothing ever streams for a file that is already there, so completion has to come from the catch.
        evaluate { router.transferSuccess_calledTimes == 1 }
        XCTAssertEqual(transfer.state, .complete)
    }
    
    @MainActor func testAction_onViewReady_fileFailingToDownload_shouldReportTheFailure() {
        let photo = NodeEntity(name: "photo.jpg", handle: 5, isFile: true)
        let transfer = CancellableTransfer(handle: photo.handle, nodeEntity: photo, name: photo.name, type: .download)
        let downloadNodeUseCase = MockDownloadNodeUseCase(result: .failure(.couldNotFindNodeByHandle))
        let router = MockCancellableTransferRouter()
        let viewModel = makeSUT(
            router: router,
            downloadNodeUseCase: downloadNodeUseCase,
            transfers: [transfer],
            transferType: .download)
        
        viewModel.dispatch(.onViewReady)
        
        evaluate { router.transferFailed_calledTimes == 1 }
        XCTAssertEqual(transfer.state, .failed)
    }
    
    @MainActor func test_sendDownloadAnalyticsStats_non_multimedia_nodes() {
        sendDownloadAnalyticsStats(multimediaNodes: [], nonMultimediaNodes: [NodeEntity(name: "node.jpg", handle: 1)], analyticsEventEntity: .download(.makeAvailableOffline))
    }
    
    @MainActor func test_sendDownloadAnalyticsStats_multimedia_nodes() {
        sendDownloadAnalyticsStats(multimediaNodes: [NodeEntity(name: "node.mp3", handle: 1)], nonMultimediaNodes: [], analyticsEventEntity: .download(.makeAvailableOfflinePhotosVideos))
    }
    
    @MainActor func test_sendDownloadAnalyticsStats_multimedia_and_non_multimedia_nodes() {
        sendDownloadAnalyticsStats(multimediaNodes: [NodeEntity(name: "node.mp3", handle: 1)], nonMultimediaNodes: [NodeEntity(name: "node.jpg", handle: 2)], analyticsEventEntity: .download(.makeAvailableOffline))
    }
    
    @MainActor private func sendDownloadAnalyticsStats(multimediaNodes: [NodeEntity], nonMultimediaNodes: [NodeEntity], analyticsEventEntity: AnalyticsEventEntity) {
        let analyticsEventUseCase = MockAnalyticsEventUseCase()
        
        let transfers = [multimediaNodes, nonMultimediaNodes].flatMap {$0}
            .compactMap {
                CancellableTransfer(handle: $0.handle, name: $0.name, type: .download)
            }
        let viewModel = makeSUT(
            mediaUseCase: MockMediaUseCase(multimediaNodeNames: multimediaNodes.compactMap {$0.name}),
            analyticsEventUseCase: analyticsEventUseCase,
            transfers: transfers,
            transferType: .download)
        
        test(viewModel: viewModel, action: .onViewReady, expectedCommands: [])
        
        XCTAssertTrue(analyticsEventUseCase.type == analyticsEventEntity)
    }
    
    @MainActor
    private func makeSUT(
        router: some CancellableTransferViewModel.routingProtocols = MockCancellableTransferRouter(),
        uploadFileUseCase: any UploadFileUseCaseProtocol = MockUploadFileUseCase(),
        downloadNodeUseCase: any DownloadNodeUseCaseProtocol = MockDownloadNodeUseCase(),
        mediaUseCase: any MediaUseCaseProtocol = MockMediaUseCase(),
        analyticsEventUseCase: any AnalyticsEventUseCaseProtocol = MockAnalyticsEventUseCase(),
        overDiskQuotaChecker: some OverDiskQuotaChecking = MockOverDiskQuotaChecker(),
        transfers: [CancellableTransfer] = [],
        transferType: CancellableTransferType,
        alertPresentationDelay: TimeInterval = 0.8,
        alertBlockingDelay: TimeInterval = 1.2
    ) -> CancellableTransferViewModel {
        .init(
            router: router,
            uploadFileUseCase: uploadFileUseCase,
            downloadNodeUseCase: downloadNodeUseCase,
            mediaUseCase: mediaUseCase,
            analyticsEventUseCase: analyticsEventUseCase,
            overDiskQuotaChecker: overDiskQuotaChecker,
            transfers: transfers,
            transferType: transferType,
            alertPresentationDelay: alertPresentationDelay,
            alertBlockingDelay: alertBlockingDelay
        )
    }
}

private final class PendingDownloadNodeUseCase: DownloadNodeUseCaseProtocol, @unchecked Sendable {
    private let stream: AsyncStream<TransferEventEntity>
    private let continuation: AsyncStream<TransferEventEntity>.Continuation

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: TransferEventEntity.self)
        self.stream = stream
        self.continuation = continuation
    }

    func downloadFileToOffline(
        forNodeHandle handle: HandleEntity,
        filename: String?,
        appData: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        stream.eraseToAnyAsyncSequence()
    }

    func downloadFileToOffline(
        _ node: NodeEntity,
        filename: String?,
        appData: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        stream.eraseToAnyAsyncSequence()
    }

    func downloadChatFileToOffline(
        forNodeHandle handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) async throws -> AnyAsyncSequence<TransferEventEntity> {
        stream.eraseToAnyAsyncSequence()
    }

    func downloadFileToTempFolder(
        nodeHandle: HandleEntity,
        appData: String?
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        stream.eraseToAnyAsyncSequence()
    }

    func downloadFileLinkToOffline(
        _ fileLink: FileLinkEntity,
        filename: String?,
        metaData: TransferMetaDataEntity?,
        startFirst: Bool
    ) async throws -> AnyAsyncSequence<TransferEventEntity> {
        stream.eraseToAnyAsyncSequence()
    }

    func cancelDownloadTransfers() {
        finish()
    }

    func finish() {
        continuation.finish()
    }
}

final class MockCancellableTransferRouter: CancellableTransferRouting, CancellableTransferFlowLifecycleRouting, TransferWidgetRouting {
    var showTransfersAlertHandler: (() -> Void)?
    var transferFlowDidFinishHandler: (() -> Void)?
    var showTransfersAlert_calledTimes = 0
    var transferSuccess_calledTimes = 0
    var transferCancelled_calledTimes = 0
    var transferFailed_calledTimes = 0
    var transferCompletedWithError_calledTimes = 0
    var transferFlowDidFinish_calledTimes = 0
    var prepareTransfersWidget_calledTimes = 0
    var downloadOutcome_receivedTimes = 0
    var lastDownloadOutcome: CancellableDownloadOutcome?

    /// Fired by every terminal callback so tests can await the asynchronous flow instead of polling.
    /// Awaiting one specific outcome would hang the run when a regression takes another branch.
    var onTerminalCallback: (() -> Void)?

    nonisolated init() { }
    
    func showTransfersAlert() {
        showTransfersAlert_calledTimes += 1
        showTransfersAlertHandler?()
    }
    
    func transferSuccess(with message: String, dismiss: Bool, downloadOutcome: CancellableDownloadOutcome?) {
        transferSuccess_calledTimes += 1
        if let downloadOutcome {
            downloadOutcome_receivedTimes += 1
            lastDownloadOutcome = downloadOutcome
        }
        onTerminalCallback?()
    }

    func transferCancelled(with message: String, dismiss: Bool) {
        transferCancelled_calledTimes += 1
        onTerminalCallback?()
    }

    func transferFailed(error: String, dismiss: Bool) {
        transferFailed_calledTimes += 1
        onTerminalCallback?()
    }

    func transferCompletedWithError(error: String, dismiss: Bool) {
        transferCompletedWithError_calledTimes += 1
        onTerminalCallback?()
    }

    func transferFlowDidFinish() {
        transferFlowDidFinish_calledTimes += 1
        transferFlowDidFinishHandler?()
    }
    
    func prepareTransfersWidget() {
        prepareTransfersWidget_calledTimes += 1
    }
}

@Suite("CancellableTransferViewModel download outcome")
@MainActor
struct CancellableTransferDownloadOutcomeTests {

    @Test("Reports saved when a download is already in Offline")
    func reportsSavedWhenAlreadyDownloaded() async {
        let router = MockCancellableTransferRouter()
        let sut = makeSUT(router: router, result: .failure(.alreadyDownloaded), transferCount: 2)

        await awaitCompletion(router: router, sut: sut)

        #expect(router.downloadOutcome_receivedTimes == 1)
        #expect(router.lastDownloadOutcome == .saved)
    }

    @Test("Reports saved when a download is copied from the temp cache")
    func reportsSavedWhenCopiedFromTempFolder() async {
        let router = MockCancellableTransferRouter()
        let sut = makeSUT(router: router, result: .failure(.copiedFromTempFolder), transferCount: 1)

        await awaitCompletion(router: router, sut: sut)

        #expect(router.lastDownloadOutcome == .saved)
    }

    @Test("Reports transferQueued when the transfers actually queue")
    func reportsTransferQueuedWhenTransfersQueue() async {
        let router = MockCancellableTransferRouter()
        // `.complete` so the transfers register as started. `.none` would never satisfy
        // `fileTransfersStarted()`, so completion would never be reached.
        let sut = makeSUT(router: router, result: .success(TransferEntity(nodeHandle: 1, state: .complete)), transferCount: 2)

        await awaitCompletion(router: router, sut: sut)

        #expect(router.lastDownloadOutcome == .transferQueued)
    }

    @Test("Does not report an outcome when the download fails")
    func doesNotReportOutcomeOnFailure() async {
        let router = MockCancellableTransferRouter()
        let sut = makeSUT(router: router, result: .failure(.couldNotFindNodeByHandle), transferCount: 1)

        await awaitCompletion(router: router, sut: sut)

        #expect(router.transferFailed_calledTimes == 1)
        #expect(router.downloadOutcome_receivedTimes == 0)
    }

    @Test("Reports no download outcome for uploads")
    func reportsNoOutcomeForUploads() {
        let router = MockCancellableTransferRouter()
        let transfer = CancellableTransfer(
            localFileURL: URL(fileURLWithPath: "PathToFile"),
            name: "file.txt",
            type: .upload
        )
        let sut = CancellableTransferViewModel(
            router: router,
            uploadFileUseCase: MockUploadFileUseCase(uploadFileResult: .success(())),
            downloadNodeUseCase: MockDownloadNodeUseCase(),
            mediaUseCase: MockMediaUseCase(),
            analyticsEventUseCase: MockAnalyticsEventUseCase(),
            overDiskQuotaChecker: MockOverDiskQuotaChecker(),
            transfers: [transfer],
            transferType: .upload
        )

        sut.dispatch(.onViewReady)

        #expect(router.transferSuccess_calledTimes == 1)
        #expect(router.downloadOutcome_receivedTimes == 0)
    }

    // MARK: - Helpers

    private func makeSUT(
        router: MockCancellableTransferRouter,
        result: Result<TransferEntity, TransferErrorEntity>,
        transferCount: Int
    ) -> CancellableTransferViewModel {
        let transfers = (0..<transferCount).map { CancellableTransfer(handle: HandleEntity($0), type: .download) }
        return CancellableTransferViewModel(
            router: router,
            uploadFileUseCase: MockUploadFileUseCase(),
            downloadNodeUseCase: MockDownloadNodeUseCase(result: result),
            mediaUseCase: MockMediaUseCase(),
            analyticsEventUseCase: MockAnalyticsEventUseCase(),
            overDiskQuotaChecker: MockOverDiskQuotaChecker(),
            transfers: transfers,
            transferType: .download
        )
    }

    /// Resumes on whichever terminal callback the view model reaches, so a regression that takes a
    /// different branch fails an expectation instead of hanging the run.
    private func awaitCompletion(
        router: MockCancellableTransferRouter,
        sut: CancellableTransferViewModel
    ) async {
        await withCheckedContinuation { continuation in
            router.onTerminalCallback = { continuation.resume() }
            sut.dispatch(.onViewReady)
        }
    }
}
