import Foundation
import MEGADomain

final class AppEnvironmentConfigurator: NSObject {
    @objc static func configAppEnvironment() {
        let configuration: AppConfigurationEntity
#if DEBUG
        configuration = .debug
#elseif QA_CONFIG
        configuration = .qa
#else
        configuration = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? .testFlight : .production
#endif
        
        AppEnvironmentUseCase.shared.config(configuration)
    }
}
