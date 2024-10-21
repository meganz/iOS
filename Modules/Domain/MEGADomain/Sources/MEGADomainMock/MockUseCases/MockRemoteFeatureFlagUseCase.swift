import MEGADomain
import MEGASwift

public final class MockRemoteFeatureFlagUseCase: RemoteFeatureFlagUseCaseProtocol, @unchecked Sendable {
    private let list: [RemoteFeatureFlag: Bool]
    
    @Atomic public var flagsPassedIn: [RemoteFeatureFlag] = []
    
    public init(list: [RemoteFeatureFlag: Bool] = [:]) {
        self.list = list
    }
    
    public func isFeatureFlagEnabled(for flag: RemoteFeatureFlag) -> Bool {
        $flagsPassedIn.mutate { $0.append(flag) }
        return list[flag] ?? false
    }
}
