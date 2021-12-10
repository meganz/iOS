import Foundation

final class CameraUploadNodeAccess: NodeAccess {
    @objc static let shared = CameraUploadNodeAccess(configuration:
                                                        NodeAccessConfiguration(autoCreate: { CameraUploadManager.isCameraUploadEnabled },
                                                                                updateInMemoryNotificationName: .MEGACameraUploadTargetFolderUpdatedInMemory,
                                                                                updateInRemoteNotificationName: .MEGACameraUploadTargetFolderChangedInRemote,
                                                                                loadNodeRequest: MEGASdkManager.sharedMEGASdk().getCameraUploadsFolder,
                                                                                setNodeRequest: MEGASdkManager.sharedMEGASdk().setCameraUploadsFolderWithHandle,
                                                                                nodeName: Strings.Localizable.cameraUploadsLabel,
                                                                                createNodeRequest: MEGASdkManager.sharedMEGASdk().createFolder))
}
