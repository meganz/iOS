import Foundation

public struct AboutSetting {
    public var appVersion: AppVersion
    public var sdkVersion: AppVersion
    public var chatSdkVersion: AppVersion
    public var viewSourceLink: SettingsLink
    public var acknowledgementsLink: SettingsLink
    public var apiEnvironment: APIEnvironmentChangingAlert
    public var toggleLogs: LogTogglingAlert

    public init(appVersion: AppVersion, sdkVersion: AppVersion, chatSDKVersion: AppVersion, viewSourceLink: SettingsLink, acknowledgementsLink: SettingsLink, apiEnvironment: APIEnvironmentChangingAlert, toggleLogs: LogTogglingAlert) {
        self.appVersion = appVersion
        self.sdkVersion = sdkVersion
        self.chatSdkVersion = chatSDKVersion
        self.viewSourceLink = viewSourceLink
        self.acknowledgementsLink = acknowledgementsLink
        self.apiEnvironment = apiEnvironment
        self.toggleLogs = toggleLogs
    }
}
