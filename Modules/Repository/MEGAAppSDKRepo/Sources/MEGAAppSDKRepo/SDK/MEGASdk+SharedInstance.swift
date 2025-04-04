import MEGADomain
import MEGASdk

public extension MEGASdk {

    private enum Constants {
        static let appKey = "EVtjzb7R"
        static let MaximumNOFILE = 20000
        static let MEGAGroupIdentifier = "group.mega.ios"
        static let MEGANotificationServiceExtensionCacheFolder =  "Library/Caches/NSE"
        static var userAgent: String {
            var agent = "MEGAiOS/\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "1")"
            switch AppEnvironmentUseCase.shared.configuration {
            case .debug:
                agent.append(" MEGAEnv/Dev")
            case .qa:
                agent.append(" MEGAEnv/QA")
            default:
                break
            }
            
            return agent
        }
    }
    
    /// MEGASdk instance used for the user logged account
    static let sharedSdk: MEGASdk = {
        let baseURL: URL? = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let sdk = MEGASdk(appKey: Constants.appKey, userAgent: Constants.userAgent, basePath: baseURL?.path)
        sdk?.setRLimitFileCount(Constants.MaximumNOFILE)
        sdk?.retrySSLErrors(true)
        guard let sdk else {
            fatalError("Can't create shared sdk")
        }
        return sdk
    }()
    
    /// MEGASdk instance used for the Notification Service Extension
    static let sharedNSESdk: MEGASdk = {
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.MEGAGroupIdentifier)
        let baseURL: URL? = containerURL?.appendingPathComponent(Constants.MEGANotificationServiceExtensionCacheFolder, isDirectory: true)
        if let baseURL {
            try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
        
        let sdk = MEGASdk(appKey: Constants.appKey, userAgent: Constants.userAgent, basePath: baseURL?.path)
        sdk?.setRLimitFileCount(Constants.MaximumNOFILE)
        sdk?.retrySSLErrors(true)
        guard let sdk else {
            fatalError("Can't create shared NSE sdk")
        }
        return sdk
    }()
    
    /// MEGASdk instance used when user opens a folder link.
    ///
    /// When user opens a folder link, we use this instance to loggin in the folder link and fetch the node tree of the folder link.
    ///
    /// - important: **Do not** use this instance of MEGASdk to download folder links (or files inside folder links) or for streaming files,
    /// otherwise free quota per IP is consumed instead own user's transfer quota
    static let sharedFolderLinkSdk: MEGASdk = {
        let baseURL = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let sdk = MEGASdk(appKey: Constants.appKey, userAgent: Constants.userAgent, basePath: baseURL?.path)
        sdk?.setRLimitFileCount(Constants.MaximumNOFILE)
        sdk?.retrySSLErrors(true)
        guard let sdk else {
            fatalError("Can't create shared folder link sdk")
        }
        return sdk
    }()
}
