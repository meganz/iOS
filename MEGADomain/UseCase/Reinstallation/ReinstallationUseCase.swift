import Foundation

protocol ReinstallationUseCaseProcotol {
    func isAppReinstalled() -> Bool
    func clearSessions()
    func markAppAsFirstRun()
}

struct ReinstallationUseCase: ReinstallationUseCaseProcotol {
    @PreferenceWrapper(key: .firstRun, defaultValue: "", useCase: PreferenceUseCase.group)
    private var firstRun: String
    
    private let credentialRepo: CredentialRepositoryProtocol
    
    init(preferenceUserCase: PreferenceUseCaseProtocol,
         credentialRepo: CredentialRepositoryProtocol) {
        self.credentialRepo = credentialRepo
        $firstRun.useCase = preferenceUserCase
    }
    
    func isAppReinstalled() -> Bool {
        firstRun != MEGAFirstRunValue
    }
    
    func clearSessions() {
        credentialRepo.clearSession()
        credentialRepo.clearEphemeralSession()
    }

    func markAppAsFirstRun() {
        firstRun = MEGAFirstRunValue
    }
}
