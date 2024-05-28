public protocol RemoteFeatureFlagUseCaseProtocol: Sendable {
    func remoteFeatureFlagValue(for: RemoteFeatureFlagName) async -> Int
}

public struct RemoteFeatureFlagUseCase<T: RemoteFeatureFlagRepositoryProtocol>: RemoteFeatureFlagUseCaseProtocol {
    
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func remoteFeatureFlagValue(for flag: RemoteFeatureFlagName) async -> Int {
        await repository.remoteFeatureFlagValue(for: flag)
    }
}
