import MEGADomain
import MEGARepo

public protocol FeatureFlagProviderProtocol: Sendable {
    func isFeatureFlagEnabled(for: FeatureFlagKey) -> Bool
}
