import Foundation

protocol AccountCleanerUseCaseProcotol {
    func cleanCredentialSessions()
    func cleanAppGroupContainer()
}

struct AccountCleanerUseCase<C: CredentialRepositoryProtocol, G: AppGroupContainerRepositoryProtocol>: AccountCleanerUseCaseProcotol {
    private let credentialRepo: C
    private let groupContainerRepo: G
    
    init(credentialRepo: C,
         groupContainerRepo: G) {
        self.credentialRepo = credentialRepo
        self.groupContainerRepo = groupContainerRepo
    }
    
    func cleanCredentialSessions() {
        credentialRepo.clearSession()
        credentialRepo.clearEphemeralSession()
    }
    
    func cleanAppGroupContainer() {
        groupContainerRepo.cleanContainer()
    }
}
