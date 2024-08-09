import Combine
import Foundation
import MEGADomain
import MEGAL10n
import SwiftUI

public final class AboutViewModel: ObservableObject {
    private enum Constants {
        static let bundleSortVersionKey = "CFBundleShortVersionString"
        static let sdkGitCommitHashKey = "SDK_GIT_COMMIT_HASH"
        static let chatSdkGitCommitHashKey = "CHAT_SDK_GIT_COMMIT_HASH"
        static let groupIdentifier = "group.mega.ios"
        static let userDefaultsKeyForLogging = "logging"
        static let extensionLogsFolder = "logs"
        
        static let sourceCodeURL = "https://github.com/meganz/iOS"
        static let acknowledgementsURL = "https://github.com/meganz/iOS3/blob/master/CREDITS.md"
    }
    
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
    private let appBundle: Bundle
    private let systemVersion: String
    private let deviceName: String

    lazy var appVersion: String = {
        guard let infoPlistDictionary = appBundle.infoDictionary,
              let bundleShortVersion = infoPlistDictionary[Constants.bundleSortVersionKey] as? String,
              let bundleVersion = infoPlistDictionary[kCFBundleVersionKey as String] as? String else { return "" }
        
        return "\(bundleShortVersion) (\(bundleVersion))"
    }()
    
    lazy var sdkVersion: String = {
        guard let infoPlistDictionary = appBundle.infoDictionary else { return "" }
        return infoPlistDictionary[Constants.sdkGitCommitHashKey] as? String ?? ""
    }()
    
    lazy var chatSdkVersion: String = {
        guard let infoPlistDictionary = appBundle.infoDictionary else { return "" }
        return infoPlistDictionary[Constants.chatSdkGitCommitHashKey] as? String ?? ""
    }()
    
    lazy var sourceCodeURL: URL = {
        URL(string: Constants.sourceCodeURL) ?? URL(fileURLWithPath: "")
    }()
    
    lazy var acknowledgementsURL: URL = {
        URL(string: Constants.acknowledgementsURL) ?? URL(fileURLWithPath: "")
    }()
    
    lazy var apiEnvironments: [APIEnvironment] = {
        [
            APIEnvironment(
                title: APIEnvironmentEntity.production.rawValue,
                environment: .production
            ),
            APIEnvironment(
                title: APIEnvironmentEntity.staging.rawValue,
                environment: .staging
            ),
            APIEnvironment(
                title: APIEnvironmentEntity.bt1444.rawValue,
                environment: .bt1444
            ),
            APIEnvironment(
                title: APIEnvironmentEntity.sandbox3.rawValue,
                environment: .sandbox3
            )
        ]
    }()
    
    public init(preferenceUC: any PreferenceUseCaseProtocol,
                apiEnvironmentUC: any APIEnvironmentUseCaseProtocol,
                manageLogsUC: any ManageLogsUseCaseProtocol,
                changeSfuServerUC: any ChangeSfuServerUseCaseProtocol,
                appBundle: Bundle,
                systemVersion: String,
                deviceName: String) {
        apiEnvironmentUseCase = apiEnvironmentUC
        manageLogsUseCase = manageLogsUC
        changeSfuServerUseCase = changeSfuServerUC
        self.appBundle = appBundle
        self.systemVersion = systemVersion
        self.deviceName = deviceName
        $isLoggingEnabled.useCase = preferenceUC
    }
    
    func refreshToggleLogsAlertStatus() {
        showToggleLogsAlert.toggle()
    }
    
    func refreshChangeAPIEnvironmentAlertStatus() {
        showChangeApiEnvironmentAlert.toggle()
    }
    
    func toggleLogs() {
        manageLogsUseCase.toggleLogs(
            with: LogMetadataEntity(
                suiteName: Constants.groupIdentifier,
                key: Constants.userDefaultsKeyForLogging,
                version: appVersion,
                systemVersion: systemVersion,
                language: selectedLanguage() ?? "",
                deviceName: deviceName,
                timezoneName: TimeZone.current.identifier,
                extensionLogsFolder: Constants.extensionLogsFolder
            )
        )
    }
    
    func changeAPIEnvironment(environment: APIEnvironmentEntity) {
        apiEnvironmentUseCase.changeAPIURL(environment)
        showApiEnvironmentChangedAlert.toggle()
    }
    
    func titleForLogsAlert() -> String {
        isLoggingEnabled ? Strings.Localizable.disableDebugModeTitle : Strings.Localizable.enableDebugModeTitle
    }
    
    func messageForLogsAlert() -> String {
        isLoggingEnabled ? Strings.Localizable.disableDebugModeMessage : Strings.Localizable.enableDebugModeMessage
    }
    
    func refreshToggleSfuServerAlertStatus() {
        showSfuServerChangeAlert.toggle()
    }
    
    func changeSfuServer() {
        guard let sfuId = Int(sfuServerId) else { return }
        sfuServerId = ""
        changeSfuServerUseCase.changeSfuServer(to: sfuId)
    }
    
    // MARK: - Private methods.
    
    private func selectedLanguage() -> String? {
        guard let preferredLocalization =  Bundle.main.preferredLocalizations.first else { return nil }
        return Locale.current.localizedString(forLanguageCode: preferredLocalization)
    }
}
