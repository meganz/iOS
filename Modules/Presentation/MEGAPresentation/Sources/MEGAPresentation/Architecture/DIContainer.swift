import MEGADomain
import MEGAData

public enum DIContainer {
    public static var authUseCase: AuthUseCaseProtocol {
        AuthUseCase(
            repo: AuthRepository.newRepo,
            credentialRepo: CredentialRepository.newRepo
        )
    }
}
