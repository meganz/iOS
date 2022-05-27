import Foundation

extension Helper {
    @objc static func cleanAccount() {
        let uc = AccountCleanerUseCase(credentialRepo: CredentialRepository.default,
                                   groupContainerRepo: AppGroupContainerRepository.default)
        
        uc.cleanCredentialSessions()
        uc.cleanAppGroupContainer()
    }
}
