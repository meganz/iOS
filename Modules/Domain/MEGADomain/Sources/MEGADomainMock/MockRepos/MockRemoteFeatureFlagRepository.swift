import MEGADomain
import MEGASwift

public final class MockRemoteFeatureFlagRepository: RemoteFeatureFlagRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockRemoteFeatureFlagRepository {
        MockRemoteFeatureFlagRepository()
    }
    
    private let valueToReturn: Int
    
    @Atomic public var receivedFlags: [RemoteFeatureFlag] = []
    
    public init(valueToReturn: Int = 0) {
        self.valueToReturn = valueToReturn
    }
    
    public func remoteFeatureFlagValue(for flag: RemoteFeatureFlag) -> Int {
        $receivedFlags.mutate { $0.append(flag) }
        return valueToReturn
    }
}
