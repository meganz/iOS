import Foundation
import MEGAL10n

final class CameraUploadNodeAccess: NodeAccess {
    @objc static let shared = CameraUploadNodeAccess(
        configuration: NodeAccessConfiguration(
            autoCreate: { CameraUploadManager.isCameraUploadEnabled },
            updateInMemoryNotificationName: .MEGACameraUploadTargetFolderUpdatedInMemory,
            updateInRemoteNotificationName: .MEGACameraUploadTargetFolderChangedInRemote,
            loadNodeRequest: MEGASdk.shared.getCameraUploadsFolder,
            setNodeRequest: MEGASdk.shared.setCameraUploadsFolderWithHandle,
            nodeName: Strings.Localizable.cameraUploadsLabel,
            createNodeRequest: MEGASdk.shared.createFolder
        )
    )
}
