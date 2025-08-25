import MEGAAppPresentation
import MEGADomain
import MEGAPreference

extension DIContainer {
    static var appDomainUseCase: some AppDomainUseCaseProtocol {
        AppDomainUseCase(
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            isLocalFeatureFlagEnabled: featureFlagProvider.isFeatureFlagEnabled(for: .dotAppDomain)
        )
    }
}
