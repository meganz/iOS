import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

protocol AlbumRemoteFeatureFlagProviderProtocol: Sendable {
    func isPerformanceImprovementsEnabled() -> Bool
}

struct AlbumRemoteFeatureFlagProvider: AlbumRemoteFeatureFlagProviderProtocol {
    func isPerformanceImprovementsEnabled() -> Bool {
        true
    }
}
