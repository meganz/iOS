struct AppMetaDataFactory {
    let bundle: Bundle
    
    private enum Constants {
        static let sdkGitCommitHashKey = "SDK_GIT_COMMIT_HASH"
    }
    
    func make() -> AppMetaData {
        let appName = (bundle.infoDictionary?["CFBundleName"] as? String) ?? ""
        let currentAppVersion = (bundle.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
        let currentSDKVersion = (bundle.infoDictionary?[Constants.sdkGitCommitHashKey] as? String) ?? ""
        let appMetaData = AppMetaData(appName: appName, currentAppVersion: currentAppVersion, currentSDKVersion: currentSDKVersion)
        return appMetaData
    }
}
