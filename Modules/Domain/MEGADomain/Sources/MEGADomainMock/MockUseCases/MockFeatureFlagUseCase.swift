import Foundation
import MEGADomain
import MEGASwift

public final class MockFeatureFlagUseCase: FeatureFlagUseCaseProtocol, @unchecked Sendable {
    @Atomic public var savedFeatureList: [FeatureFlagEntity] = []

    public init(savedFeatureFlags: [FeatureFlagEntity] = []) {
        $savedFeatureList.mutate { $0 = savedFeatureFlags }
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
        
        removeFeatureFlag(key: key)
        $savedFeatureList.mutate { $0.append(newFeatureFlag) }
    }

    public func removeFeatureFlag(key: FeatureFlagName) {
        guard let featureFlag = savedFeatureList.first(where: { $0.name == key }) else { return }
        $savedFeatureList.mutate { $0.remove(object: featureFlag) }
    }
}
