public protocol FeatureFlagUseCaseProtocol: Sendable {
    func savedFeatureFlags() -> [FeatureFlagEntity]
    func isFeatureFlagEnabled(for key: FeatureFlagName) -> Bool
    func configFeatureFlag(key: FeatureFlagName, isEnabled: Bool)
    func removeFeatureFlag(key: FeatureFlagName)
}

public struct FeatureFlagUseCase<T: FeatureFlagRepositoryProtocol>: FeatureFlagUseCaseProtocol {
    private let repo: T
    
    public init(repository: T) {
        repo = repository
    }

    public func savedFeatureFlags() -> [FeatureFlagEntity] {
        repo.savedFeatureFlags()
    }
    
    public func isFeatureFlagEnabled(for key: FeatureFlagName) -> Bool {
        repo.isFeatureFlagEnabled(for: key)
    }

    public func configFeatureFlag(key: FeatureFlagName, isEnabled: Bool) {
        repo.configFeatureFlag(for: key, isEnabled: isEnabled)
    }
    
    public func removeFeatureFlag(key: FeatureFlagName) {
        repo.removeFeatureFlag(for: key)
    }
}
