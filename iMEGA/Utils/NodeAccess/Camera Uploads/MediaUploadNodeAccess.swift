import Foundation

final class MediaUploadNodeAccess: NodeAccess {
    @objc static let shared = MediaUploadNodeAccess(
        configuration: NodeAccessConfiguration(
            updateInMemoryNotificationName: nil,
            updateInRemoteNotificationName: .MEGACameraUploadTargetFolderChangedInRemote,
            loadNodeRequest: MEGASdkManager.sharedMEGASdk().getCameraUploadsFolderSecondary
        )
    )
}
