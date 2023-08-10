@testable import MEGA
@testable import MEGADomain
import MEGAPresentation

final class MockABTestProvider: ABTestProviderProtocol {
    private var list = [ABTestFlagKey: ABTestVariant]()

    init(list: [ABTestFlagKey: ABTestVariant]) {
        self.list = list
    }
    
    func abTestVariant(for key: ABTestFlagKey) async -> ABTestVariant {
        list[key] ?? .baseline
    }
}
