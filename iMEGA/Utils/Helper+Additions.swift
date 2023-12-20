import Foundation
import LogRepo
import MEGADomain
import MEGASDKRepo

extension Helper {
    /// Temporary method to cache value of the AB test, we need this immediately after app is launched
    /// and every time user navigates anywhere in the folder tree
    /// Caching this in the UserDefault until we can access those flags without sprinkling async await everywhere
    static let CloudDriveABTestCacheKey = "ab_test_new_cloud_drive"
    
    static func cloudDriveABTestCacheKey() -> String {
        "ab_test_new_cloud_drive"
    }
    @objc static func cleanAccount() {
        let uc = AccountCleanerUseCase(credentialRepo: CredentialRepository.newRepo,
                                       groupContainerRepo: AppGroupContainerRepository.newRepo)
        
        uc.cleanCredentialSessions()
        uc.cleanAppGroupContainer()
        UserDefaults.standard.setValue(nil, forKey: cloudDriveABTestCacheKey())
    }
    
    @objc static func markAppAsLaunched() {
        AppFirstLaunchUseCase(preferenceUserCase: PreferenceUseCase.group).markAppAsLaunched()
    }
    
    @objc static func removeLogsDirectory() {
        Logger.shared().removeLogsDirectory()
    }
}
