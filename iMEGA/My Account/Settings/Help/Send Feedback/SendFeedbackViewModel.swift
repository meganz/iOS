import MEGADomain
import MEGAData
import MEGASwift

final class SendFeedbackViewModel: NSObject {
    private let accountUseCase: AccountUseCaseProtocol
    private let bundle: Bundle
    private let device: UIDevice
    private let locale: NSLocale
    private let timeZone: TimeZone
    private var accountDetails: AccountDetailsEntity?
    private var userEmail: String?
    
    init(accountUseCase: AccountUseCaseProtocol,
         bundle: Bundle = .main,
         device: UIDevice = .current,
         locale: NSLocale = NSLocale.current as NSLocale,
         timeZone: TimeZone = NSTimeZone.local) {
        self.accountUseCase = accountUseCase
        self.bundle = bundle
        self.device = device
        self.locale = locale
        self.timeZone = timeZone
    }
    
    //MARK: - Public
    func getFeedback() async -> FeedbackEntity {
        await setupAccountDetails()
        userEmail = await accountUseCase.currentUser()?.email
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYMMdd_hhmmss"
        let logsFileName = "\(dateFormatter.string(from: Date()))_iOS_\(userEmail ?? "").zip"
        
        return FeedbackEntity(toEmail: "iosfeedback@mega.nz",
                              subject: "Feedback \(appVersion ?? "")",
                              messageBody: feedbackMessageBody(),
                              logsFileName: logsFileName)
    }

    //MARK: - Private
    private var appVersion: String? {
        bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
    }
    
    private func setupAccountDetails() async {
        do {
            accountDetails = try await accountUseCase.accountDetails()
        } catch {
            MEGALogError("[Send Feedback] Error loading account details. Error: \(error)")
        }
    }
    
    private func feedbackMessageBody() -> String {
        let infoDictionary = bundle.infoDictionary
        let appName = infoDictionary?["CFBundleName"] as? String
        let shortAppVersion = infoDictionary?["CFBundleShortVersionString"] as? String
        let systemVersion = device.systemVersion
        let languageArray = bundle.preferredLocalizations
        let language = locale.displayName(forKey: .identifier, value: languageArray.first ?? "")
        let proLevel = accountDetails?.proLevel.toAccountTypeDisplayName()
        let connectionStatusMessage = MEGAReachabilityManager.statusConnectionMessage()
        let deviceName = device.deviceName()
        
        var body = Strings.Localizable.pleaseWriteYourFeedback
        
        if let appName {
            body += "\n\n\nApp Information:\nApp Name: \(appName)\n"
        }
        
        if let shortAppVersion, let appVersion {
            body += "App Version: \(shortAppVersion) (\(appVersion))\n\n"
        }
        
        if let deviceName, let userEmail, let language, let proLevel {
            body += "Device information:\nDevice: \(deviceName)\niOS Version: \(systemVersion)\nLanguage: \(language)\nTimezone: \(timeZone.identifier)\nConnection Status: \(connectionStatusMessage)\nMEGA account: \(userEmail) (\(proLevel))"
        }
        
        return body
    }
}
