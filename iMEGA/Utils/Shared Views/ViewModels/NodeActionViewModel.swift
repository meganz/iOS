import Foundation
import MEGADomain
import MEGAPresentation

struct NodeActionViewModel {
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    init(featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider) {
        self.featureFlagProvider = featureFlagProvider
    }
    
    func isNodeHidden(_ node: NodeEntity) -> Bool? {
        guard featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) else {
            return nil
        }
        return node.isMarkedSensitive
    }
}
