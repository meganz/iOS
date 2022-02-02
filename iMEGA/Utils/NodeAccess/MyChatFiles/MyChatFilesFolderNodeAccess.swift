import Foundation

final class MyChatFilesFolderNodeAccess: NodeAccess {
    @objc static let shared = MyChatFilesFolderNodeAccess(
        configuration: NodeAccessConfiguration(
            autoCreate: { false },
            updateInMemoryNotificationName: .MEGAMyChatFilesFolderUpdatedInMemory,
            updateInRemoteNotificationName: .MEGAMyChatFilesFolderUpdatedInRemote,
            loadNodeRequest: MEGASdkManager.sharedMEGASdk().getMyChatFilesFolder,
            setNodeRequest: MEGASdkManager.sharedMEGASdk().setMyChatFilesFolderWithHandle,
            nodeName: Strings.Localizable.myChatFiles,
            createNodeRequest: MEGASdkManager.sharedMEGASdk().createFolder))
    
    @objc func updateAutoCreate(status: @escaping @autoclosure () -> Bool) {
        MyChatFilesFolderNodeAccess.shared.nodeAccessConfiguration.autoCreate = status
    }
}
