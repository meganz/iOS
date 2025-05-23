import MEGAInfrastructure

public typealias RemoteFeatureFlagUseCaseProtocol = MEGAInfrastructure.RemoteFeatureFlagUseCaseProtocol
public typealias RemoteFeatureFlagUseCase = MEGAInfrastructure.RemoteFeatureFlagUseCase

public extension RemoteFeatureFlagUseCaseProtocol {
    func isFeatureFlagEnabled(for flag: RemoteFeatureFlag) -> Bool {
        switch get(for: flag.rawValue) {
        case .enabled: return true
        default: return false
        }
    }
}

public extension RemoteFeatureFlagUseCase {
    init(repository: some RemoteFeatureFlagRepositoryProtocol) {
        self.init(repo: repository)
    }
}
