import MEGADomain
import MEGAInfrastructure
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

    public func get(for key: String) async throws -> Int {
        get(rawValue: key)
    }

    public func get(for key: String) -> Int {
        get(rawValue: key)
    }

    private func get(rawValue: String) -> Int {
        if let flag = RemoteFeatureFlag(rawValue: rawValue) {
            $receivedFlags.mutate { $0.append(flag) }
        }

        return valueToReturn
    }
}
