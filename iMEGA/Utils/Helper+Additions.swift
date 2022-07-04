import Foundation

extension Helper {
    @objc static func cleanAccount() {
        let uc = AccountCleanerUseCase(credentialRepo: CredentialRepository.newRepo,
                                   groupContainerRepo: AppGroupContainerRepository.newRepo)
        
        uc.cleanCredentialSessions()
        uc.cleanAppGroupContainer()
    }
}
