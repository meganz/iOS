import Foundation

struct SDKNodeClient {

    var findNode: (
        _ nodeHandle: MEGAHandle
    ) -> NodeEntity?

    var loadThumbnail: (
        _ nodeHandle: MEGAHandle,
        _ destinationPath: URL,
        _ completion: @escaping (Bool) -> Void
    ) -> Void

    var findOwnerNode: (
        _ nodeHandle: MEGAHandle
    ) -> MEGANode?

    var findChatFolderNode: (
        _ completion: @escaping (NodeEntity?) -> Void
    ) -> Void
}

extension SDKNodeClient {

    static var live: Self {
        let sdk  = MEGASdkManager.sharedMEGASdk()

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
                let delegate = MEGAGenericRequestDelegate { (request, error) in
                    guard error.type == .apiOk else {
                        asyncOnGlobal { completion(false) }
                        return
                    }
                    asyncOnGlobal { completion(true) }
                }
                sdk.getThumbnailNode(node, destinationFilePath: destinationPath, delegate: delegate)
            }
        },

        findOwnerNode: { nodeHandle -> MEGANode? in
            guard let parentHandle = sdk.node(forHandle: nodeHandle)?.parentHandle else {
                return nil
            }
            return sdk.node(forHandle:parentHandle)
        },

        findChatFolderNode: { completion in
            megaSDKOperationQueue.addOperation {
                let delegate = MEGAGenericRequestDelegate { (request, error) in
                    guard error.type == .apiOk else {
                        completion(nil)
                        return
                    }
                    let chatFilesFolderNode = sdk.node(forHandle: request.nodeHandle)
                    completion(chatFilesFolderNode?.toNodeEntity())
                }
                sdk.getMyChatFilesFolder(with: delegate)
            }
        })
    }
}
