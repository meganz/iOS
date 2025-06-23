import MEGASdk

public extension MEGASdk {
    /// MEGASdk instance used for the user logged account
    static let sharedSdk: MEGASdk = {
        let baseURL: URL? = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        guard let sdk = MEGASdk(
            appKey: "", // App key does not need to be set for this demo project
            userAgent: userAgent,
            basePath: baseURL?.path
        ) else { fatalError("Can't create shared sdk") }

        sdk.setRLimitFileCount(20_000)
        sdk.retrySSLErrors(true)
        if let preferredLanguage = Bundle.main.preferredLocalizations.first {
            sdk.setLanguageCode(preferredLanguage)
        }
        return sdk
    }()

    private static var userAgent: String {
        var agent = "MEGAiOS"
        agent.append("/\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "1")")
        agent.append(" (iOS \(osVersion))")
        return agent
    }

    private static var osVersion: String {
        "\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)"
        + ".\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion)"
        + ".\(ProcessInfo.processInfo.operatingSystemVersion.patchVersion)"
    }
}
