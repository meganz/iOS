
struct FeedbackRepository: FeedbackRepositoryProtocol {
    private let sdk: MEGASdk
    private let bundle: Bundle
    private let device: UIDevice
    private let locale: NSLocale
    private let timeZone: TimeZone
    
    init(sdk: MEGASdk, bundle: Bundle, device: UIDevice, locale: NSLocale, timeZone: TimeZone) {
        self.sdk = sdk
        self.bundle = bundle
        self.device = device
        self.locale = locale
        self.timeZone = timeZone
    }
    
    func getFeedback() -> FeedbackEntity {
        let appVersion = bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYMMdd_hhmmss"
        let logsFileName = "\(dateFormatter.string(from: Date()))_iOS_\(sdk.myEmail ?? "").zip"
        
        return FeedbackEntity(toEmail: "iosfeedback@mega.nz",
                              subject: "Feedback \(appVersion ?? "")",
                              messageBody: feedbackMessageBody() ?? "",
                              logsFileName: logsFileName)
    }
    
    private func feedbackMessageBody() -> String? {
        let infoDictionary = bundle.infoDictionary
        let appName = infoDictionary?["CFBundleName"] as? String
        let appVersion = infoDictionary?[kCFBundleVersionKey as String] as? String
        let shortAppVersion = infoDictionary?["CFBundleShortVersionString"] as? String
        let systemVersion = device.systemVersion
        let languageArray = bundle.preferredLocalizations
        let language = locale.displayName(forKey: .identifier, value: languageArray.first ?? "")
        let userEmail = sdk.myEmail
        let proLevel = sdk.mnz_accountDetails.flatMap{ MEGAAccountDetails.string(for: $0.type) }
        
        var body = Strings.Localizable.pleaseWriteYourFeedback
        
        if let appName = appName {
            body += "\n\n\nApp Information:\nApp Name: \(appName)\n"
        }
        
        if let shortAppVersion = shortAppVersion, let appVersion = appVersion {
            body += "App Version: \(shortAppVersion) (\(appVersion))\n\n"
        }
        
        if let deviceName = device.deviceName(),
           let language = language,
           let userEmail = userEmail,
           let proLevel = proLevel {
            body += "Device information:\nDevice: \(deviceName)\niOS Version: \(systemVersion)\nLanguage: \(language)\nTimezone: \(timeZone.identifier)\nConnection Status: \(MEGAReachabilityManager.statusConnectionMessage())\nMEGA account: \(userEmail) (\(proLevel))"
        }
        
        return body
    }
}
