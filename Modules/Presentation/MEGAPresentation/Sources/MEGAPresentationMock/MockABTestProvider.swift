import MEGAPresentation

public final class MockABTestProvider: ABTestProviderProtocol {
    private var list = [ABTestFlagKey: ABTestVariant]()

    public init(list: [ABTestFlagKey: ABTestVariant]) {
        self.list = list
    }
    
    public func abTestVariant(for key: ABTestFlagKey) async -> ABTestVariant {
        list[key] ?? .baseline
    }
}
