@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ReportIssueMessageViewModelTests: XCTestCase {
    
    func testGenerateReportIssueMessage_whenInjected_FormatMessageWithFileName() async {
        let filename: String? = "any-file-name"
        let sut = ReportIssueMessageViewModel(accountUseCase: mockAccountUseCase(), appMetaData: mockAppMetaData(), deviceMetaData: mockDeviceMetaData())
        
        let result = await sut.generateReportIssueMessage(message: anyMessageDetail(), filename: filename)
        
        XCTAssertEqual(result, expectedStringFormat(filename: filename))
    }
    
    func testGenerateReportIssueMessage_whenInjected_FormatMessageWithoutFilename() async {
        let noFileName: String? = nil
        let sut = ReportIssueMessageViewModel(accountUseCase: mockAccountUseCase(), appMetaData: mockAppMetaData(), deviceMetaData: mockDeviceMetaData())
        
        let result = await sut.generateReportIssueMessage(message: anyMessageDetail(), filename: noFileName)
        
        XCTAssertEqual(result, expectedStringFormat(filename: noFileName))
    }
    
    // MARK: - Helpers
    
    private func mockAccountUseCase() -> any AccountUseCaseProtocol {
        MockAccountUseCase(
            currentAccountDetails: AccountDetailsEntity.build(
                proLevel: .free
            ),
            email: anyEmail()
        )
    }
    
    private func accountDetailsEntity(accountType: AccountTypeEntity) -> AccountDetailsEntity {
        AccountDetailsEntity.build(storageUsed: 0, versionsStorageUsed: 0, storageMax: 0, transferUsed: 0, transferMax: 0, proLevel: accountType, proExpiration: 0, subscriptionStatus: .none, subscriptionRenewTime: 0, subscriptionMethod: nil, subscriptionCycle: .none, numberUsageItems: 0)
    }
    
    private func mockAppMetaData() -> AppMetaData {
        AppMetaData(appName: appName(), currentAppVersion: appVersion(), currentSDKVersion: sdkVersion())
    }
    
    private func mockDeviceMetaData() -> DeviceMetaData {
        DeviceMetaData(deviceName: deviceName(), osVersion: iosVersion(), language: language())
    }
    
    private func appName() -> String {
        "MEGA"
    }
    
    private func deviceName() -> String {
        "iPhone 14"
    }
    
    private func iosVersion() -> String {
        "iOS 16"
    }
    
    private func language() -> String {
        "English"
    }
    
    private func appVersion() -> String {
        "10.1"
    }
    
    private func sdkVersion() -> String {
        "4.4.0"
    }
    
    private func anyAccountType() -> String {
        "Free"
    }
    
    private func expectedStringFormat(filename: String?) -> String {
        let expected = """
        \(anyMessageDetail())
                               
        Report filename: \(filename ?? "No log file")
        
        Account Information:
        Email: anyperson@mega.co.nz
        Type: Free
        
        App Information:
        App name: MEGA
        App version: 10.1
        Sdk version: 4.4.0
        
        Device Information:
        Device: \(deviceName())
        iOS Version: \(iosVersion())
        Language: \(language())
        """.trimmingCharacters(in: .newlines)
        
        return expected
    }
    
    private func anyMessageDetail() -> String {
        "any-message-detail"
    }
    
    private func anyEmail() -> String {
        "anyperson@mega.co.nz"
    }

}
