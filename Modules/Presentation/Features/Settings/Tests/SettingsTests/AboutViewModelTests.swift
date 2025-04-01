import MEGADomain
import MEGADomainMock
import MEGAL10n
@testable import Settings
import XCTest

final class AboutViewModeTests: XCTestCase {
    private var preferenceUC: MockPreferenceUseCase!
    private var apiEnvironmentUC: MockAPIEnvironmentUseCase!
    private var manageLogsUC: MockManageLogsUseCase!
    private var changeSfuServerUC: MockChangeSfuServerUseCase!
    private var aboutVM: AboutViewModel!
    
    private func configureViewModel(enableLogs: Bool) {
        preferenceUC = MockPreferenceUseCase(dict: [.logging: enableLogs])
        apiEnvironmentUC = MockAPIEnvironmentUseCase()
        manageLogsUC = MockManageLogsUseCase()
        changeSfuServerUC = MockChangeSfuServerUseCase()
        
        aboutVM = AboutViewModel(preferenceUC: preferenceUC, apiEnvironmentUC: apiEnvironmentUC, manageLogsUC: manageLogsUC, changeSfuServerUC: changeSfuServerUC, appBundle: .main, systemVersion: "", deviceName: "")
    }
    
    func testShouldEnableLogs_toggleLogsAlertText() throws {
        configureViewModel(enableLogs: true)

        XCTAssertEqual(Strings.Localizable.disableDebugModeTitle, aboutVM.titleForLogsAlert())
        XCTAssertEqual(Strings.Localizable.disableDebugModeMessage, aboutVM.messageForLogsAlert())
    }
    
    func testShouldDisableLogs_toggleLogsAlertText() throws {
        configureViewModel(enableLogs: false)

        XCTAssertEqual(Strings.Localizable.enableDebugModeTitle, aboutVM.titleForLogsAlert())
        XCTAssertEqual(Strings.Localizable.enableDebugModeMessage, aboutVM.messageForLogsAlert())
    }
}
