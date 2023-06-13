import MEGADomain
import MEGAData

protocol FeatureFlagProviderProtocol {
    func isFeatureFlagEnabled(for: FeatureFlagKey) -> Bool
}

final class FeatureFlagProvider: FeatureFlagProviderProtocol {
    private var useCase: any FeatureFlagUseCaseProtocol

    init(useCase: any FeatureFlagUseCaseProtocol = FeatureFlagUseCase(repository: FeatureFlagRepository.newRepo)) {
        self.useCase = useCase
    }
    
    func isFeatureFlagEnabled(for key: FeatureFlagKey) -> Bool {
#if QA_CONFIG
        return useCase.isFeatureFlagEnabled(for: key.rawValue)
#else
        false
#endif
    }
}
