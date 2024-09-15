import MEGADomain
import MEGARepo

public protocol FeatureFlagProviderProtocol: Sendable {
    func isFeatureFlagEnabled(for: FeatureFlagKey) -> Bool
}

public struct FeatureFlagProvider: FeatureFlagProviderProtocol {
    public static var disableFeatureFlags: Bool = true
    private let useCase: any FeatureFlagUseCaseProtocol

    init(useCase: any FeatureFlagUseCaseProtocol = FeatureFlagUseCase(repository: FeatureFlagRepository.newRepo)) {
        self.useCase = useCase
    }
    
    public func isFeatureFlagEnabled(for key: FeatureFlagKey) -> Bool {
        guard !Self.disableFeatureFlags else { return false }

        return useCase.isFeatureFlagEnabled(for: key.rawValue)
    }
}
