import XCTest
import Combine
import MEGADomainMock
import MEGADomain
@testable import MEGA

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
        sut.dismissReport()
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
        sut.dismissReport()
        XCTAssertEqual(mockRouter.dismiss_calledTimes, 1)
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

    func dismiss() {
        dismiss_calledTimes += 1
    }
}
