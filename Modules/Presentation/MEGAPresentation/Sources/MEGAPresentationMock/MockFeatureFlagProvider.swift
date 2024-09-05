import MEGAPresentation
import MEGASwift

public final class MockFeatureFlagProvider: FeatureFlagProviderProtocol, @unchecked Sendable {
    @Atomic private var list = [FeatureFlagKey: Bool]()

    public init(list: [FeatureFlagKey: Bool]) {
        $list.mutate {  $0 = list }
    }
    
    public func isFeatureFlagEnabled(for key: FeatureFlagKey) -> Bool {
        return list[key] ?? false
    }
}
