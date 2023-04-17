import MEGASdk

public extension MEGASdk {

    private enum Constants {
        static let appKey = "EVtjzb7R"
        static let MaximumNOFILE = 20000
        static let userAgent = "MEGAiOS/\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "1")"
        static let MEGAGroupIdentifier = "group.mega.ios"
        static let MEGANotificationServiceExtensionCacheFolder =  "Library/Caches/NSE"
    }
    
    static let sharedSdk: MEGASdk = {
        let baseURL: URL? = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let sdk = MEGASdk(appKey: Constants.appKey, userAgent: Constants.userAgent, basePath: baseURL?.path)
        sdk?.setRLimitFileCount(Constants.MaximumNOFILE)
        sdk?.retrySSLErrors(true)
        return sdk!
    }()
    
    static let sharedNSESdk: MEGASdk = {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.MEGAGroupIdentifier)
        let baseURL: URL? = containerURL?.appendingPathComponent(Constants.MEGANotificationServiceExtensionCacheFolder, isDirectory: true)
        if let baseURL {
            try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
        
        let sdk = MEGASdk(appKey: Constants.appKey, userAgent: Constants.userAgent, basePath: baseURL?.path)
        sdk?.setRLimitFileCount(Constants.MaximumNOFILE)
        sdk?.retrySSLErrors(true)
        return sdk!
    }()
    
    static let sharedFolderLinkSdk: MEGASdk = {
        let baseURL = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let sdk = MEGASdk(appKey: Constants.appKey, userAgent: Constants.userAgent, basePath: baseURL?.path)
        sdk?.setRLimitFileCount(Constants.MaximumNOFILE)
        sdk?.retrySSLErrors(true)
        return sdk!
    }()
}
