@testable import MEGA

struct MockAlbumRemoteFeatureFlagProvider: AlbumRemoteFeatureFlagProviderProtocol {
    private let isEnabled: Bool
    
    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }
    
    func isPerformanceImprovementsEnabled() async -> Bool {
        isEnabled
    }
}
