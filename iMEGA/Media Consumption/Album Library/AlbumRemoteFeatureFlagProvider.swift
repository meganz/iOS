import MEGADomain
import MEGAPresentation
import MEGASDKRepo

protocol AlbumRemoteFeatureFlagProviderProtocol: Sendable {
    func isPerformanceImprovementsEnabled() -> Bool
}

struct AlbumRemoteFeatureFlagProvider: AlbumRemoteFeatureFlagProviderProtocol {
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    
    init(remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = RemoteFeatureFlagUseCase(repository: RemoteFeatureFlagRepository.newRepo)) {
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
    }
    
    func isPerformanceImprovementsEnabled() -> Bool {
        remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .albumPerformanceImprovements)
    }
}
