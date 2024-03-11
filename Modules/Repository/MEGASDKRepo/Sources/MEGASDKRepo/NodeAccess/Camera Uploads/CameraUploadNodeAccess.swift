import Foundation
import MEGADomain
import MEGASdk

final public class CameraUploadNodeAccess: NodeAccess {
    @objc public init(autoCreate: @autoclosure @escaping () -> Bool, nodeName: String) {
        super.init(
            configuration: NodeAccessConfiguration(
                autoCreate: autoCreate,
                updateInMemoryNotificationName: .MEGACameraUploadTargetFolderUpdatedInMemory,
                updateInRemoteNotificationName: .MEGACameraUploadTargetFolderChangedInRemote,
                loadNodeRequest: MEGASdk.sharedSdk.getCameraUploadsFolder,
                setNodeRequest: MEGASdk.sharedSdk.setCameraUploadsFolderWithHandle,
                nodeName: nodeName,
                createNodeRequest: MEGASdk.sharedSdk.createFolder
            )
        )
    }
}
