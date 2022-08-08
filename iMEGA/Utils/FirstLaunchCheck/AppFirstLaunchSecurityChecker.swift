import Foundation
import MEGADomain

final class AppFirstLaunchSecurityChecker: NSObject {
    private let appFirstLaunchUseCase: AppFirstLaunchUseCaseProcotol
    private let accountCleanerUseCase: AccountCleanerUseCaseProcotol
    
    init(appFirstLaunchUseCase: AppFirstLaunchUseCaseProcotol, accountCleanerUseCase: AccountCleanerUseCaseProcotol) {
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


