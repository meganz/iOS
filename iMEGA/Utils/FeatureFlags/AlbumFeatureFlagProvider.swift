import Foundation

struct AlbumFeatureFlagProvider: FeatureFlagProviderProtocol {
    func isFeatureFlagEnabled(for key: FeatureFlagKey) -> Bool {
        key == .createAlbum || key == .albumContextMenu
    }
}
