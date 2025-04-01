import MEGAAppPresentation

public final class MockABTestProvider: ABTestProviderProtocol {
    private let list: [ABTestFlagKey: ABTestVariant]

    public init(list: [ABTestFlagKey: ABTestVariant]) {
        self.list = list
    }
    
    public func abTestVariant(for key: ABTestFlagKey) async -> ABTestVariant {
        list[key] ?? .baseline
    }
}
