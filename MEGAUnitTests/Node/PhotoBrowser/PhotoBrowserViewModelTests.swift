@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

@MainActor
final class PhotoBrowserViewModelTests: XCTestCase {
    
    func testOnViewDidLoad_called_shouldTrackPhotoPreviewEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.dispatch(.onViewDidLoad)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [PhotoPreviewScreenEvent()])
    }
    
    func testTrackAnalyticsSaveToDeviceMenuToolbarEvent_called_shouldTrackCorrectEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.trackAnalyticsSaveToDeviceMenuToolbarEvent()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [PhotoPreviewSaveToDeviceMenuToolbarEvent()])
    }
    
    func testTrackHideNodeMenuEvent_called_shouldTrackCorrectEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        
        sut.trackHideNodeMenuEvent()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [ImagePreviewHideNodeMenuToolBarEvent()])
    }
    
    func testActionOnViewWillAppear_shouldInvokeNodesUpdateCommand() async {
        let nodeEntities = [
            NodeEntity(handle: 1),
            NodeEntity(handle: 2)
        ]
        let nodeRepository = MockNodeRepository(nodeUpdates: [nodeEntities].async.eraseToAnyAsyncSequence())
        let photoBrowserUseCase = MockPhotoBrowserUseCase(nodeRepository: nodeRepository)
        let sut = makeSUT(photoBrowserUseCase: photoBrowserUseCase)
        
        var invokedCommands = [PhotoBrowserViewModel.Command]()
        sut.invokeCommand = { command in
            invokedCommands.append(command)
        }
        
        sut.dispatch(.onViewWillAppear)
        
        var handles: [[HandleEntity]] = []
        for await nodeEntities in photoBrowserUseCase.nodeUpdates {
            handles.append(nodeEntities.map(\.handle))
        }
        
        XCTAssertEqual(handles, [[1, 2]])
        
        await test(viewModel: sut, action: .onViewWillAppear, expectedCommands: [.nodesUpdate(nodeEntities)])
    }

    func testActionOnViewWillDisappear_shouldCancelMonitorNodeUpdatesTask() {
        let sut = makeSUT()
        sut.dispatch(.onViewWillDisappear)
        XCTAssertNil(sut.monitorNodeUpdatesTask)
    }
    
    func testActionOnViewWillAppear_shouldMonitorNodeUpdatesTask() {
        let sut = makeSUT()
        sut.dispatch(.onViewWillAppear)
        XCTAssertNotNil(sut.monitorNodeUpdatesTask)
    }

    func testTrackAddToAlbumMenuItemEvent() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)
        sut.trackAddToAlbumMenuItemEvent()
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AddToAlbumMenuItemEvent()]
        )
    }

    // MARK: - Original photo download

    func testStartOriginalDownload_whenTransferUpdates_reportsTransferredFraction() async {
        let repository = MockDownloadFileRepository(downloadBatchResult: .success([
            .update(TransferEntity(transferredBytes: 5, totalBytes: 10)),
            .finish(TransferEntity(path: "/tmp/photo.jpg"))
        ]))
        let sut = makeSUT(downloadFileRepository: repository)
        var progress = [Float]()
        let finished = expectation(description: "download finished")

        sut.startOriginalDownload(
            for: MockNode(handle: 1, name: "photo.jpg"),
            destinationPath: "/tmp/photo.jpg",
            onProgress: { progress.append($0) },
            onFinish: { _ in finished.fulfill() }
        )

        await fulfillment(of: [finished], timeout: 1)
        XCTAssertEqual(progress, [0.5])
    }

    /// The SDK reports a total of zero before it knows the size, which would divide by zero.
    func testStartOriginalDownload_whenTransferHasNoTotalYet_reportsNoProgress() async {
        let repository = MockDownloadFileRepository(downloadBatchResult: .success([
            .update(TransferEntity(transferredBytes: 5, totalBytes: 0)),
            .finish(TransferEntity(path: "/tmp/photo.jpg"))
        ]))
        let sut = makeSUT(downloadFileRepository: repository)
        var progress = [Float]()
        let finished = expectation(description: "download finished")

        sut.startOriginalDownload(
            for: MockNode(handle: 1, name: "photo.jpg"),
            destinationPath: "/tmp/photo.jpg",
            onProgress: { progress.append($0) },
            onFinish: { _ in finished.fulfill() }
        )

        await fulfillment(of: [finished], timeout: 1)
        XCTAssertTrue(progress.isEmpty)
    }

    /// The path is read back from the finished transfer, since collision resolution can rename the file.
    func testStartOriginalDownload_whenTransferFinishes_reportsThePathItLandedAt() async {
        let repository = MockDownloadFileRepository(
            downloadBatchResult: .success([.finish(TransferEntity(path: "/tmp/photo (1).jpg"))])
        )
        let sut = makeSUT(downloadFileRepository: repository)
        var finishedPath: String?
        let finished = expectation(description: "download finished")

        sut.startOriginalDownload(
            for: MockNode(handle: 1, name: "photo.jpg"),
            destinationPath: "/tmp/photo.jpg",
            onProgress: { _ in },
            onFinish: {
                finishedPath = $0
                finished.fulfill()
            }
        )

        await fulfillment(of: [finished], timeout: 1)
        XCTAssertEqual(finishedPath, "/tmp/photo (1).jpg")
    }

    func testStartOriginalDownload_whenFinishedTransferHasNoPath_reportsNothing() async {
        let repository = MockDownloadFileRepository(
            downloadBatchResult: .success([.finish(TransferEntity(path: nil))])
        )
        let sut = makeSUT(downloadFileRepository: repository)
        let finished = expectation(description: "download finished")
        finished.isInverted = true

        sut.startOriginalDownload(
            for: MockNode(handle: 1, name: "photo.jpg"),
            destinationPath: "/tmp/photo.jpg",
            onProgress: { _ in },
            onFinish: { _ in finished.fulfill() }
        )

        await fulfillment(of: [finished], timeout: 0.3)
    }

    /// The batch downloads the node it was given, to exactly the path the caller asked for.
    func testStartOriginalDownload_downloadsTheNodeToTheGivenPath() async {
        let repository = MockDownloadFileRepository(
            downloadBatchResult: .success([.finish(TransferEntity(path: "/tmp/photo.jpg"))])
        )
        let sut = makeSUT(downloadFileRepository: repository)
        let finished = expectation(description: "download finished")

        sut.startOriginalDownload(
            for: MockNode(handle: 42, name: "photo.jpg"),
            destinationPath: "/tmp/originalV3/photo.jpg",
            onProgress: { _ in },
            onFinish: { _ in finished.fulfill() }
        )

        await fulfillment(of: [finished], timeout: 1)
        let items = repository.startedDownloadBatches.flatMap { $0 }
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.destination, .file(URL(fileURLWithPath: "/tmp/originalV3/photo.jpg")))
    }

    /// Every page downloads on its own, so a second start must not replace the first.
    func testStartOriginalDownload_forTwoPages_reportsBothFinishes() async {
        let repository = MockDownloadFileRepository(
            downloadBatchResult: .success([.finish(TransferEntity(path: "/tmp/photo.jpg"))])
        )
        let sut = makeSUT(downloadFileRepository: repository)
        let finished = expectation(description: "both downloads finished")
        finished.expectedFulfillmentCount = 2

        for handle in [1, 2] as [HandleEntity] {
            sut.startOriginalDownload(
                for: MockNode(handle: handle, name: "photo.jpg"),
                destinationPath: "/tmp/photo.jpg",
                onProgress: { _ in },
                onFinish: { _ in finished.fulfill() }
            )
        }

        await fulfillment(of: [finished], timeout: 1)
        XCTAssertEqual(repository.startedDownloadBatches.count, 2)
    }

    // MARK: - Helpers

    private func makeSUT(
        tracker: any AnalyticsTracking = MockTracker(),
        photoBrowserUseCase: any PhotoBrowserUseCaseProtocol = MockPhotoBrowserUseCase(),
        downloadFileRepository: MockDownloadFileRepository = MockDownloadFileRepository()
    ) -> PhotoBrowserViewModel {
        PhotoBrowserViewModel(
            tracker: tracker,
            photoBrowserUseCase: photoBrowserUseCase,
            makeDownloadUseCase: { _ in
                PhotoBrowserNodeDownloadUseCase(downloadFileRepository: downloadFileRepository)
            }
        )
    }
}
