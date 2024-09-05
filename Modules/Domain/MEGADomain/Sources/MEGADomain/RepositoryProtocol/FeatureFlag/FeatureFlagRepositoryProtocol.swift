public protocol FeatureFlagRepositoryProtocol: RepositoryProtocol, Sendable {
    func savedFeatureFlags() -> [FeatureFlagEntity]
    func isFeatureFlagEnabled(for key: FeatureFlagName) -> Bool
    func configFeatureFlag(for key: FeatureFlagName, isEnabled: Bool)
    func removeFeatureFlag(for key: FeatureFlagName)
}
