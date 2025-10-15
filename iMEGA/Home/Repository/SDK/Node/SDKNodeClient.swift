import Foundation
import MEGAAppSDKRepo
import MEGADomain

struct SDKNodeClient: Sendable {

    var findNode: @Sendable (
        _ nodeHandle: HandleEntity
    ) -> NodeEntity?

    var loadThumbnail: @Sendable (
        _ nodeHandle: HandleEntity,
        _ destinationPath: URL,
        _ completion: @Sendable @escaping (Bool) -> Void
    ) -> Void

    var findOwnerNode: @Sendable (
        _ nodeHandle: HandleEntity
    ) -> MEGANode?

    var findChatFolderNode: @Sendable (
        _ completion: @Sendable @escaping (NodeEntity?) -> Void
    ) -> Void
}

extension SDKNodeClient {

    static var live: Self {
        let sdk  = MEGASdk.shared

        let megaSDKOperationQueue = OperationQueue()
        megaSDKOperationQueue.name = "MEGASDKOperationQueue"
        megaSDKOperationQueue.qualityOfService = .userInteractive

        return Self.init(findNode: { nodeHandle in
            return sdk.node(forHandle: nodeHandle)?.toNodeEntity()
        },

        loadThumbnail: { (nodeHandle, destinationPathURL, completion) in
            guard let node = sdk.node(forHandle: nodeHandle), node.hasThumbnail() else {
                completion(false)
                return
            }
            let destinationPath = destinationPathURL.path
            megaSDKOperationQueue.addOperation {
                let delegate = RequestDelegate { result in
                    switch result {
                    case .success:
                        asyncOnGlobal { completion(true) }
                    case .failure:
                        asyncOnGlobal { completion(false) }
                    }
                }
                sdk.getThumbnailNode(node, destinationFilePath: destinationPath, delegate: delegate)
            }
        },

        findOwnerNode: { nodeHandle -> MEGANode? in
            guard let parentHandle = sdk.node(forHandle: nodeHandle)?.parentHandle else {
                return nil
            }
            return sdk.node(forHandle: parentHandle)
        },

        findChatFolderNode: { completion in
            megaSDKOperationQueue.addOperation {
                let delegate = RequestDelegate { result in
                    switch result {
                    case let .success(request):
                        let chatFilesFolderNode = sdk.node(forHandle: request.nodeHandle)
                        completion(chatFilesFolderNode?.toNodeEntity())
                    case .failure:
                        completion(nil)
                    }
                }
                sdk.getMyChatFilesFolder(with: delegate)
            }
        })
    }
}
