import MEGADomain
import MEGAPresentation
import MEGASDKRepo

protocol AlbumRemoteFeatureFlagProviderProtocol: Sendable {
    func isPerformanceImprovementsEnabled() -> Bool
}

struct AlbumRemoteFeatureFlagProvider: AlbumRemoteFeatureFlagProviderProtocol {
    func isPerformanceImprovementsEnabled() -> Bool {
        true
    }
}
