@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import XCTest

@MainActor
final class PreviewDocumentViewModelTests: XCTestCase {

    // MARK: - Progress

    func testStart_whenTransferUpdates_reportsTransferredFraction() async {
        let useCase = MockDownloadNodeUseCase(transferEvents: [
            .update(TransferEntity(transferredBytes: 5, totalBytes: 10)),
            .finish(TransferEntity(path: "/tmp/file.pdf"))
        ])
        let sut = makeSUT(useCase: useCase)
        var progress = [Float]()
        let finished = expectation(description: "download finished")

        sut.start(onProgress: { progress.append($0) }, onStalled: {}, onFinish: { _ in finished.fulfill() })

        await fulfillment(of: [finished], timeout: 1)
        XCTAssertEqual(progress, [0.5])
    }

    /// The SDK reports a total of zero before it knows the size, which would divide by zero.
    func testStart_whenTransferHasNoTotalYet_reportsNoProgress() async {
        let useCase = MockDownloadNodeUseCase(transferEvents: [
            .update(TransferEntity(transferredBytes: 5, totalBytes: 0)),
            .finish(TransferEntity(path: "/tmp/file.pdf"))
        ])
        let sut = makeSUT(useCase: useCase)
        var progress = [Float]()
        let finished = expectation(description: "download finished")

        sut.start(onProgress: { progress.append($0) }, onStalled: {}, onFinish: { _ in finished.fulfill() })

        await fulfillment(of: [finished], timeout: 1)
        XCTAssertTrue(progress.isEmpty)
    }

    // MARK: - Stalled

    func testStart_whenQuotaTemporaryError_reportsStalled() async {
        let useCase = MockDownloadNodeUseCase(transferEvents: [
            .temporaryError(TransferEntity(), ErrorEntity(type: .quotaExceeded)),
            .finish(TransferEntity(path: "/tmp/file.pdf"))
        ])
        let sut = makeSUT(useCase: useCase)
        var stalledCount = 0
        let finished = expectation(description: "download finished")

        sut.start(onProgress: { _ in }, onStalled: { stalledCount += 1 }, onFinish: { _ in finished.fulfill() })

        await fulfillment(of: [finished], timeout: 1)
        XCTAssertEqual(stalledCount, 1)
    }

    /// The SDK retries every other temporary error on its own, so the download has not stopped moving.
    func testStart_whenOtherTemporaryError_doesNotReportStalled() async {
        let useCase = MockDownloadNodeUseCase(transferEvents: [
            .temporaryError(TransferEntity(), ErrorEntity(type: .tryAgain)),
            .finish(TransferEntity(path: "/tmp/file.pdf"))
        ])
        let sut = makeSUT(useCase: useCase)
        var stalledCount = 0
        let finished = expectation(description: "download finished")

        sut.start(onProgress: { _ in }, onStalled: { stalledCount += 1 }, onFinish: { _ in finished.fulfill() })

        await fulfillment(of: [finished], timeout: 1)
        XCTAssertEqual(stalledCount, 0)
    }

    // MARK: - Finish

    /// The path is read back from the finished transfer, since collision resolution can rename the file.
    func testStart_whenTransferFinishes_reportsThePathItLandedAt() async {
        let useCase = MockDownloadNodeUseCase(transferEvents: [.finish(TransferEntity(path: "/tmp/file (1).pdf"))])
        let sut = makeSUT(useCase: useCase)
        var finishedPath: String?
        let finished = expectation(description: "download finished")

        sut.start(onProgress: { _ in }, onStalled: {}, onFinish: {
            finishedPath = $0
            finished.fulfill()
        })

        await fulfillment(of: [finished], timeout: 1)
        XCTAssertEqual(finishedPath, "/tmp/file (1).pdf")
    }

    func testStart_whenFinishedTransferHasNoPath_reportsNothing() async {
        let useCase = MockDownloadNodeUseCase(transferEvents: [.finish(TransferEntity(path: nil))])
        let sut = makeSUT(useCase: useCase)
        let finished = expectation(description: "download finished")
        finished.isInverted = true

        sut.start(onProgress: { _ in }, onStalled: {}, onFinish: { _ in finished.fulfill() })

        await fulfillment(of: [finished], timeout: 0.3)
    }

    // MARK: - Node

    /// The node is handed over whole: a link's node is in no tree the data layer could look it up in.
    func testStart_downloadsTheNodeItWasGiven() async {
        let useCase = MockDownloadNodeUseCase(transferEvents: [.finish(TransferEntity(path: "/tmp/file.pdf"))])
        let sut = makeSUT(node: MockNode(handle: 42, name: "file.pdf"), useCase: useCase)
        let finished = expectation(description: "download finished")

        sut.start(onProgress: { _ in }, onStalled: {}, onFinish: { _ in finished.fulfill() })

        await fulfillment(of: [finished], timeout: 1)
        XCTAssertEqual(useCase.downloadedNodes.map(\.handle), [42])
    }

    func testStart_withoutNode_downloadsNothing() {
        let useCase = MockDownloadNodeUseCase(transferEvents: [])
        let sut = makeSUT(node: nil, useCase: useCase)

        sut.start(onProgress: { _ in }, onStalled: {}, onFinish: { _ in })

        XCTAssertTrue(useCase.downloadedNodes.isEmpty)
    }

    // MARK: - Cancel

    func testCancel_afterStart_cancelsTheDownloadTransfers() async {
        let useCase = MockDownloadNodeUseCase(transferEvents: [.finish(TransferEntity(path: "/tmp/file.pdf"))])
        let sut = makeSUT(useCase: useCase)
        let finished = expectation(description: "download finished")
        sut.start(onProgress: { _ in }, onStalled: {}, onFinish: { _ in finished.fulfill() })
        await fulfillment(of: [finished], timeout: 1)

        sut.cancel()

        XCTAssertEqual(useCase.cancelDownloadTransfers_calledTimes, 1)
    }

    /// Nothing was started, so there is no use case to cancel and the call must still be safe.
    func testCancel_withoutStart_doesNothing() {
        let useCase = MockDownloadNodeUseCase(transferEvents: [])
        let sut = makeSUT(useCase: useCase)

        sut.cancel()

        XCTAssertEqual(useCase.cancelDownloadTransfers_calledTimes, 0)
    }

    // MARK: - Helpers

    private func makeSUT(
        node: MEGANode? = MockNode(handle: 1, name: "file.pdf"),
        useCase: MockDownloadNodeUseCase
    ) -> PreviewDocumentViewModel {
        PreviewDocumentViewModel(node: node, makeDownloadNodeUseCase: { _ in useCase })
    }
}
