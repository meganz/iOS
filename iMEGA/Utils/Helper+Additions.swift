import Foundation
import LogRepo
import MEGADomain
import MEGASDKRepo

extension Helper {
    @objc static func cleanAccount() {
        let uc = AccountCleanerUseCase(credentialRepo: CredentialRepository.newRepo,
                                       groupContainerRepo: AppGroupContainerRepository.newRepo)
        
        uc.cleanCredentialSessions()
        uc.cleanAppGroupContainer()
    }
    
    @objc static func markAppAsLaunched() {
        AppFirstLaunchUseCase(preferenceUserCase: PreferenceUseCase.group).markAppAsLaunched()
    }
    
    @objc static func removeLogsDirectory() {
        Logger.shared().removeLogsDirectory()
    }
}
