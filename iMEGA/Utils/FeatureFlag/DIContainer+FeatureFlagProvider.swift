import MEGAAppPresentation
import MEGADomain
import MEGARepo

extension DIContainer {
    static var featureFlagProvider: some FeatureFlagProviderProtocol {
        FeatureFlagProvider(
            useCase: FeatureFlagUseCase(
                repository: FeatureFlagRepository.newRepo
            )
        )
    }
}

struct FeatureFlagProvider: FeatureFlagProviderProtocol {
#if DEBUG || QA_CONFIG
    private static let disableFeatureFlags: Bool = false
#else
    private static let disableFeatureFlags: Bool = true
#endif
    
    private let useCase: any FeatureFlagUseCaseProtocol

    init(
        useCase: some FeatureFlagUseCaseProtocol = FeatureFlagUseCase(repository: FeatureFlagRepository.newRepo)
    ) {
        self.useCase = useCase
    }
    
    public func isFeatureFlagEnabled(for key: FeatureFlagKey) -> Bool {
        if FeatureFlagKey.rolledOutKeys.contains(key) { return true }
        guard !Self.disableFeatureFlags else { return false }

        return useCase.isFeatureFlagEnabled(for: key.rawValue)
    }
}
