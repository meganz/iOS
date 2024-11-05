import Foundation
import MEGASdk

final public class MyChatFilesFolderNodeAccess: NodeAccess, @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.mega.myChatFilesFolderNodeAccess")
    
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
    
    public func loadNode() async throws -> MEGANode? {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                loadNode { node, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: node)
                    }
                }
            }
        }
    }
}
