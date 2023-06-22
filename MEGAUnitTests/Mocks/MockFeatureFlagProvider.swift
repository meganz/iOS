@testable import MEGA
@testable import MEGADomain
import MEGAPresentation

final class MockFeatureFlagProvider: FeatureFlagProviderProtocol {
    private var list = [FeatureFlagKey: Bool]()

    init(list: [FeatureFlagKey: Bool]) {
        self.list = list
    }
    
    func isFeatureFlagEnabled(for key: FeatureFlagKey) -> Bool {
        return list[key] ?? false
    }
}
