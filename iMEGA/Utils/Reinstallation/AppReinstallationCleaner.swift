
final class AppReinstallationCleaner: NSObject {
    let reinstallationUseCase = ReinstallationUseCase(preferenceUserCase: PreferenceUseCase.group,
                                                      credentialRepo: CredentialRepository())
    
    @objc func cleanCredentialsIfNeeded() -> Bool {
        if reinstallationUseCase.isAppReinstalled() {
            reinstallationUseCase.clearSessions()
            reinstallationUseCase.markAppAsFirstRun()
            Helper.deletePasscode()
            return true
        }
        return false
    }
}
