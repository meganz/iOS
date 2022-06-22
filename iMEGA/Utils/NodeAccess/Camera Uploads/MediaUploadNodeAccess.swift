import Foundation

final class MediaUploadNodeAccess: NodeAccess {
    @objc static let shared = CameraUploadNodeAccess(
        configuration: NodeAccessConfiguration(
            updateInMemoryNotificationName: .MEGACameraUploadTargetFolderUpdatedInMemory,
            updateInRemoteNotificationName: .MEGACameraUploadTargetFolderChangedInRemote,
            loadNodeRequest: MEGASdkManager.sharedMEGASdk().getCameraUploadsFolderSecondary
        )
    )
}
