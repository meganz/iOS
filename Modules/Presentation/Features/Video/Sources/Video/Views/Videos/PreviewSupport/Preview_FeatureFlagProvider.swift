import MEGAPresentation

struct Preview_FeatureFlagProvider: FeatureFlagProviderProtocol {
    
    let isFeatureFlagEnabled: Bool
    
    func isFeatureFlagEnabled(for: MEGAPresentation.FeatureFlagKey) -> Bool {
        isFeatureFlagEnabled
    }
}
