@testable import MEGA
import MEGADomain
import MEGADomainMock
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
    }
    
    @MainActor func testAction_cancelTransfer() {
        let transfer = CancellableTransfer(handle: .invalid, messageId: .invalid, chatId: .invalid, localFileURL: URL(fileURLWithPath: "PathToFile"), name: nil, appData: nil, priority: false, isFile: true, type: .download)
        let router = MockCancellableTransferRouter()
        let viewModel = makeSUT(
            router: router,
            transfers: [transfer],
            transferType: .download)
        
        test(viewModel: viewModel, action: .didTapCancelButton, expectedCommands: [.cancelling])
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
        transferType: CancellableTransferType
    ) -> CancellableTransferViewModel {
        .init(
            router: router,
            uploadFileUseCase: uploadFileUseCase,
            downloadNodeUseCase: downloadNodeUseCase,
            mediaUseCase: mediaUseCase,
            analyticsEventUseCase: analyticsEventUseCase,
            overDiskQuotaChecker: overDiskQuotaChecker,
            transfers: transfers,
            transferType: transferType
        )
    }
}

final class MockCancellableTransferRouter: CancellableTransferRouting, TransferWidgetRouting {
    var showTransfersAlert_calledTimes = 0
    var transferSuccess_calledTimes = 0
    var transferCancelled_calledTimes = 0
    var transferFailed_calledTimes = 0
    var transferCompletedWithError_calledTimes = 0
    var prepareTransfersWidget_calledTimes = 0

    nonisolated init() { }
    
    func showTransfersAlert() {
        showTransfersAlert_calledTimes += 1
    }
    
    func transferSuccess(with message: String, dismiss: Bool) {
        transferSuccess_calledTimes += 1
    }
    
    func transferCancelled(with message: String, dismiss: Bool) {
        transferCancelled_calledTimes += 1
    }
    
    func transferFailed(error: String, dismiss: Bool) {
        transferFailed_calledTimes += 1
    }
    
    func transferCompletedWithError(error: String, dismiss: Bool) {
        transferCompletedWithError_calledTimes += 1
    }
    
    func prepareTransfersWidget() {
        prepareTransfersWidget_calledTimes += 1
    }
}
