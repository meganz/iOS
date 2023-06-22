import Foundation
import MEGAData
import MEGADomain

struct ImportNodeRepository: ImportNodeRepositoryProtocol {
    static var newRepo: ImportNodeRepository {
        ImportNodeRepository(sdk: MEGASdkManager.sharedMEGASdk(), chatSdk: MEGASdkManager.sharedMEGAChatSdk(), myChatFilesFolder: MyChatFilesFolderNodeAccess.shared)
    }
    
    private let sdk: MEGASdk
    private let chatSdk: MEGAChatSdk
    private let myChatFilesFolder: MyChatFilesFolderNodeAccess

    init(sdk: MEGASdk, chatSdk: MEGAChatSdk, myChatFilesFolder: MyChatFilesFolderNodeAccess) {
        self.sdk = sdk
        self.chatSdk = chatSdk
        self.myChatFilesFolder = myChatFilesFolder
    }
    
    func importChatNode(_ node: NodeEntity, messageId: HandleEntity, chatId: HandleEntity, completion: @escaping (Result<NodeEntity, ExportFileErrorEntity>) -> Void) {
        if node.ownerHandle == chatSdk.myUserHandle {
            completion(.success(node))
        } else {
            if let remoteNode = sdk.node(forFingerprint: node.fingerprint ?? ""), remoteNode.owner == chatSdk.myUserHandle {
                completion(.success(remoteNode.toNodeEntity()))
            } else {
                myChatFilesFolder.loadNode { myChatFilesNode, error in
                    if let chatFilesNode = myChatFilesNode {
                        guard let megaNode = chatSdk.chatNode(handle: node.handle, messageId: messageId, chatId: chatId) else {
                            MEGALogWarning("Coud not find node for handle \(node.handle)")
                            completion(.failure(.couldNotFindNodeByHandle))
                            return
                        }
                        sdk.copy(megaNode, newParent: chatFilesNode, delegate: RequestDelegate { (result) in
                            switch result {
                            case .success(let request):
                                guard let resultNode = sdk.node(forHandle: request.nodeHandle) else {
                                    MEGALogWarning("Coud not find node for handle \(request.nodeHandle)")
                                    completion(.failure(.generic))
                                    return
                                }
                                completion(.success(resultNode.toNodeEntity()))
                            case .failure:
                                completion(.failure(.generic))
                            }
                        })
                    } else {
                        MEGALogWarning("Coud not load MyChatFiles target folder due to error \(String(describing: error))")
                        completion(.failure(.generic))
                    }
                }
            }
        }
    }
}
