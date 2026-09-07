import MEGAAppPresentation
import MEGAInfrastructure
import MEGAPreference

extension DIContainer {
    private static var appDomainUseCase: some AppDomainUseCaseProtocol {
        AppDomainUseCase(
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            preferenceUseCase: PreferenceUseCase(repository: PreferenceRepository.newRepo)
        )
    }

    static var domainName: String {
        appDomainUseCase.domainName
    }
}
