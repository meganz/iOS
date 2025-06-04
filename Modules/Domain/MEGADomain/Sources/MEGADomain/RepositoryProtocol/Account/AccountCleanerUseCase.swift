import Foundation

public protocol AccountCleanerUseCaseProcotol {
    func cleanCredentialSessions()
    func cleanAppGroupContainer() async
}

public struct AccountCleanerUseCase<C: CredentialRepositoryProtocol, G: AppGroupContainerRepositoryProtocol>: AccountCleanerUseCaseProcotol {
    private let credentialRepo: C
    private let groupContainerRepo: G
    
    public init(credentialRepo: C,
                groupContainerRepo: G) {
        self.credentialRepo = credentialRepo
        self.groupContainerRepo = groupContainerRepo
    }
    
    public func cleanCredentialSessions() {
        credentialRepo.clearSession()
        credentialRepo.clearEphemeralSession()
    }
    
    public func cleanAppGroupContainer() async {
        await groupContainerRepo.cleanContainer()
    }
}
