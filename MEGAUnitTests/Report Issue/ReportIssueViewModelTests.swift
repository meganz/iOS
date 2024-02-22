import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class ReportIssueViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testCancelReport_emptyDetails() {
        let router = MockReportIssueViewRouter()
        let sut = makeReportIssueViewModel(router: router)
        
        sut.details = ""
        sut.dismissReport()
        
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    func testCancelReport_detailsSameAsPlaceholder() {
        let router = MockReportIssueViewRouter()
        let sut = makeReportIssueViewModel(router: router)
        
        sut.details = "Describe the issue"
        sut.dismissReport()
        
        XCTAssertEqual(router.dismiss_calledTimes, 1)
    }
    
    func test_disableSendButton_detailEmpty() {
        let sut = makeReportIssueViewModel()
        
        sut.details = ""
        
        XCTAssertTrue(sut.shouldDisableSendButton)
    }
    
    func test_disableSendButton_detailEqualToPlaceholder() {
        let sut = makeReportIssueViewModel()
        
        sut.details = "Describe the issue"
        
        XCTAssertTrue(sut.shouldDisableSendButton)
    }
    
    func test_disableSendButton_isNotConnected() {
        let sut = makeReportIssueViewModel()
        
        sut.isConnected = false
        
        XCTAssertTrue(sut.shouldDisableSendButton)
    }
    
    func test_shouldShowUploadLogFileView() {
        let sut = makeReportIssueViewModel()
        
        sut.isUploadingLog = true
        sut.areLogsEnabled = true
        sut.isSendLogFileToggleOn = true
        
        XCTAssertTrue(sut.shouldShowUploadLogFileView)
    }
    
    func test_shouldNotShowUploadLogFileView_logsNotEnable() {
        let sut = makeReportIssueViewModel()
        
        sut.isUploadingLog = true
        sut.areLogsEnabled = false
        sut.isSendLogFileToggleOn = true
        
        XCTAssertFalse(sut.shouldShowUploadLogFileView)
    }
    
    func test_shouldNotShowUploadLogFileView_isNotUploadingLog() {
        let sut = makeReportIssueViewModel()
        
        sut.isUploadingLog = false
        sut.areLogsEnabled = true
        sut.isSendLogFileToggleOn = true
        
        XCTAssertFalse(sut.shouldShowUploadLogFileView)
    }
    
    func test_shouldNotShowUploadLogFileView_sendLogFileDisabled() {
        let sut = makeReportIssueViewModel()
        
        sut.isUploadingLog = true
        sut.areLogsEnabled = true
        sut.isSendLogFileToggleOn = false
        
        XCTAssertFalse(sut.shouldShowUploadLogFileView)
    }
    
    func testMonitorNetworkChanges_onConnectionChanges_shouldUpdateIsConnected() async {
        var results = [false, true, true, false]
        let stream = AsyncStream { continuation in
            results.forEach {
                continuation.yield($0)
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
        
        let networkMonitoring = MockNetworkMonitorUseCase(connectionChangedStream: stream)
        let sut = makeReportIssueViewModel(monitorUseCase: networkMonitoring)
        
        sut.$isConnected
            .dropFirst()
            .sink {
                XCTAssertEqual($0, results.removeFirst())
            }
            .store(in: &subscriptions)
        
        await sut.monitorNetworkChanges()
    }
    
    private func makeReportIssueViewModel(
        router: some ReportIssueViewRouting = MockReportIssueViewRouter(),
        uploadFileUseCase: any UploadFileUseCaseProtocol = MockUploadFileUseCase(),
        supportUseCase: any SupportUseCaseProtocol = MockSupportUseCase(),
        monitorUseCase: any NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        areLogsEnabled: Bool = false,
        sourceUrl: URL? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> ReportIssueViewModel {
        let sut = ReportIssueViewModel(router: router,
                                       uploadFileUseCase: uploadFileUseCase,
                                       supportUseCase: supportUseCase,
                                       monitorUseCase: monitorUseCase,
                                       accountUseCase: accountUseCase,
                                       areLogsEnabled: areLogsEnabled,
                                       sourceUrl: sourceUrl)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}

final class MockReportIssueViewRouter: ReportIssueViewRouting {
    var dismiss_calledTimes = 0

    func dismiss() {
        dismiss_calledTimes += 1
    }
}
