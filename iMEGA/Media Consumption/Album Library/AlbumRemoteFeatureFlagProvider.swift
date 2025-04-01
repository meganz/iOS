import MEGAAppPresentation
import MEGADomain
import MEGASDKRepo

protocol AlbumRemoteFeatureFlagProviderProtocol: Sendable {
    func isPerformanceImprovementsEnabled() -> Bool
}

struct AlbumRemoteFeatureFlagProvider: AlbumRemoteFeatureFlagProviderProtocol {
    func isPerformanceImprovementsEnabled() -> Bool {
        true
    }
}
