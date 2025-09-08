import Photos

public protocol PhotoPermissionHandling {
    @MainActor
    func requestPhotoLibraryAddOnlyPermissions() async -> Bool
}

public final class PhotoPermissionHandler: PhotoPermissionHandling {
    @MainActor
    public func requestPhotoLibraryAddOnlyPermissions() async -> Bool {
        let level = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        return level == .authorized || level == .limited
    }
}
