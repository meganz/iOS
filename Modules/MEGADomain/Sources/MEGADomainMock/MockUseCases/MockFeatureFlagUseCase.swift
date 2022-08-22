import MEGADomain
import Foundation

public final class MockFeatureFlagUseCase: FeatureFlagUseCaseProtocol {
    public var savedFeatureList: [FeatureFlagEntity]

    public init(savedFeatureFlags: [FeatureFlagEntity] = []) {
        savedFeatureList = savedFeatureFlags
    }

    public func savedFeatureFlags() -> [FeatureFlagEntity] {
        savedFeatureList
    }
    
    public func isFeatureFlagEnabled(for key: FeatureFlagName) -> Bool {
        guard let featureFlag = savedFeatureList.first(where: { $0.name == key }) else { return false }
        return featureFlag.isEnabled
    }

    public func configFeatureFlag(key: FeatureFlagName, isEnabled: Bool) {
        let newFeatureFlag = FeatureFlagEntity(name: key, isEnabled: isEnabled)
        
        if let featureFlag = savedFeatureList.first(where: { $0.name == key }) {
            savedFeatureList.remove(object: featureFlag)
        }
        savedFeatureList.append(newFeatureFlag)
    }

    public func removeFeatureFlag(key: FeatureFlagName) {
        guard let featureFlag = savedFeatureList.first(where: { $0.name == key }) else { return }
        savedFeatureList.remove(object: featureFlag)
    }
}
