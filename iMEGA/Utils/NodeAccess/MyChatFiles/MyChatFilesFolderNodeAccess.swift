import Foundation
import MEGAL10n

final class MyChatFilesFolderNodeAccess: NodeAccess {
    @objc static let shared = MyChatFilesFolderNodeAccess(
        configuration: NodeAccessConfiguration(
            autoCreate: { false },
            updateInMemoryNotificationName: .MEGAMyChatFilesFolderUpdatedInMemory,
            updateInRemoteNotificationName: .MEGAMyChatFilesFolderUpdatedInRemote,
            loadNodeRequest: MEGASdk.shared.getMyChatFilesFolder,
            setNodeRequest: MEGASdk.shared.setMyChatFilesFolderWithHandle,
            nodeName: Strings.Localizable.myChatFiles,
            createNodeRequest: MEGASdk.shared.createFolder))
    
    @objc func updateAutoCreate(status: @escaping @autoclosure () -> Bool) {
        MyChatFilesFolderNodeAccess.shared.nodeAccessConfiguration.autoCreate = status
    }
}
