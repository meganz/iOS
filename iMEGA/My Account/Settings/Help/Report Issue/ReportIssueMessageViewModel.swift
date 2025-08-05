import MEGADomain

struct ReportIssueMessageViewModel {
    let accountUseCase: any AccountUseCaseProtocol
    let appMetaData: AppMetaData
    let deviceMetaData: DeviceMetaData
    
    func generateReportIssueMessage(message details: String, filename: String?) async -> String {
        
        let email = accountUseCase.myEmail ?? ""
        let accountDetails = accountUseCase.currentAccountDetails
        let accountType = accountDetails?.proLevel.toString() ?? ""
        
        let ticketMessage = """
        \(details)
                               
        Report filename: \(filename ?? "No log file")
        
        Account Information:
        Email: \(email)
        Type: \(accountType)
        
        App Information:
        App name: \(appMetaData.appName)
        App version: \(appMetaData.currentAppVersion)
        Sdk version: \(appMetaData.currentSDKVersion)
        
        Device Information:
        Device: \(deviceMetaData.deviceName)
        iOS Version: \(deviceMetaData.osVersion)
        Language: \(deviceMetaData.language)
        """.trimmingCharacters(in: .newlines)
        
        return ticketMessage
    }
}

private extension AccountTypeEntity {
    
    func toString() -> String {
        switch self {
        case .free:
            return "Free"
        case .proI:
            return "Pro I"
        case .proII:
            return "Pro II"
        case .proIII:
            return "Pro III"
        case .lite:
            return "Pro Lite"
        case .business:
            return "Business"
        case .proFlexi:
            return "Pro Flexi"
        case .starter:
            return "Starter"
        case .basic:
            return "Basic"
        case .essential:
            return "Essential"
        case .feature:
            return "Feature"
        }
    }
}
