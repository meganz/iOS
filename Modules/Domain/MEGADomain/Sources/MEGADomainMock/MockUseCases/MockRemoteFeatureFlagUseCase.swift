import MEGADomain
import MEGAInfrastructure
import MEGASwift

public final class MockRemoteFeatureFlagUseCase: RemoteFeatureFlagUseCaseProtocol, @unchecked Sendable {
    private let list: [RemoteFeatureFlag: Bool]
    
    @Atomic public var flagsPassedIn: [RemoteFeatureFlag] = []
    
    public init(list: [RemoteFeatureFlag: Bool] = [:]) {
        self.list = list
    }

    public func get(for key: String) async -> RemoteFeatureFlagState {
        get(rawValue: key)
    }

    public func get(for key: String) -> RemoteFeatureFlagState {
        get(rawValue: key)
    }

    private func get(rawValue: String) -> RemoteFeatureFlagState {
        guard let flag = RemoteFeatureFlag(rawValue: rawValue) else { return .disabled }

        $flagsPassedIn.mutate { $0.append(flag) }
        let isEnabled: Bool = list[flag] ?? false
        return isEnabled ? .enabled(value: 1) : .disabled
    }
}
