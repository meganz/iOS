import Foundation

final class CameraUploadNodeAccess: NodeAccess {
    @objc static let shared = CameraUploadNodeAccess(configuration:
                                                        NodeAccessConfiguration(updateInMemoryNotificationName: .MEGACameraUploadTargetFolderUpdatedInMemory,
                                                                                updateInRemoteNotificationName: .MEGACameraUploadTargetFolderChangedInRemote,
                                                                                loadNodeRequest: MEGASdkManager.sharedMEGASdk().getCameraUploadsFolder,
                                                                                setNodeRequest: MEGASdkManager.sharedMEGASdk().setCameraUploadsFolderWithHandle,
                                                                                autoCreate: CameraUploadManager.isCameraUploadEnabled))
}
