import MEGADomain
import Foundation

public final class MockFeatureFlagUseCase: FeatureFlagUseCaseProtocol {
    public var savedFeatureList: [FeatureFlagEntity: Bool]

    public init(savedFeatureFlags: [FeatureFlagEntity: Bool] = [:]) {
        savedFeatureList = savedFeatureFlags
    }

    public func savedFeatureFlags() -> [FeatureFlagEntity] {
        Array(savedFeatureList.keys)
    }

    public func isFeatureFlagEnabled(for key: FeatureFlagName) -> Bool {
        let featureFlag = FeatureFlagEntity(name: key, isEnabled: false)
        return savedFeatureList[featureFlag] ?? false
    }

    public func configFeatureFlag(key: FeatureFlagName, isEnabled: Bool) {
        let featureFlag = FeatureFlagEntity(name: key, isEnabled: isEnabled)
        savedFeatureList[featureFlag] = isEnabled
    }

    public func removeFeatureFlag(key: FeatureFlagName) {
        let featureFlag = FeatureFlagEntity(name: key, isEnabled: false)
        savedFeatureList[featureFlag] = nil
    }
}
