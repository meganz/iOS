import MEGAAppPresentation
import MEGADomain
import MEGAInfrastructure
import MEGAPreference
import MEGASDKRepo

extension DIContainer {
    private static var appDomainUseCase: some AppDomainUseCaseProtocol {
        AppDomainUseCase(
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            preferenceUseCase: PreferenceUseCase(repository: PreferenceRepository.newRepo)
        )
    }

    static var domainName: String {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .dotAppDomain) else { return "mega.nz" }
        return appDomainUseCase.domainName
    }
}
