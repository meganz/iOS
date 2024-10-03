import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import MEGATest
import XCTest

final class ReportIssueViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    private let defaultTransferEntity = TransferEntity(fileName: "test.log")
    private let emptyDetails = ""
    private let placeholderDetails = "Describe the issue with at least 10 characters"
    private let validDetails = "Some issue details"
    private let defaultTitle = Strings.Localizable.Help.ReportIssue.Success.title
    private let defaultMessage = Strings.Localizable.Help.ReportIssue.Success.message
    private let defaultButtonTitle = Strings.Localizable.ok
    private let defaultFileURL = URL(string: "file://testFile")!
    
    @MainActor
    private func makeSUT(
        connectionSequence: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        connected: Bool = true,
        connectedViaWiFi: Bool = false,
        uploadFileResult: Result<Void, TransferErrorEntity>? = nil,
        uploadSupportFileResult: Result<TransferEntity, TransferErrorEntity>? = nil,
        supportResult: Result<Void, any Error> = .failure(GenericErrorEntity()),
        cancelTransferResult: Result<Void, TransferErrorEntity> = .failure(.generic),
        areLogsEnabled: Bool = false,
        sourceUrl: URL? = nil,
        transfer: TransferEntity? = nil,
        totalBytes: Int = 1,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (ReportIssueViewModel, MockReportIssueViewRouter) {
        let router: some ReportIssueViewRouting = MockReportIssueViewRouter()
        let monitorUseCase = MockNetworkMonitorUseCase(
            connected: connected,
            connectedViaWiFi: connectedViaWiFi,
            connectionSequence: connectionSequence
        )
        let uploadFileUseCase = MockUploadFileUseCase(
            uploadFileResult: uploadFileResult,
            uploadSupportFileResult: uploadSupportFileResult,
            cancelTransferResult: cancelTransferResult,
            transfer: transfer,
            totalBytes: totalBytes
        )
        let supportUseCase = MockSupportUseCase(createSupportTicketResult: supportResult)
        let accountUseCase = MockAccountUseCase()
        
        let sut = ReportIssueViewModel(
            router: router,
            uploadFileUseCase: uploadFileUseCase,
            supportUseCase: supportUseCase,
            monitorUseCase: monitorUseCase,
            accountUseCase: accountUseCase,
            areLogsEnabled: areLogsEnabled,
            sourceUrl: sourceUrl
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, router as! MockReportIssueViewRouter)
    }
    
    @MainActor
    private func assertAlertData(
        _ alertData: ReportIssueAlertDataModel,
        title: String,
        message: String,
        buttonTitle: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(alertData.title, title, file: file, line: line)
        XCTAssertEqual(alertData.message, message, file: file, line: line)
        XCTAssertEqual(alertData.primaryButtonTitle, buttonTitle, file: file, line: line)
    }

    @MainActor
    private func setDetailsAndAssert(
        _ sut: ReportIssueViewModel,
        details: String,
        shouldDisableSendButton: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        sut.details = details
        XCTAssertEqual(sut.shouldDisableSendButton, shouldDisableSendButton, file: file, line: line)
    }

    @MainActor
    func testShouldDisableSendButton_detailsEmpty_isTrue() {
        let (sut, _) = makeSUT()
        setDetailsAndAssert(sut, details: emptyDetails, shouldDisableSendButton: true)
    }

    @MainActor
    func testShouldDisableSendButton_detailsEqualToPlaceholder_isTrue() {
        let (sut, _) = makeSUT()
        setDetailsAndAssert(sut, details: placeholderDetails, shouldDisableSendButton: true)
    }
    
    @MainActor
    func testShouldDisableSendButton_networkDisconnected_isTrue() {
        let (sut, _) = makeSUT(connected: false)
        XCTAssertTrue(sut.shouldDisableSendButton)
    }
    
    @MainActor
    func testShouldDisableSendButton_allConditionsMet_isFalse() {
        let (sut, _) = makeSUT()
        sut.details = validDetails
        sut.isConnected = true
        XCTAssertFalse(sut.shouldDisableSendButton)
    }

    @MainActor
    func testDismissReport_detailsEmpty_dismissCalledOnce() {
        let (sut, router) = makeSUT()
        sut.details = emptyDetails
        sut.dismissReport()
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    @MainActor
    func testDismissReport_detailsEqualToPlaceholder_dismissCalledOnce() {
        let (sut, router) = makeSUT()
        sut.details = placeholderDetails
        sut.dismissReport()
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }

    @MainActor
    func testDismissReport_called_dismissCalledOnce() {
        let (sut, router) = makeSUT()
        sut.dismissReport()
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    @MainActor
    func testShouldShowUploadLogFileView_conditionsMet_isTrue() {
        let (sut, _) = makeSUT()
        sut.isUploadingLog = true
        sut.areLogsEnabled = true
        sut.isSendLogFileToggleOn = true
        XCTAssertTrue(sut.shouldShowUploadLogFileView)
    }

    @MainActor
    func testShouldShowUploadLogFileView_logsDisabled_isFalse() {
        let (sut, _) = makeSUT()
        sut.isUploadingLog = true
        sut.areLogsEnabled = false
        sut.isSendLogFileToggleOn = true
        XCTAssertFalse(sut.shouldShowUploadLogFileView)
    }
    
    @MainActor
    func testShouldShowUploadLogFileView_notUploadingLog_isFalse() {
        let (sut, _) = makeSUT()
        sut.isUploadingLog = false
        sut.areLogsEnabled = true
        sut.isSendLogFileToggleOn = true
        XCTAssertFalse(sut.shouldShowUploadLogFileView)
    }
    
    @MainActor
    func testShouldShowUploadLogFileView_sendLogFileToggleOff_isFalse() {
        let (sut, _) = makeSUT()
        sut.isUploadingLog = true
        sut.areLogsEnabled = true
        sut.isSendLogFileToggleOn = false
        XCTAssertFalse(sut.shouldShowUploadLogFileView)
    }

    @MainActor
    func testMonitorNetworkChanges_connectionChanges_isConnectedUpdated() async {
        var results = [false, true, true, false]
        let stream = AsyncStream { continuation in
            results.forEach { continuation.yield($0) }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let (sut, _) = makeSUT(connectionSequence: stream)
        sut.$isConnected.dropFirst().sink {
            XCTAssertEqual($0, results.removeFirst())
        }.store(in: &subscriptions)
        sut.monitorNetworkChanges()
    }
    
    @MainActor
    func testCreateTicket_uploadSupportFileFails_showsAlert() async {
        let (sut, _) = makeSUT(
            uploadSupportFileResult: .success(defaultTransferEntity),
            supportResult: .failure(ReportErrorEntity.tooManyRequest),
            areLogsEnabled: true,
            sourceUrl: defaultFileURL,
            transfer: defaultTransferEntity
        )
        
        await sut.createTicket()
        
        XCTAssertTrue(sut.showingReportIssueAlert)
        XCTAssertEqual(sut.reportAlertType, .createSupportTicketTooManyRequestFailure)
        
        assertAlertData(
            sut.reportIssueAlertData(),
            title: Strings.Localizable.Help.ReportIssue.Fail.Too.Many.Request.title,
            message: Strings.Localizable.Help.ReportIssue.Fail.Too.Many.Request.message,
            buttonTitle: Strings.Localizable.ok
        )
    }
    
    @MainActor
    func testUploadLogFileIfNeeded_logsEnabled_sourceUrlNil_doesNotUploadFile() async {
        let (sut, _) = makeSUT(
            uploadSupportFileResult: .success(defaultTransferEntity),
            supportResult: .success,
            areLogsEnabled: true,
            transfer: defaultTransferEntity
        )
        
        await sut.createTicket()
        
        XCTAssertFalse(sut.isUploadingLog)
        XCTAssertTrue(sut.reportAlertType == .createSupportTicketFinished)
        
        assertAlertData(
            sut.reportIssueAlertData(),
            title: defaultTitle,
            message: defaultMessage,
            buttonTitle: defaultButtonTitle
        )
    }
    
    @MainActor
    func testUploadLogFileIfNeeded_logsEnabledAndToggleOn_uploadsFile() async {
        let (sut, _) = makeSUT(
            uploadSupportFileResult: .success(defaultTransferEntity),
            supportResult: .success,
            areLogsEnabled: true,
            sourceUrl: defaultFileURL,
            transfer: defaultTransferEntity
        )
        
        let expectation = self.expectation(description: "Log file upload completed")
        
        sut.$isUploadingLog
            .dropFirst()
            .sink { isUploadingLog in
                if !isUploadingLog {
                    expectation.fulfill()
                }
            }
            .store(in: &subscriptions)
        
        await sut.createTicket()
        
        await fulfillment(of: [expectation], timeout: 3)
        XCTAssertFalse(sut.isUploadingLog)
        XCTAssertEqual(sut.progress, 1)
        XCTAssertTrue(sut.reportAlertType == .createSupportTicketFinished)
    }
   
    @MainActor
    func testUploadLogFileIfNeeded_logsDisabled_doesNotUploadFile() async {
        let uploadFileResult: Result<Void, TransferErrorEntity> = .success
        let (sut, _) = makeSUT(uploadFileResult: uploadFileResult)
        
        sut.areLogsEnabled = false
        sut.isSendLogFileToggleOn = true
        
        await sut.createTicket()
        
        XCTAssertFalse(sut.isUploadingLog)
    }
   
    @MainActor
    func testUploadLogFileIfNeeded_uploadFails_showsAlert() async {
        let (sut, _) = makeSUT(
            uploadSupportFileResult: .failure(.generic),
            areLogsEnabled: true,
            sourceUrl: defaultFileURL
        )
        
        let expectation = self.expectation(description: "Upload failure shows alert")
        
        sut.$showingReportIssueAlert
            .dropFirst()
            .sink { showingAlert in
                if showingAlert {
                    expectation.fulfill()
                }
            }
            .store(in: &subscriptions)
        
        await sut.createTicket()
        
        await fulfillment(of: [expectation], timeout: 3)
        XCTAssertFalse(sut.isUploadingLog)
        XCTAssertEqual(sut.reportAlertType, .uploadLogFileFailure)
        
        assertAlertData(
            sut.reportIssueAlertData(),
            title: Strings.Localizable.somethingWentWrong,
            message: Strings.Localizable.Help.ReportIssue.Fail.message,
            buttonTitle: Strings.Localizable.ok
        )
    }
    
    @MainActor
    func testCancelUploadReport_uploadInProgress_cancelSucceeds() async throws {
        let (sut, router) = makeSUT(
            uploadSupportFileResult: .success(defaultTransferEntity),
            cancelTransferResult: .success,
            sourceUrl: defaultFileURL,
            transfer: defaultTransferEntity
        )
        
        sut.areLogsEnabled = true
        sut.isSendLogFileToggleOn = true
        
        let createTicketExpectation = self.expectation(description: "Create ticket in progress")
        
        Task {
            await sut.createTicket()
            createTicketExpectation.fulfill()
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        await sut.cancelUploadReport()
        
        XCTAssertEqual(router.dismiss_calledTimes, 0)
        
        await fulfillment(of: [createTicketExpectation], timeout: 3)
    }
    
    @MainActor
    func testCancelUploadReport_uploadFails_dismissCalledOnce() async throws {
        let (sut, router) = makeSUT(
            uploadSupportFileResult: .success(defaultTransferEntity),
            cancelTransferResult: .failure(.generic),
            sourceUrl: defaultFileURL,
            transfer: defaultTransferEntity
        )
        
        sut.areLogsEnabled = true
        sut.isSendLogFileToggleOn = true
        
        let createTicketExpectation = self.expectation(description: "Create ticket in progress")
        
        Task {
            await sut.createTicket()
            createTicketExpectation.fulfill()
        }
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        await sut.cancelUploadReport()
        
        XCTAssertEqual(router.dismiss_calledTimes, 1)
        
        await fulfillment(of: [createTicketExpectation], timeout: 3)
    }
    
    @MainActor
    func testCancelUploadReport_noTransfer_dismissCalled() async {
        let (sut, router) = makeSUT()
        
        let noTransferExpectation = self.expectation(description: "No transfer, dismiss called")
        
        await sut.cancelUploadReport()
        
        XCTAssertEqual(router.dismiss_calledTimes, 1)
        noTransferExpectation.fulfill()
        
        await fulfillment(of: [noTransferExpectation], timeout: 2)
    }

    @MainActor
    func testShowReportIssueActionSheetIfNeeded_discardable_showsActionSheet() async {
        let (sut, _) = makeSUT()
        sut.details = validDetails
        
        sut.showReportIssueActionSheetIfNeeded()
        
        XCTAssertTrue(sut.showingReportIssueActionSheet)
    }

    @MainActor
    func testShowReportIssueActionSheetIfNeeded_notDiscardable_dismissesReport() async {
        let (sut, router) = makeSUT()
        sut.details = emptyDetails
        
        sut.showReportIssueActionSheetIfNeeded()
        
        XCTAssertFalse(sut.showingReportIssueActionSheet)
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }

    @MainActor
    func testShowCancelUploadReportAlert_whenCalled_setsCorrectAlertTypeAndShowsAlert() {
        let (sut, _) = makeSUT()
        
        sut.showCancelUploadReportAlert()
        
        XCTAssertEqual(sut.reportAlertType, .cancelUploadReport)
        XCTAssertTrue(sut.showingReportIssueAlert)
        
        assertAlertData(
            sut.reportIssueAlertData(),
            title: Strings.Localizable.Help.ReportIssue.Creating.Cancel.title,
            message: Strings.Localizable.Help.ReportIssue.Creating.Cancel.message,
            buttonTitle: Strings.Localizable.continue
        )
    }
    
    @MainActor
    func testReportIssueAlertData_none_returnsEmptyAlertData() {
        let (sut, _) = makeSUT()
        
        let alertData = sut.reportIssueAlertData()
        
        XCTAssertTrue(alertData.title.isEmpty)
        XCTAssertTrue(alertData.message.isEmpty)
        XCTAssertTrue(alertData.primaryButtonTitle.isEmpty)
    }

    @MainActor
    func testIsReportDiscardable_detailsEmpty_isFalse() {
        let (sut, _) = makeSUT()
        
        sut.details = emptyDetails
        
        XCTAssertFalse(sut.isReportDiscardable)
    }

    @MainActor
    func testIsReportDiscardable_detailsEqualToPlaceholder_isFalse() {
        let (sut, _) = makeSUT()
        
        sut.details = placeholderDetails
        
        XCTAssertFalse(sut.isReportDiscardable)
    }

    @MainActor
    func testIsReportDiscardable_detailsNotEmptyAndNotPlaceholder_isTrue() {
        let (sut, _) = makeSUT()
        
        sut.details = validDetails
        
        XCTAssertTrue(sut.isReportDiscardable)
    }
    
    @MainActor
    func testUploadSupportFile_progress_updatesProgress() async throws {
        let transferEntity = TransferEntity(transferredBytes: 0, totalBytes: 4, fileName: "test.log")
        let uploadSupportFileResult: Result<TransferEntity, TransferErrorEntity> = .success(transferEntity)
        let (sut, _) = makeSUT(
            uploadSupportFileResult: uploadSupportFileResult,
            areLogsEnabled: true,
            sourceUrl: defaultFileURL,
            transfer: transferEntity,
            totalBytes: 4
        )
        let exp = self.expectation(description: "Progress updated")
        
        var progressValues = [Float]()
        
        sut.$progress
            .dropFirst()
            .sink { progress in
                progressValues.append(progress)
                if progress == 1 {
                    exp.fulfill()
                }
            }
            .store(in: &subscriptions)
        
        await sut.createTicket()
        
        await fulfillment(of: [exp], timeout: 5)
        XCTAssertEqual(sut.progress, 1)
        XCTAssertEqual(progressValues.count, 4)
        XCTAssertEqual(progressValues, [0.25, 0.5, 0.75, 1])
    }
}

final class MockReportIssueViewRouter: ReportIssueViewRouting {
    var dismiss_calledTimes = 0

    func dismiss() {
        dismiss_calledTimes += 1
    }
}
