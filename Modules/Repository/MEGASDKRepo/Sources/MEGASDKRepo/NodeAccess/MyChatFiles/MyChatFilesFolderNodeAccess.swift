import Foundation
import MEGASdk

final public class MyChatFilesFolderNodeAccess: NodeAccess, @unchecked Sendable {
    @objc public init(autoCreate: @autoclosure @escaping () -> Bool = false, nodeName: String) {
        super.init(
            configuration: NodeAccessConfiguration(
                autoCreate: autoCreate,
                updateInMemoryNotificationName: .MEGAMyChatFilesFolderUpdatedInMemory,
                updateInRemoteNotificationName: .MEGAMyChatFilesFolderUpdatedInRemote,
                loadNodeRequest: MEGASdk.sharedSdk.getMyChatFilesFolder,
                setNodeRequest: MEGASdk.sharedSdk.setMyChatFilesFolderWithHandle,
                nodeName: nodeName,
                createNodeRequest: MEGASdk.sharedSdk.createFolder
            )
        )
    }
    
    @objc public func updateAutoCreate(status: @escaping @autoclosure () -> Bool) {
        nodeAccessConfiguration.autoCreate = status
    }
}
