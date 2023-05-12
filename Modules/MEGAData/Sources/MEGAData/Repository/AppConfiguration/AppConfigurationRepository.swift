import MEGADomain
import Foundation

public struct AppConfigurationRepository: AppConfigurationRepositoryProtocol {
    public static var newRepo: AppConfigurationRepository {
        AppConfigurationRepository()
    }
    
    private let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    
    private var isDebug: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    private var isQa: Bool {
#if QA_CONFIG
        return true
#else
        return false
#endif
    }
    
    public var configuration: AppConfigurationEntity {
        if isDebug {
            return .debug
        } else if isQa {
            return .qa
        } else if isTestFlight {
            return .testFlight
        } else {
            return .production
        }
    }
}
