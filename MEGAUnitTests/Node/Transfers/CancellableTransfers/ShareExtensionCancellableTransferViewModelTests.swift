@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

@MainActor
final class ShareExtensionCancellableTransferViewModelTests: XCTestCase {

    func testDidTapCancelButton_cancelsTheTransfersAndClosesTheFlowWithoutDismissing() {
        let router = MockCancellableTransferRouter()
        let uploadFileUseCase = MockUploadFileUseCase()
        let sut = makeSUT(router: router, uploadFileUseCase: uploadFileUseCase, transfers: [fileTransfer()])

        sut.dispatch(.onViewReady)
        sut.dispatch(.didTapCancelButton)

        XCTAssertEqual(uploadFileUseCase.cancelUploadTransfers_calledTimes, 1)
        XCTAssertEqual(router.transferCancelled_calledTimes, 1)
        // The alert dismisses itself on the button tap, so a second dismiss would never complete.
        XCTAssertEqual(router.transferCancelled_dismiss, false)
    }

    func testDidTapCancelButton_calledTwice_cancelsOnlyOnce() {
        let router = MockCancellableTransferRouter()
        let uploadFileUseCase = MockUploadFileUseCase()
        let sut = makeSUT(router: router, uploadFileUseCase: uploadFileUseCase, transfers: [fileTransfer()])

        sut.dispatch(.onViewReady)
        sut.dispatch(.didTapCancelButton)
        sut.dispatch(.didTapCancelButton)

        XCTAssertEqual(uploadFileUseCase.cancelUploadTransfers_calledTimes, 1)
        XCTAssertEqual(router.transferCancelled_calledTimes, 1)
    }

    func testOnViewReady_uploadOverStorageQuota_cancelsTheTransfersAndFailsTheFlow() {
        let router = MockCancellableTransferRouter()
        let uploadFileUseCase = MockUploadFileUseCase(uploadTemporaryError: ErrorEntity(type: .quotaExceeded))
        let sut = makeSUT(router: router, uploadFileUseCase: uploadFileUseCase, transfers: [fileTransfer()])

        sut.dispatch(.onViewReady)

        XCTAssertEqual(uploadFileUseCase.cancelUploadTransfers_calledTimes, 1)
        XCTAssertEqual(router.transferFailed_calledTimes, 1)
        // The alert is already on screen when the first upload starts, so it must be dismissed.
        XCTAssertEqual(router.transferFailed_dismiss, true)
    }

    func testOnViewReady_overStorageQuotaOnEveryTransfer_failsTheFlowOnlyOnce() {
        let router = MockCancellableTransferRouter()
        let uploadFileUseCase = MockUploadFileUseCase(uploadTemporaryError: ErrorEntity(type: .quotaExceeded))
        let sut = makeSUT(
            router: router,
            uploadFileUseCase: uploadFileUseCase,
            transfers: [fileTransfer(), fileTransfer()])

        sut.dispatch(.onViewReady)

        XCTAssertEqual(uploadFileUseCase.cancelUploadTransfers_calledTimes, 1)
        XCTAssertEqual(router.transferFailed_calledTimes, 1)
    }

    /// The SDK keeps retrying a stalled upload, so a non quota error must leave the flow running.
    func testOnViewReady_temporaryErrorThatIsNotOverQuota_keepsTheFlowRunning() {
        let router = MockCancellableTransferRouter()
        let uploadFileUseCase = MockUploadFileUseCase(uploadTemporaryError: ErrorEntity(type: .tryAgain))
        let sut = makeSUT(router: router, uploadFileUseCase: uploadFileUseCase, transfers: [fileTransfer()])

        sut.dispatch(.onViewReady)

        XCTAssertEqual(uploadFileUseCase.cancelUploadTransfers_calledTimes, 0)
        XCTAssertEqual(router.transferFailed_calledTimes, 0)
    }

    /// Cancelling is async, so the SDK can still report an over quota error after the flow closed.
    func testDidTapCancelButton_thenLateQuotaError_doesNotFailTheFlow() {
        let router = MockCancellableTransferRouter()
        let uploadFileUseCase = MockUploadFileUseCase()
        let sut = makeSUT(router: router, uploadFileUseCase: uploadFileUseCase, transfers: [fileTransfer()])

        sut.dispatch(.onViewReady)
        sut.dispatch(.didTapCancelButton)
        uploadFileUseCase.uploadFileTemporaryErrorClosure?(TransferEntity(), ErrorEntity(type: .quotaExceeded))

        XCTAssertEqual(router.transferFailed_calledTimes, 0)
        XCTAssertEqual(router.transferCancelled_calledTimes, 1)
        XCTAssertEqual(uploadFileUseCase.cancelUploadTransfers_calledTimes, 1)
    }

    // MARK: - Helpers

    private func makeSUT(
        router: MockCancellableTransferRouter = MockCancellableTransferRouter(),
        uploadFileUseCase: MockUploadFileUseCase = MockUploadFileUseCase(),
        transfers: [CancellableTransfer]
    ) -> ShareExtensionCancellableTransferViewModel {
        .init(router: router, uploadFileUseCase: uploadFileUseCase, transfers: transfers)
    }

    private func fileTransfer() -> CancellableTransfer {
        CancellableTransfer(
            localFileURL: URL(fileURLWithPath: "PathToFile"),
            isFile: true,
            type: .upload)
    }
}
