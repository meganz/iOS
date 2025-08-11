import MEGAAppPresentation
import MEGADomain
import MEGAPreference

extension DIContainer {
    static let appDomainUseCase = AppDomainUseCase(
        preferenceUseCase: PreferenceUseCase(repository: PreferenceRepository.newRepo),
        remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
        isLocalFeatureFlagEnabled: featureFlagProvider.isFeatureFlagEnabled(for: .dotAppDomain)
    )
}
