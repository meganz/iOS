
extension MEGASdk {
    
    private enum Constants {
        static let appKey = "EVtjzb7R"
        static let MaximumNOFILE = 20000
        static let userAgent = "MEGAiOS/\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "1")"
    }
    
    @objc static let shared: MEGASdk = {
        var baseURL: URL?
#if MNZ_NOTIFICATION_EXTENSION
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MEGAGroupIdentifier)
        baseURL = containerURL?.appendingPathComponent(MEGANotificationServiceExtensionCacheFolder, isDirectory: true)
        if let baseURL {
            try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
#else
        baseURL = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
#endif
        let sdk = MEGASdk(appKey: Constants.appKey, userAgent: Constants.userAgent, basePath: baseURL?.path)
        sdk?.setRLimitFileCount(Constants.MaximumNOFILE)
        sdk?.retrySSLErrors(true)
        return sdk!
    }()
    
    @objc static let sharedFolderLink: MEGASdk = {
        let baseURL = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let sdk = MEGASdk(appKey: Constants.appKey, userAgent: Constants.userAgent, basePath: baseURL?.path)
        sdk?.setRLimitFileCount(Constants.MaximumNOFILE)
        sdk?.retrySSLErrors(true)
        return sdk!
    }()
}
