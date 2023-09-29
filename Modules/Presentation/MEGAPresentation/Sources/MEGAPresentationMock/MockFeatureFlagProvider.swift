import MEGAPresentation

public final class MockFeatureFlagProvider: FeatureFlagProviderProtocol {
    private var list = [FeatureFlagKey: Bool]()

    public init(list: [FeatureFlagKey: Bool]) {
        self.list = list
    }
    
    public func isFeatureFlagEnabled(for key: FeatureFlagKey) -> Bool {
        return list[key] ?? false
    }
}
