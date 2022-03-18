import XCTest
import Combine
@testable import MEGA

@available(iOS 14.0, *)
final class ReportIssueViewModelTests: XCTestCase {
    let mockRouter = MockReportIssueViewRouter()
    
    func testCancelReport_emptyDetails() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.details = ""
        sut.cancelReport()
        XCTAssertEqual(mockRouter.dismiss_calledTimes, 1)
    }
    
    func testCancelReport_detailsSameAsPlaceholder() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.details = "Describe the issue"
        sut.cancelReport()
        XCTAssertEqual(mockRouter.dismiss_calledTimes, 1)
    }
    
    func testCancelReport_detailsAreNotEmpty() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.details = "Details for the issue"
        sut.cancelReport()
        XCTAssertEqual(mockRouter.discardReportAlert_calledTimes, 1)
    }
    
    func testCreateReport_logsDisabled_fail() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.details = "Details for the issue"
        sut.createTicket()
        XCTAssertEqual(mockRouter.showFailAlert_calledTimes, 1)
    }
    
    func testCreateReport_logsDisabled_success() {
        let createSupportTicket = Future<Void, CreateSupportTicketErrorEntity> { promise in
            promise(.success(()))
        }
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(createSupportTicket: createSupportTicket),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.details = "Details for the issue"
        sut.createTicket()
        XCTAssertEqual(mockRouter.showSuccessAlert_calledTimes, 1)
    }
    
    func testCancelUploadReport() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.details = "Details for the issue"
        sut.cancelUploadReport()
        XCTAssertEqual(mockRouter.cancelUploadReport_calledTimes, 1)
    }
    
    func test_disableSendButton_detailEmpty() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.details = ""
        XCTAssertTrue(sut.shouldDisableSendButton)
    }
    
    func test_disableSendButton_detailEqualToPlaceholder() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.details = "Describe the issue"
        XCTAssertTrue(sut.shouldDisableSendButton)
    }
    
    func test_disableSendButton_isNotConnected() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.isConnected = false
        XCTAssertTrue(sut.shouldDisableSendButton)
    }
    
    func test_isShowingPlaceholder() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.details = "Describe the issue"
        XCTAssertTrue(sut.isShowingPlaceholder)
    }
    
    func test_isNotShowingPlaceholder() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.details = "Describe for the issue"
        XCTAssertFalse(sut.isShowingPlaceholder)
    }
    
    func test_shouldShowUploadLogFileView() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.isUploadingLog = true
        sut.areLogsEnabled = true
        sut.isSendLogFileToggleOn = true
        XCTAssertTrue(sut.shouldShowUploadLogFileView)
    }
    
    func test_shouldNotShowUploadLogFileView_logsNotEnable() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.isUploadingLog = true
        sut.areLogsEnabled = false
        sut.isSendLogFileToggleOn = true
        XCTAssertFalse(sut.shouldShowUploadLogFileView)
    }
    
    func test_shouldNotShowUploadLogFileView_isNotUplaodingLog() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.isUploadingLog = false
        sut.areLogsEnabled = true
        sut.isSendLogFileToggleOn = true
        XCTAssertFalse(sut.shouldShowUploadLogFileView)
    }
    
    func test_shouldNotShowUploadLogFileView_sendLogFileDisabled() {
        let sut = ReportIssueViewModel(router: mockRouter,
                                       uploadFileUseCase: MockUploadFileUseCase(),
                                       supportUseCase: MockSupportUseCase(),
                                       monitorUseCase: MockNetworkMonitorUseCase(),
                                       areLogsEnabled: false,
                                       sourceUrl: nil)
        sut.isUploadingLog = true
        sut.areLogsEnabled = true
        sut.isSendLogFileToggleOn = false
        XCTAssertFalse(sut.shouldShowUploadLogFileView)
    }
}


final class MockReportIssueViewRouter: ReportIssueViewRouting {
    var dismiss_calledTimes = 0
    var showSuccessAlert_calledTimes = 0
    var showFailAlert_calledTimes = 0
    var discardReportAlert_calledTimes = 0
    var cancelUploadReport_calledTimes = 0
    
    func dismiss() {
        dismiss_calledTimes += 1
    }
    
    func showAlert(title: String, message: String) {
        if title == Strings.Localizable.somethingWentWrong {
            showFailAlert_calledTimes += 1
        } else {
            showSuccessAlert_calledTimes += 1
        }
    }
    
    func discardReportAlert() {
        discardReportAlert_calledTimes += 1
    }
    
    func cancelUploadReport(completion: @escaping (Bool) -> Void) {
        cancelUploadReport_calledTimes += 1
    }
}
