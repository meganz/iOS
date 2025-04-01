import MEGAAppPresentation

struct Preview_FeatureFlagProvider: FeatureFlagProviderProtocol {
    
    let isFeatureFlagEnabled: Bool
    
    func isFeatureFlagEnabled(for: MEGAAppPresentation.FeatureFlagKey) -> Bool {
        isFeatureFlagEnabled
    }
}
