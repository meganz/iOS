import Foundation

final class MyChatFilesFolderNodeAccess: NodeAccess {
    @objc static let shared = MyChatFilesFolderNodeAccess(
        configuration: NodeAccessConfiguration(
            autoCreate: { true },
            updateInMemoryNotificationName: .MEGAMyChatFilesFolderUpdatedInMemory,
            updateInRemoteNotificationName: .MEGAMyChatFilesFolderUpdatedInRemote,
            loadNodeRequest: MEGASdkManager.sharedMEGASdk().getMyChatFilesFolder,
            setNodeRequest: MEGASdkManager.sharedMEGASdk().setMyChatFilesFolderWithHandle,
            nodeName: Strings.Localizable.myChatFiles,
            createNodeRequest: MEGASdkManager.sharedMEGASdk().createFolder))
}
