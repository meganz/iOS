import Combine
import Foundation
import MEGADomain
import SwiftUI

public final class AboutViewModel: ObservableObject {
    @Published var aboutSetting: AboutSetting
    @Published var showToggleLogsAlert = false
    @Published var showChangeApiEnvironmentAlert = false
    @Published var showApiEnvironmentChangedAlert = false
    @Published var showSfuServerChangeAlert = false
    @Published var sfuServerId = ""

    private var apiEnvironmentUseCase: any APIEnvironmentUseCaseProtocol
    private var manageLogsUseCase: any ManageLogsUseCaseProtocol
    private var changeSfuServerUseCase: any ChangeSfuServerUseCaseProtocol

    @PreferenceWrapper(key: .logging, defaultValue: false)
    private var isLoggingEnabled: Bool
    
    public init(preferenceUC: any PreferenceUseCaseProtocol,
                apiEnvironmentUC: any APIEnvironmentUseCaseProtocol,
                manageLogsUC: any ManageLogsUseCaseProtocol,
                changeSfuServerUC: any ChangeSfuServerUseCaseProtocol,
                aboutSetting: AboutSetting) {
        apiEnvironmentUseCase = apiEnvironmentUC
        manageLogsUseCase = manageLogsUC
        changeSfuServerUseCase = changeSfuServerUC
        self.aboutSetting = aboutSetting
        $isLoggingEnabled.useCase = preferenceUC
    }
    
    func refreshToggleLogsAlertStatus() {
        showToggleLogsAlert.toggle()
    }
    
    func refreshChangeAPIEnvironmentAlertStatus() {
        showChangeApiEnvironmentAlert.toggle()
    }
    
    func toggleLogs() {
        manageLogsUseCase.toggleLogs()
    }
    
    func changeAPIEnvironment(environment: APIEnvironmentEntity) {
        apiEnvironmentUseCase.changeAPIURL(environment)
        showApiEnvironmentChangedAlert.toggle()
    }
    
    func titleForLogsAlert() -> String {
        isLoggingEnabled ? aboutSetting.toggleLogs.disableTitle : aboutSetting.toggleLogs.enableTitle
    }
    
    func messageForLogsAlert() -> String {
        isLoggingEnabled ? aboutSetting.toggleLogs.disableMessage : aboutSetting.toggleLogs.enableMessage
    }
    
    func refreshToggleSfuServerAlertStatus() {
        showSfuServerChangeAlert.toggle()
    }
    
    func changeSfuServer() {
        guard let sfuId = Int(sfuServerId) else { return }
        sfuServerId = ""
        changeSfuServerUseCase.changeSfuServer(to: sfuId)
    }
}
