import Foundation
import MEGAVideoPlayer

@MainActor
public final class MockPhotoPermissionHandler: PhotoPermissionHandling {
    public var requestPhotoLibraryAddOnlyPermissionsCallCount: Int = 0
    public var permissionResult: Bool = true
    
    public init() {}
    
    @MainActor
    public func requestPhotoLibraryAddOnlyPermissions() async -> Bool {
        requestPhotoLibraryAddOnlyPermissionsCallCount += 1
        return permissionResult
    }
}
