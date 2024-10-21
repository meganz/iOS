import MEGADomain
import MEGAPresentation
import MEGASDKRepo

protocol AlbumRemoteFeatureFlagProviderProtocol: Sendable {
    func isPerformanceImprovementsEnabled() async -> Bool
}

struct AlbumRemoteFeatureFlagProvider: AlbumRemoteFeatureFlagProviderProtocol {
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    
    init(featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = RemoteFeatureFlagUseCase(repository: RemoteFeatureFlagRepository.newRepo)) {
        self.featureFlagProvider = featureFlagProvider
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
    }
    
    func isPerformanceImprovementsEnabled() async -> Bool {
        if featureFlagProvider.isFeatureFlagEnabled(for: .albumPhotoCache) {
            await isAlbumPerformanceRemoteFeatureFlagEnabled()
        } else {
            false
        }
    }
    
    private func isAlbumPerformanceRemoteFeatureFlagEnabled() async -> Bool {
        let isEnabled = remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .albumPerformanceImprovements)
        MEGALogInfo("[\(type(of: self))]: Album performance improvements enabled: \(isEnabled)")
        return isEnabled
    }
}
