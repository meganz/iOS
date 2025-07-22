import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference
import MEGARepo

final class AppFirstLaunchSecurityChecker: NSObject {
    private let appFirstLaunchUseCase: any AppFirstLaunchUseCaseProcotol
    private let accountCleanerUseCase: any AccountCleanerUseCaseProcotol
    
    init(appFirstLaunchUseCase: any AppFirstLaunchUseCaseProcotol,
         accountCleanerUseCase: any AccountCleanerUseCaseProcotol) {
        self.appFirstLaunchUseCase = appFirstLaunchUseCase
        self.accountCleanerUseCase = accountCleanerUseCase
        
        super.init()
    }
    
    @objc func performSecurityCheck() {
        if appFirstLaunchUseCase.isAppFirstLaunch() {
            appFirstLaunchUseCase.markAppAsLaunched()
            accountCleanerUseCase.cleanCredentialSessions()
            Helper.deletePasscode()
        }
    }
}

extension AppFirstLaunchSecurityChecker {
    @objc static var newChecker: AppFirstLaunchSecurityChecker {
        AppFirstLaunchSecurityChecker(
            appFirstLaunchUseCase: AppFirstLaunchUseCase(preferenceUserCase: PreferenceUseCase.group),
            accountCleanerUseCase: AccountCleanerUseCase(
                credentialRepo: CredentialRepository.newRepo,
                groupContainerRepo: AppGroupContainerRepository.newRepo
            )
        )
    }
}
