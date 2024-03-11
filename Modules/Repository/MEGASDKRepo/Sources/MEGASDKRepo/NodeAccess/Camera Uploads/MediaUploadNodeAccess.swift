import Foundation
import MEGASdk

final public class MediaUploadNodeAccess: NodeAccess {
    @objc public static let shared = MediaUploadNodeAccess(
        configuration: NodeAccessConfiguration(
            updateInMemoryNotificationName: nil,
            updateInRemoteNotificationName: .MEGACameraUploadTargetFolderChangedInRemote,
            loadNodeRequest: MEGASdk.sharedSdk.getCameraUploadsFolderSecondary
        )
    )
}
