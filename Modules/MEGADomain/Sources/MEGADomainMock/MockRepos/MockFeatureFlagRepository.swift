import MEGADomain
import Foundation

public final class MockFeatureFlagRepository: FeatureFlagRepositoryProtocol {
    public static var newRepo: MockFeatureFlagRepository {
        MockFeatureFlagRepository()
    }

    private var featureList: [FeatureFlagEntity]
    private var isFeatureFlagEnabled: Bool
    
    public init(featureList: [FeatureFlagEntity] = [], isFeatureFlagEnabled: Bool = false) {
        self.featureList = featureList
        self.isFeatureFlagEnabled = isFeatureFlagEnabled
    }
    
    public func savedFeatureFlags() -> [FeatureFlagEntity] {
        featureList
    }
    
    public func isFeatureFlagEnabled(for key: FeatureFlagName) -> Bool {
        isFeatureFlagEnabled
    }
    
    public func configFeatureFlag(for key: FeatureFlagName, isEnabled: Bool) {}
    
    public func removeFeatureFlag(for key: FeatureFlagName) {}
}
