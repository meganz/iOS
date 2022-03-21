import Foundation

protocol ReinstallationUseCaseProcotol {
    func isAppReinstalled() -> Bool
    func clearSessions()
    func markAppAsFirstRun()
}

struct ReinstallationUseCase<T: PreferenceUseCaseProtocol, U: CredentialRepositoryProtocol>: ReinstallationUseCaseProcotol {
    @PreferenceWrapper(key: .firstRun, defaultValue: "", useCase: PreferenceUseCase.group)
    private var firstRun: String
    
    private let credentialRepo:U
    
    init(preferenceUserCase: T,
         credentialRepo: U) {
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
