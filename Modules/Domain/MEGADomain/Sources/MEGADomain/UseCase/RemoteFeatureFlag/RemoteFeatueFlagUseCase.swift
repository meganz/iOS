public protocol RemoteFeatureFlagUseCaseProtocol: Sendable {
    func isFeatureFlagEnabled(for flag: RemoteFeatureFlag) -> Bool
}

public struct RemoteFeatureFlagUseCase<T: RemoteFeatureFlagRepositoryProtocol>: RemoteFeatureFlagUseCaseProtocol {
    
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func isFeatureFlagEnabled(for flag: RemoteFeatureFlag) -> Bool {
        repository.remoteFeatureFlagValue(for: flag) != 0
    }
}
