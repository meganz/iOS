import Foundation
import MEGADomain
import SwiftUI
import Combine

public final class AboutViewModel: ObservableObject {
    @Published var aboutSetting: AboutSetting
    @Published var showToggleLogsAlert = false
    @Published var showChangeApiEnvironmentAlert = false
    @Published var showApiEnvironmentChangedAlert = false
    
    private var apiEnvironmentUseCase: any APIEnvironmentUseCaseProtocol
    private var manageLogsUseCase: any ManageLogsUseCaseProtocol
    
    @PreferenceWrapper(key: .logging, defaultValue: false)
    private var isLoggingEnabled: Bool
    
    public init(preferenceUC: any PreferenceUseCaseProtocol,
                apiEnvironmentUC: any APIEnvironmentUseCaseProtocol,
                manageLogsUC: any ManageLogsUseCaseProtocol,
                aboutSetting: AboutSetting) {
        apiEnvironmentUseCase = apiEnvironmentUC
        manageLogsUseCase = manageLogsUC
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
}
